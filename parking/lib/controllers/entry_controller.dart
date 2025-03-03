import 'package:flutter/material.dart';
import '../services/api_services.dart';

class EntryController with ChangeNotifier {
  String? lastEntryPlate;
  String? lastEntrySlot;

  Future<bool> registerEntry(String plateNumber, String slotId) async {
    bool success = await ApiService.registerEntry(plateNumber, slotId);
    if (success) {
      lastEntryPlate = plateNumber;
      lastEntrySlot = slotId;
      notifyListeners();
    }
    return success;
  }

  // Metodo para obtener la última placa registrada
  String? getLastEntryPlate() {
    return lastEntryPlate;
  }

  // Metodo para obtener el último espacio registrado
  String? getLastEntrySlot() {
    return lastEntrySlot;
  }
}
