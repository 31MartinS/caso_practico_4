import 'package:flutter/material.dart';
import '../services/api_services.dart';

class ReserveController with ChangeNotifier {
  bool _isLoading = false;
  String? _message;
  List<Map<String, dynamic>> _reservations = [];

  bool get isLoading => _isLoading;
  String? get message => _message;
  List<Map<String, dynamic>> get reservations => _reservations;

  ///  **Reservar un espacio de parqueo**
  Future<void> reserveSlot(String slotId) async {
    _isLoading = true;
    _message = null;
    notifyListeners();

    try {
      final result = await ApiService.reserveSlot(slotId);

      if (result != null && result.containsKey("message")) {
        _message = "${result["message"]}";
        await fetchReservations(); //  Actualizar la lista de reservas
      } else {
        _message = "Error al reservar el espacio";
      }
    } catch (e) {
      _message = "Ocurrió un error: $e";
      print("Error en la reserva: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
      _clearMessageAfterDelay();
    }
  }

  ///  **Obtener todas las reservas del usuario**
  Future<void> fetchReservations() async {
    _isLoading = true;
    notifyListeners();

    try {
      _reservations = await ApiService.getReservations();
      print("${_reservations.length} reservas encontradas.");
    } catch (e) {
      print("Error obteniendo reservas: $e");
      _message = "Error al cargar reservas.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ///  **Cancelar una reserva**
  Future<void> cancelReservation(String reservationId) async {
    _isLoading = true;
    _message = null;
    notifyListeners();

    try {
      print("Cancelando reserva: $reservationId");

      bool success = await ApiService.cancelReservation(reservationId);

      if (success) {
        _message = "Reserva cancelada correctamente";
        print("Reserva eliminada.");
        await fetchReservations();
      } else {
        _message = "No se pudo cancelar la reserva";
        print("Error cancelando la reserva");
      }
    } catch (e) {
      _message = "Ocurrió un error: $e";
      print("Error en la cancelación de la reserva: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
      _clearMessageAfterDelay();
    }
  }

  ///  **Limpia el mensaje después de 3 segundos**
  void _clearMessageAfterDelay() {
    Future.delayed(Duration(seconds: 3), () {
      _message = null;
      notifyListeners();
    });
  }
}
