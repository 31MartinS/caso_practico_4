import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/plate_model.dart';
import '../models/parking_slot.dart';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://localhost:3000";

  ///  **Registrar usuario**
  static Future<Map<String, dynamic>?> registerUser(
      String name, String email, String password) async {
    try {

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "email": email, "password": password}),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Error al registrar usuario"};
      }
    } catch (e) {
      return {"error": "Error en el registro"};
    }
  }

  static Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    try {
      print("📤 Enviando solicitud de inicio de sesión...");

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      print(" Respuesta del servidor (Login): ${response.statusCode}");
      print(" Cuerpo de la respuesta: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Extraer datos del usuario
        final String? token = responseData["token"];
        final String? userId = responseData["uid"];
        final String userName = responseData["name"] ?? "Usuario";
        final String userEmail = responseData["email"] ?? "Correo no disponible";

        // Validar datos recibidos
        if (token == null || userId == null) {
          print("Datos incompletos en la respuesta del servidor");
          return {"error": "Datos incompletos en la respuesta del servidor"};
        }

        // Guardar en `SharedPreferences`
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", token);
        await prefs.setString("user_id", userId);
        await prefs.setString("user_name", userName);
        await prefs.setString("user_email", userEmail);

        print("Datos guardados correctamente en SharedPreferences");
        return responseData;
      } else {
        print("Error en el inicio de sesión: ${response.body}");
        return {"error": "Error en el inicio de sesión"};
      }
    } catch (e) {
      print("Error en el inicio de sesión: $e");
      return {"error": "Error en el inicio de sesión"};
    }
  }


  ///  **Obtener token guardado**
  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  ///  **Verificar token de autenticación**
  static Future<bool> verifyToken() async {
    try {
      String? token = await getToken();
      if (token == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/verify-token'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": token}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error verificando token: $e");
      return false;
    }
  }

  ///  **Cerrar sesión**
  static Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    print(" Sesión cerrada");
  }

  ///  **Escanear placa**
  static Future<Map<String, dynamic>> scanPlate(String imagePath, Uint8List? imageBytes) async {
    var uri = Uri.parse('$baseUrl/scan-plate');
    var request = http.MultipartRequest("POST", uri);

    if (kIsWeb && imageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: "upload.jpg",
      ));
    } else if (!kIsWeb && imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    } else {
      throw Exception("No se proporcionó una imagen válida para el escaneo.");
    }

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    try {
      final jsonDecoded = json.decode(responseData);
      if (jsonDecoded is Map<String, dynamic>) {
        return jsonDecoded;
      } else {
        throw Exception("Respuesta inesperada del servidor: $jsonDecoded");
      }
    } catch (e) {
      throw Exception("Error procesando respuesta del servidor: $e");
    }
  }

  ///  **Obtener placas detectadas**
  static Future<List<String>> getDetectedPlates() async {
    final response = await http.get(Uri.parse('$baseUrl/detected-plates'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data["plates"]);
    } else {
      throw Exception("Error obteniendo placas detectadas");
    }
  }

  ///  **Obtener disponibilidad de parqueaderos**
  static Future<List<ParkingSlot>> getAvailableSlots() async {
    final response = await http.get(Uri.parse('$baseUrl/availability'));

    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((slot) => ParkingSlot.fromJson(slot)).toList();
    } else {
      throw Exception("Error obteniendo disponibilidad");
    }
  }

  ///  **Registrar entrada de vehículo**
  static Future<bool> registerEntry(String plateNumber, String slotId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/entry'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"plateNumber": plateNumber, "slotId": slotId}),
    );

    return response.statusCode == 201;
  }


  ///  **Registrar salida de vehículo**
  static Future<Map<String, dynamic>?> registerExit(String plateNumber, String slotId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/exit'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"plateNumber": plateNumber, "slotId": slotId}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  ///  **Consultar historial de estacionamientos y pagos**
  static Future<List<Map<String, dynamic>>> getHistory(String plateNumber) async {
    final response = await http.get(Uri.parse('$baseUrl/history/$plateNumber'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception("Error obteniendo historial");
    }
  }
  ///  **Reservar un espacio de parqueo**
  static Future<Map<String, dynamic>?> reserveSlot(String slotId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString("user_id");

      if (userId == null) {
        return {"error": "Usuario no autenticado. Inicie sesión."};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/reserve'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId, "slotId": slotId}),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {"error": "No se pudo reservar el espacio"};
      }
    } catch (e) {
      return {"error": "Error en la reserva"};
    }
  }

  ///  **Obtener todas las reservas del usuario**
  static Future<List<Map<String, dynamic>>> getReservations() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString("user_id");

      if (userId == null) {
        return [];
      }

      final response = await http.get(Uri.parse('$baseUrl/reservations/$userId'));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  ///  **Cancelar una reserva**
  static Future<bool> cancelReservation(String reservationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cancel-reservation/$reservationId'),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

}
