import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/auth_controller.dart';
import 'availability_view.dart';
import 'plate_scan_view.dart';
import 'entry_view.dart';
import 'exit_view.dart';
import 'history_view.dart';
import 'reserve_view.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0; // Índice de la pestaña seleccionada
  String _displayName = "Usuario no disponible";
  String _email = "Correo no disponible";

  @override
  void initState() {
    super.initState();
    _loadUserData(); //  Cargar datos del usuario al iniciar la vista
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _displayName = prefs.getString("user_name") ?? "Usuario no disponible";
      _email = prefs.getString("user_email") ?? "Correo no disponible";
    });
  }

  final List<Widget> _screens = [
    AvailabilityView(),
    PlateScanView(),
    EntryView(),
    ExitView(),
    HistoryView(),
    ReserveView(),
  ];

  final List<String> _titles = [
    "Disponibilidad",
    "Escanear Placa",
    "Registrar Entrada",
    "Registrar Salida",
    "Historial",
    "Reservar",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Parqueadero")
      ),
      drawer: _buildDrawer(context),
      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.local_parking), label: "Disponibilidad"),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: "Escanear"),
          BottomNavigationBarItem(icon: Icon(Icons.input), label: "Entrada"),
          BottomNavigationBarItem(icon: Icon(Icons.exit_to_app), label: "Salida"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Historial"),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: "Reservar"),
        ],
      ),
    );
  }

  ///  **Navigation Drawer con usuario autenticado y botón de logout**
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            accountName: Text(_displayName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            accountEmail: Text(_email, style: TextStyle(fontSize: 16)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Colors.blue),
            ),
          ),
          _drawerItem(context, Icons.local_parking, "Disponibilidad", 0),
          _drawerItem(context, Icons.camera_alt, "Escanear Placa", 1),
          _drawerItem(context, Icons.input, "Registrar Entrada", 2),
          _drawerItem(context, Icons.exit_to_app, "Registrar Salida", 3),
          _drawerItem(context, Icons.history, "Historial", 4),
          _drawerItem(context, Icons.book_online, "Reservar", 5),

          Divider(), // Línea separadora

          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  ///  **Elemento del Navigation Drawer**
  Widget _drawerItem(BuildContext context, IconData icon, String text, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context); // Cierra el Drawer
      },
    );
  }

  ///  **Cerrar sesión y redirigir a Login**
  void _logout(BuildContext context) async {
    final authController = Provider.of<AuthController>(context, listen: false);
    await authController.logout();

    Navigator.pushReplacementNamed(context, "/login"); // Redirige al login
  }
}
