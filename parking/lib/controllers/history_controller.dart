import 'package:flutter/material.dart';
import '../services/api_services.dart';

class HistoryController with ChangeNotifier {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get history => _history;
  bool get isLoading => _isLoading;

  ///  **Obtener historial de estacionamiento**
  Future<void> fetchHistory(String plateNumber) async {
    _isLoading = true;
    notifyListeners();

    try {
      _history = await ApiService.getHistory(plateNumber);
    } catch (e) {
      print("Error obteniendo historial: $e");
    }

    _isLoading = false;
    notifyListeners();
  }
}
