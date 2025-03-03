import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/history_controller.dart';
import '../controllers/plate_scan_controller.dart';

class HistoryView extends StatefulWidget {
  @override
  _HistoryViewState createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  String? _selectedPlate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final plateScanController =
      Provider.of<PlateScanController>(context, listen: false);
      final detectedPlate = plateScanController.getDetectedPlate();

      if (detectedPlate != null) {
        setState(() {
          _selectedPlate = detectedPlate;
        });
        _fetchHistory(detectedPlate);
      }
    });
  }

  void _fetchHistory(String plate) {
    if (plate.isNotEmpty) {
      Provider.of<HistoryController>(context, listen: false).fetchHistory(plate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyController = Provider.of<HistoryController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Historial de Estacionamientos",style: TextStyle(color: Colors.white)),
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
            //  **Tarjeta para mostrar la placa detectada**
            _infoCard(
              icon: Icons.directions_car,
              label: "Placa detectada",
              value: _selectedPlate ?? "No hay placa detectada",
            ),

            SizedBox(height: 20),

            //  **Lista del historial de estacionamientos**
            Expanded(
              child: historyController.isLoading
                  ? Center(child: CircularProgressIndicator())
                  : historyController.history.isEmpty
                  ? _emptyHistoryMessage()
                  : ListView.builder(
                itemCount: historyController.history.length,
                itemBuilder: (context, index) {
                  final record = historyController.history[index];
                  return _historyCard(record);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///  **Tarjeta de información (para la placa)**
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

  ///  **Tarjeta de historial de estacionamientos**
  Widget _historyCard(Map<String, dynamic> record) {
    Color statusColor = record['paymentStatus'] == "pendiente" ? Colors.red[100]! : Colors.green[100]!;
    IconData statusIcon = record['paymentStatus'] == "pendiente" ? Icons.warning : Icons.check_circle;

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      color: statusColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, color: Colors.blue),
                SizedBox(width: 10),
                Text(
                  "Placa: ${record['plateNumber']}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer, color: Colors.blueGrey),
                SizedBox(width: 10),
                Text("Duración: ${record['durationMinutes']} min"),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money, color: Colors.green),
                SizedBox(width: 10),
                Text("Total: ${record['totalAmount']}"),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(statusIcon, color: record['paymentStatus'] == "pendiente" ? Colors.red : Colors.green),
                SizedBox(width: 10),
                Text(
                  "Estado de pago: ${record['paymentStatus']}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: record['paymentStatus'] == "pendiente" ? Colors.red[800] : Colors.green[800],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ///  **Mensaje cuando no hay historial**
  Widget _emptyHistoryMessage() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "No hay historial para esta placa",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
