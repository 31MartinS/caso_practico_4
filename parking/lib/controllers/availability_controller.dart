import 'package:flutter/material.dart';
import '../services/api_services.dart';
import '../models/parking_slot.dart';

class AvailabilityController with ChangeNotifier {
  List<ParkingSlot> _slots = [];
  bool _isLoading = false;

  List<ParkingSlot> get slots => _slots;
  bool get isLoading => _isLoading;

  ///Obtener espacios disponibles
  Future<void> fetchAvailableSlots() async {
    _isLoading = true;
    notifyListeners();

    try {
      _slots = await ApiService.getAvailableSlots();
    } catch (e) {
      print("Error obteniendo disponibilidad: $e");
    }

    _isLoading = false;
    notifyListeners();
  }
}
