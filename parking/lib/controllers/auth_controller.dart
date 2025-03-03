import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_services.dart';

class AuthController with ChangeNotifier {
  String? _token;

  String? get token => _token;

  ///  **Registrar usuario**
  Future<bool> register(String name, String email, String password) async {
    final result = await ApiService.registerUser(name, email, password);
    if (result != null && result.containsKey("uid")) {
      return true;
    }
    return false;
  }

  ///  **Iniciar sesión**
  Future<bool> login(String email, String password) async {
    final result = await ApiService.loginUser(email, password);
    if (result != null && result.containsKey("token")) {
      _token = result["token"];

      //  Guardar token localmente para mantener la sesión
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("auth_token", _token!);

      notifyListeners();
      return true;
    }
    return false;
  }

  ///  **Verificar si hay una sesión activa**
  Future<bool> checkAuthStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedToken = prefs.getString("auth_token");

    if (savedToken != null) {
      bool isValid = await ApiService.verifyToken();
      if (isValid) {
        _token = savedToken;
        notifyListeners();
        return true;
      } else {
        await logout();
      }
    }
    return false;
  }

  ///  **Cerrar sesión**
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    _token = null;
    notifyListeners();
  }
}
