const express = require("express");
const multer = require("multer");
const vision = require("@google-cloud/vision");
const cors = require("cors");
const fs = require("fs");

//  Configurar credenciales de Google Cloud Vision
process.env.GOOGLE_APPLICATION_CREDENTIALS = "./google-cloud-key.json";

// Inicializar cliente de Vision API
const client = new vision.ImageAnnotatorClient();

// Configurar Express
const app = express();
const upload = multer({ dest: "uploads/" });

app.use(cors());
app.use(express.json());

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
  
      // Obtener el texto detectado
      const detectedText = detections[0].description.trim();
  
      // Expresión regular para detectar el formato de placas de Ecuador
      const plateRegex = /[A-Z]{3}-\d{3,4}/; // Busca patrones tipo "ABC-123" o "ABC-1234"
  
      const match = detectedText.match(plateRegex);
      const detectedPlate = match ? match[0] : "Placa no encontrada";
  
      // Eliminar la imagen temporal
      fs.unlinkSync(imagePath);
  
      res.json({ plateNumber: detectedPlate, message: "Placa detectada correctamente" });
  
    } catch (error) {
      console.error("❌ Error en OCR:", error);
      res.status(500).json({ error: "Error en el reconocimiento de placas" });
    }
  });
  

/** Endpoint de prueba */
app.get("/", (req, res) => {
  res.send("🚀 Servidor de OCR con Google Cloud Vision API funcionando correctamente.");
});

// Iniciar el servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});
