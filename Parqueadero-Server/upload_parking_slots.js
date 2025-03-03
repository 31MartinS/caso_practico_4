const admin = require("firebase-admin");

// Cargar credenciales de Firebase
const serviceAccount = require("./firebase-service-account2.json"); 

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Definir niveles y sus prefijos
const levels = {
  "Subsuelo": "sub",
  "Suelo 1": "L1",
  "Suelo 2": "L2"
};

const letters = ["A", "B", "C", "D"]; 
const numbers = 9; 

async function uploadParkingSlots() {
  try {
    for (const [levelName, prefix] of Object.entries(levels)) {
      for (let letter of letters) {
        for (let num = 1; num <= numbers; num++) {
          const slotId = `${prefix}_${letter}${num}`; 

          await db.collection("parkingSlots").doc(slotId).set({
            slotId: `${letter}${num}`,
            level: levelName,
            isAvailable: true
          });

          console.log(`Agregado: ${slotId}`);
        }
      }
    }
    console.log("Importación completada.");
  } catch (error) {
    console.error("Error al importar:", error);
  }
}

uploadParkingSlots();
