import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/entry_controller.dart';
import '../controllers/availability_controller.dart';
import '../controllers/plate_scan_controller.dart';

class EntryView extends StatefulWidget {
  @override
  _EntryViewState createState() => _EntryViewState();
}

class _EntryViewState extends State<EntryView> {
  String? _selectedPlate;
  String? _selectedSlot;
  bool _isSubmitted = false; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final availabilityController =
      Provider.of<AvailabilityController>(context, listen: false);
      availabilityController.fetchAvailableSlots();
    });

    // Llenar automáticamente la placa detectada
    final plateScanController =
    Provider.of<PlateScanController>(context, listen: false);
    _selectedPlate = plateScanController.getDetectedPlate();
  }

  void _registerEntry() async {
    if (_selectedPlate == null || _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Debe seleccionar una placa y un espacio disponible")));
      return;
    }

    bool success = await Provider.of<EntryController>(context, listen: false)
        .registerEntry(_selectedPlate!, _selectedSlot!);

    if (success) {
      setState(() {
        _isSubmitted = true; //  Marcar como enviado
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? "Entrada registrada" : "Error registrando entrada"),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final plateScanController = Provider.of<PlateScanController>(context);
    final availabilityController = Provider.of<AvailabilityController>(context);

    //  Filtrar solo los espacios disponibles
    final availableSlots =
    availabilityController.slots.where((slot) => slot.isAvailable).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Registrar Entrada", style: TextStyle(color: Colors.white)),
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
            //  Mostrar la última placa detectada automáticamente en un campo de texto
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.car_repair, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedPlate ?? "No hay placa detectada",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            Text(
              "Selecciona un espacio disponible:",
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
                  childAspectRatio: 1.8, //  Ajuste de tamaño de cada elemento
                ),
                itemCount: availableSlots.length,
                itemBuilder: (context, index) {
                  final slot = availableSlots[index];
                  return GestureDetector(
                    onTap: _isSubmitted
                        ? null //  Deshabilitar selección después del envío
                        : () {
                      setState(() {
                        _selectedSlot = slot.id;
                      });
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _selectedSlot == slot.id
                              ? Colors.blue
                              : Colors.grey,
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
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
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

            //  **Botón de Registrar Entrada con mejor estilo**
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitted ? null : _registerEntry, //  Deshabilitar después del envío
                icon: Icon(Icons.check_circle, color: Colors.white),
                label: Text("Registrar Entrada",
                    style: TextStyle(fontSize: 18, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSubmitted ? Colors.grey : Colors.blue, //  Cambia el color
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            if (_isSubmitted) //  Mostrar mensaje de confirmación después del registro
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Center(
                  child: Text(
                    "Entrada registrada con éxito",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
