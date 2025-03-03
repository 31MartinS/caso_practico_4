import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_services.dart';

class PlateScanController with ChangeNotifier {
  bool isScanning = false;
  String? detectedPlate;

  ///  **Escanear Placa y Guardar en Estado**
  Future<void> scanPlate(String? imagePath, {Uint8List? imageBytes}) async {
    if ((imagePath == null || imagePath.isEmpty) && imageBytes == null) {
      print(" Error: No hay imagen para procesar");
      return;
    }

    isScanning = true;
    notifyListeners();

    try {
      final response = await ApiService.scanPlate(imagePath ?? "", imageBytes);
      detectedPlate = response["plateNumber"];
      notifyListeners();
    } catch (e) {
      print(" Error al escanear placa: $e");
      detectedPlate = null;
    }

    isScanning = false;
    notifyListeners();
  }

  ///  **Obtener la última placa detectada**
  String? getDetectedPlate() {
    return detectedPlate;
  }
}
