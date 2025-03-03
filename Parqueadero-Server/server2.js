const express = require("express");
const multer = require("multer");
const vision = require("@google-cloud/vision");
const cors = require("cors");
const fs = require("fs");
const http = require("http");
const socketIo = require("socket.io");
const admin = require("firebase-admin");
const { getAuth } = require("firebase-admin/auth");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

//  Configurar Firebase
admin.initializeApp({
    credential: admin.credential.cert(require("./firebase-service-account2.json"))
});
const db = admin.firestore();
const auth = getAuth();


//  Configurar credenciales de Google Cloud Vision
process.env.GOOGLE_APPLICATION_CREDENTIALS = "./google-cloud-key.json";
const client = new vision.ImageAnnotatorClient();

//  Configurar Express y Socket.io
const app = express();
const server = http.createServer(app);
const io = socketIo(server);

app.use(cors());
app.use(express.json());
const upload = multer({ dest: "uploads/" });

/**  REGISTRO DE USUARIOS  **/
app.post("/register", async (req, res) => {
    try {
        const { email, password, name } = req.body;
        console.log(" Registrando usuario:", email);

        // Cifrar la contraseña antes de guardarla
        const hashedPassword = await bcrypt.hash(password, 10);

        // Crear usuario en Firebase Authentication
        const userRecord = await auth.createUser({
            email,
            password,
            displayName: name
        });

        // Guardar usuario en Firestore con la contraseña cifrada
        await db.collection("users").doc(userRecord.uid).set({
            uid: userRecord.uid,
            email,
            name,
            password: hashedPassword, //  Guardamos la contraseña cifrada
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log("Usuario registrado correctamente");
        res.status(201).json({ message: "Usuario registrado exitosamente", uid: userRecord.uid });

    } catch (error) {
        console.error("Error en el registro:", error);
        res.status(400).json({ error: error.message });
    }
});


/**  INICIO DE SESIÓN  **/
app.post("/login", async (req, res) => {
    try {
        const { email, password } = req.body;
        console.log("Recibiendo login para:", email);

        // Buscar usuario en Firestore
        const snapshot = await db.collection("users").where("email", "==", email).get();

        if (snapshot.empty) {
            console.log("Usuario no encontrado");
            return res.status(401).json({ error: "Usuario no encontrado" });
        }

        const userData = snapshot.docs[0].data();
        const userId = snapshot.docs[0].id; //  Obtenemos el UID del usuario

        // Comparar contraseñas usando bcrypt
        const isValidPassword = await bcrypt.compare(password, userData.password);
        if (!isValidPassword) {
            console.log("Contraseña incorrecta");
            return res.status(401).json({ error: "Contraseña incorrecta" });
        }

        // Generar token JWT
        const token = jwt.sign(
            { uid: userId, email: userData.email },
            "supersecreto",
            { expiresIn: "2h" }
        );

        console.log("Inicio de sesión exitoso, Token generado");

        res.status(200).json({
            message: "Inicio de sesión exitoso",
            token,
            uid: userId,
            name: userData.name, 
            email: userData.email
        });

    } catch (error) {
        console.error("Error en login:", error);
        res.status(500).json({ error: error.message });
    }
});




/**  VERIFICACIÓN DE TOKEN  **/
app.post("/verify-token", async (req, res) => {
    try {
        const { token } = req.body;
        console.log("Verificando token...");

        // Decodificar el token JWT
        const decodedToken = jwt.verify(token, "supersecreto");

        console.log("Token válido para:", decodedToken.email);
        res.status(200).json({
            message: "Token válido",
            uid: decodedToken.uid,
            email: decodedToken.email
        });

    } catch (error) {
        console.error("Error verificando token:", error);
        res.status(401).json({ error: "Token inválido o expirado" });
    }
});


/**  Registro y reservación de espacios en tiempo real */
app.post("/reserve", async (req, res) => {
    try {
        const { userId, slotId } = req.body;
        const slotRef = db.collection("parkingSlots").doc(slotId);

        // Verificar disponibilidad
        const slot = await slotRef.get();
        if (!slot.exists || !slot.data().isAvailable) {
            return res.status(400).json({ error: "Espacio no disponible" });
        }

        // Registrar la reserva
        await db.collection("reservations").add({
            userId,
            slotId,
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });

        // Marcar el espacio como ocupado
        await slotRef.update({ isAvailable: false });

        io.emit("update", { message: `El espacio ${slotId} ha sido reservado` });

        res.status(201).json({ message: "Reserva exitosa", slotId });
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

/**  Obtener todas las reservas de un usuario */
app.get("/reservations/:userId", async (req, res) => {
    try {
        const { userId } = req.params;

        const snapshot = await db.collection("reservations").where("userId", "==", userId).get();

        if (snapshot.empty) {
            return res.status(404).json({ error: "No hay reservas activas para este usuario" });
        }

        const reservations = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        res.json(reservations);

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**  Cancelar una reserva */
app.delete("/cancel-reservation/:reservationId", async (req, res) => {
    try {
        const { reservationId } = req.params;

        // Buscar la reserva en Firestore
        const reservationRef = db.collection("reservations").doc(reservationId);
        const reservationDoc = await reservationRef.get();

        if (!reservationDoc.exists) {
            return res.status(404).json({ error: "Reserva no encontrada" });
        }

        const { slotId } = reservationDoc.data();

        // Eliminar la reserva de la colección
        await reservationRef.delete();

        // Marcar el espacio como disponible nuevamente
        await db.collection("parkingSlots").doc(slotId).update({ isAvailable: true });

        io.emit("update", { message: `La reserva del espacio ${slotId} ha sido cancelada` });

        res.json({ message: "Reserva cancelada exitosamente" });

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});


/** Obtener todas las placas detectadas */
app.get("/detected-plates", async (req, res) => {
    try {
        const snapshot = await db.collection("detectedPlates").orderBy("timestamp", "desc").get();

        if (snapshot.empty) {
            return res.status(404).json({ error: "No hay placas detectadas" });
        }

        const plates = snapshot.docs.map(doc => doc.data().plateNumber);
        res.json({ plates });

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});


/**  Escaneo de placas mediante OCR */
app.post("/scan-plate", upload.single("image"), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: "No se proporcionó una imagen" });
        }

        const imagePath = req.file.path;

        // Analizar la imagen con Google Cloud Vision
        const [result] = await client.textDetection(imagePath);
        const detections = result.textAnnotations;

        if (!detections.length) {
            return res.status(400).json({ error: "No se detectó texto en la imagen" });
        }

        // Extraer solo el número de la placa
        const detectedText = detections[0].description.trim();
        const plateRegex = /[A-Z]{3}-\d{3,4}/;
        const match = detectedText.match(plateRegex);
        const detectedPlate = match ? match[0] : "Placa no encontrada";

        // Guardar en Firebase Firestore si la placa es válida
        if (detectedPlate !== "Placa no encontrada") {
            await db.collection("detectedPlates").add({
                plateNumber: detectedPlate,
                timestamp: admin.firestore.FieldValue.serverTimestamp()
            });
        }

        fs.unlinkSync(imagePath); // Eliminar imagen temporal

        res.json({ plateNumber: detectedPlate, message: "Placa detectada y almacenada en Firestore" });

    } catch (error) {
        console.error(" Error en OCR:", error);
        res.status(500).json({ error: "Error en el reconocimiento de placas" });
    }
});

/**  Registro de entrada automática */
app.post("/entry", async (req, res) => {
    try {
        const { plateNumber, slotId } = req.body;

        // Registrar entrada en Firestore
        await db.collection("entries").add({
            plateNumber,
            slotId,
            entryTime: admin.firestore.FieldValue.serverTimestamp()
        });

        // Marcar el espacio como ocupado
        await db.collection("parkingSlots").doc(slotId).update({ isAvailable: false });

        io.emit("update", { message: `El espacio ${slotId} ha sido ocupado` });

        res.status(201).json({ message: "Entrada registrada", plateNumber });

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**  Registro de salida automática y cálculo de pago */
app.post("/exit", async (req, res) => {
    try {
        const { plateNumber, slotId } = req.body;

        // Buscar la última entrada de esta placa
        const entries = await db.collection("entries")
            .where("plateNumber", "==", plateNumber)
            .orderBy("entryTime", "desc")
            .limit(1)
            .get();

        if (entries.empty) {
            return res.status(404).json({ error: "No hay registro de entrada para esta placa" });
        }

        const entryDoc = entries.docs[0];
        const entryTime = entryDoc.data().entryTime.toDate();
        const exitTime = new Date();

        // Calcular la duración en minutos
        const durationMinutes = Math.ceil((exitTime - entryTime) / (1000 * 60));

        // Definir tarifa base y calcular costo según bloques de 30 minutos
        const ratePer30Minutes = 0.50; // $0.50 cada 30 minutos
        const blocksUsed = Math.ceil(durationMinutes / 30); // Redondear al siguiente bloque
        const totalAmount = blocksUsed * ratePer30Minutes;

        // Guardar en Firestore el registro de salida y pago
        await db.collection("exits").add({
            plateNumber,
            slotId,
            entryTime,
            exitTime,
            durationMinutes,
            totalAmount,
            paymentStatus: "pendiente"
        });

        // Marcar el espacio como disponible en Firestore
        await db.collection("parkingSlots").doc(slotId).update({ isAvailable: true });

        io.emit("update", { message: `El espacio ${slotId} ahora está disponible` });

        res.status(201).json({
            message: "Salida registrada",
            plateNumber,
            durationMinutes,
            totalAmount: `$${totalAmount.toFixed(2)}`
        });

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});


/**  Historial de estacionamientos y pagos */
app.get("/history/:plateNumber", async (req, res) => {
    try {
        const { plateNumber } = req.params;
        const history = await db.collection("exits")
            .where("plateNumber", "==", plateNumber)
            .orderBy("exitTime", "desc")
            .get();

        if (history.empty) {
            return res.status(404).json({ error: "No hay historial para esta placa" });
        }

        const data = history.docs.map(doc => doc.data());

        res.json(data);

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**  Obtener disponibilidad en tiempo real */
app.get("/availability", async (req, res) => {
    try {
        const snapshot = await db.collection("parkingSlots").get();
        const slots = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        res.json(slots);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**  WebSockets para actualizar en tiempo real */
io.on("connection", (socket) => {
    console.log("Nuevo cliente conectado");
    socket.on("disconnect", () => console.log("Cliente desconectado"));
});

// Iniciar el servidor
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(` Servidor corriendo en http://localhost:${PORT}`);
});
