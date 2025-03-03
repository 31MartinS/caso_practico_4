import 'package:flutter/material.dart';
import '../services/api_services.dart';

class ExitController with ChangeNotifier {
  int? durationMinutes;
  String? totalAmount;

  Future<bool> registerExit(String plateNumber, String slotId) async {
    final response = await ApiService.registerExit(plateNumber, slotId);
    if (response != null) {
      durationMinutes = response["durationMinutes"];
      totalAmount = response["totalAmount"];
      notifyListeners();
      return true;
    }
    return false;
  }
}
