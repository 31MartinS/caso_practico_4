import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../controllers/plate_scan_controller.dart';

class PlateScanView extends StatefulWidget {
  @override
  _PlateScanViewState createState() => _PlateScanViewState();
}

class _PlateScanViewState extends State<PlateScanView> {
  Uint8List? _selectedImageBytes;
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();

  void _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se seleccionó ninguna imagen")),
      );
      return;
    }

    final plateScanController = Provider.of<PlateScanController>(context, listen: false);

    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
      await plateScanController.scanPlate(null, imageBytes: bytes);
    } else {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
      await plateScanController.scanPlate(pickedFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plateScanController = Provider.of<PlateScanController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Escanear Placa",style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //  **Caja para mostrar la imagen seleccionada**
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey, width: 1),
              ),
              child: _selectedImageBytes != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
              )
                  : _selectedImageFile != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_selectedImageFile!, fit: BoxFit.cover),
              )
                  : Center(
                child: Text(
                  "No hay imagen seleccionada",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            ),

            SizedBox(height: 20),

            //  **Botones de selección de imagen**
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: Icons.camera_alt,
                  label: "Cámara",
                  onPressed: () => _pickImage(ImageSource.camera),
                  color: Colors.blue,
                ),
                SizedBox(width: 20),
                _buildActionButton(
                  icon: Icons.photo,
                  label: "Galería",
                  onPressed: () => _pickImage(ImageSource.gallery),
                  color: Colors.green,
                ),
              ],
            ),

            SizedBox(height: 20),

            //  **Indicador de carga o resultado**
            plateScanController.isScanning
                ? CircularProgressIndicator()
                : plateScanController.detectedPlate != null
                ? _resultBox(plateScanController.detectedPlate!)
                : Container(),
          ],
        ),
      ),
    );
  }

  ///  **Botón de acción estilizado**
  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onPressed, required Color color}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: Size(140, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 24),
      label: Text(
        label,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  ///  **Caja de resultado de la placa detectada**
  Widget _resultBox(String plateNumber) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.directions_car, color: Colors.blue, size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Placa detectada: $plateNumber",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
