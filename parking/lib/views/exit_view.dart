import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/exit_controller.dart';
import '../controllers/entry_controller.dart';

class ExitView extends StatefulWidget {
  @override
  _ExitViewState createState() => _ExitViewState();
}

class _ExitViewState extends State<ExitView> {
  String? _selectedPlate;
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final entryController =
      Provider.of<EntryController>(context, listen: false);
      if (entryController.lastEntryPlate != null &&
          entryController.lastEntrySlot != null) {
        setState(() {
          _selectedPlate = entryController.lastEntryPlate;
          _selectedSlot = entryController.lastEntrySlot;
        });
      }
    });
  }

  void _registerExit() async {
    if (_selectedPlate == null || _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No hay datos de entrada registrados"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final exitController = Provider.of<ExitController>(context, listen: false);
    bool success =
    await exitController.registerExit(_selectedPlate!, _selectedSlot!);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Salida registrada"),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error registrando salida"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final exitController = Provider.of<ExitController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Registrar Salida", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 4,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  **Tarjeta de la Placa**
            _infoCard(
              icon: Icons.directions_car,
              label: "Placa registrada",
              value: _selectedPlate ?? "No registrada",
            ),

            SizedBox(height: 20),

            //  **Tarjeta del Espacio Asignado**
            _infoCard(
              icon: Icons.local_parking,
              label: "Espacio asignado",
              value: _selectedSlot ?? "No asignado",
            ),

            SizedBox(height: 20),

            //  **Botón de Registrar Salida**
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _registerExit,
                icon: Icon(Icons.exit_to_app, color: Colors.white),
                label: Text("Registrar Salida", style: TextStyle(fontSize: 18,color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            //  **Mostrar duración y total si está disponible**
            if (exitController.durationMinutes != null &&
                exitController.totalAmount != null)
              Card(
                color: Colors.blue[50],
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer, color: Colors.blue),
                          SizedBox(width: 10),
                          Text(
                            "Tiempo estacionado: ${exitController.durationMinutes} minutos",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: Colors.green),
                          SizedBox(width: 10),
                          Text(
                            "Total a pagar: ${exitController.totalAmount}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  ///  **Función para mostrar tarjetas de información**
  Widget _infoCard({required IconData icon, required String label, required String value}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "$label:\n$value",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
