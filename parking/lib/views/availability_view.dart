import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/availability_controller.dart';

class AvailabilityView extends StatefulWidget {
  @override
  _AvailabilityViewState createState() => _AvailabilityViewState();
}

class _AvailabilityViewState extends State<AvailabilityView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<AvailabilityController>(context, listen: false).fetchAvailableSlots());
  }

  @override
  Widget build(BuildContext context) {
    final availabilityController = Provider.of<AvailabilityController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Disponibilidad de Parqueaderos",style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: availabilityController.isLoading
            ? Center(child: CircularProgressIndicator())
            : availabilityController.slots.isEmpty
            ? Center(
          child: Text(
            "No hay espacios disponibles",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        )
            : GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemCount: availabilityController.slots.length,
          itemBuilder: (context, index) {
            final slot = availabilityController.slots[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
              color: slot.isAvailable ? Colors.green[100] : Colors.red[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      slot.isAvailable ? Icons.local_parking : Icons.block,
                      size: 50,
                      color: slot.isAvailable ? Colors.green : Colors.red,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Espacio: ${slot.id}",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      slot.isAvailable ? "Disponible" : "Ocupado",
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    SizedBox(height: 8),
                    //  **Mostrar el nivel del espacio**
                    Text(
                      "Nivel: ${slot.level}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
