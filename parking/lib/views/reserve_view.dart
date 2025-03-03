import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/reserve_controller.dart';
import '../controllers/availability_controller.dart';

class ReserveView extends StatefulWidget {
  @override
  _ReserveViewState createState() => _ReserveViewState();
}

class _ReserveViewState extends State<ReserveView> {
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AvailabilityController>(context, listen: false).fetchAvailableSlots();
      Provider.of<ReserveController>(context, listen: false).fetchReservations();
    });
  }

  void _reserveSlot() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Debe seleccionar un espacio para reservar")),
      );
      return;
    }

    final reserveController = Provider.of<ReserveController>(context, listen: false);
    await reserveController.reserveSlot(_selectedSlot!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(reserveController.message ?? "Error en la reserva"),
        backgroundColor: reserveController.message == "Reserva exitosa" ? Colors.green : Colors.red,
      ),
    );

    if (reserveController.message == "Reserva exitosa") {
      _selectedSlot = null;
      await reserveController.fetchReservations(); //  Actualiza lista de reservas
    }
  }

  void _cancelReservation(String reservationId) async {
    final reserveController = Provider.of<ReserveController>(context, listen: false);
    await reserveController.cancelReservation(reservationId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(reserveController.message ?? "Error al cancelar la reserva"),
        backgroundColor: reserveController.message == "Reserva cancelada correctamente" ? Colors.green : Colors.red,
      ),
    );

    await reserveController.fetchReservations(); //  Actualiza lista después de cancelar
  }

  @override
  Widget build(BuildContext context) {
    final availabilityController = Provider.of<AvailabilityController>(context);
    final reserveController = Provider.of<ReserveController>(context);

    final availableSlots = availabilityController.slots.where((slot) => slot.isAvailable).toList();
    final userReservations = reserveController.reservations;

    return Scaffold(
      appBar: AppBar(
        title: Text("Reservar Espacio", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  **Sección de Espacios Disponibles**
            Text(
              "Seleccione un espacio disponible:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            availabilityController.isLoading
                ? Center(child: CircularProgressIndicator())
                : availableSlots.isEmpty
                ? Center(
              child: Text(
                "No hay espacios disponibles",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
                : Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, //  **Dos columnas**
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.8,
                ),
                itemCount: availableSlots.length,
                itemBuilder: (context, index) {
                  final slot = availableSlots[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSlot = slot.id;
                      });
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _selectedSlot == slot.id ? Colors.blue : Colors.grey,
                          width: 2,
                        ),
                      ),
                      color: Colors.green[100],
                      elevation: 3,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_parking,
                              size: 40,
                              color: Colors.green,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Espacio: ${slot.id}",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 20),

            //  **Botón de Reservar**
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _reserveSlot,
                icon: Icon(Icons.check_circle, color: Colors.white),
                label: Text("Reservar Espacio", style: TextStyle(fontSize: 18, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            SizedBox(height: 30),

            //  **Sección de Reservas Activas**
            Text(
              "Mis Reservas Activas:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            reserveController.isLoading
                ? Center(child: CircularProgressIndicator())
                : userReservations.isEmpty
                ? Center(
              child: Text(
                "No tiene reservas activas",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
                : Expanded(
              child: ListView.builder(
                itemCount: userReservations.length,
                itemBuilder: (context, index) {
                  final reservation = userReservations[index];

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: Icon(Icons.car_rental, color: Colors.blue),
                      title: Text("Espacio: ${reservation['slotId']}"),
                      subtitle: Text("Reserva ID: ${reservation['id']}"),
                      trailing: IconButton(
                        icon: Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _cancelReservation(reservation['id']),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
