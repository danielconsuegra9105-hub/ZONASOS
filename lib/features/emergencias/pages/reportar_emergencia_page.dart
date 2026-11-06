import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/emergencia_model.dart';
import '../services/emergencia_service.dart';

class ReportarEmergenciaPage extends StatefulWidget {
  final LatLng? ubicacion;

  const ReportarEmergenciaPage({super.key, this.ubicacion});

  @override
  State<ReportarEmergenciaPage> createState() => _ReportarEmergenciaPageState();
}

class _ReportarEmergenciaPageState extends State<ReportarEmergenciaPage> {
  final _descripcionController = TextEditingController();
  final _emergenciaService = EmergenciaService();
  String _tipoSeleccionado = 'Incendio';
  bool _isSubmitting = false;

  final List<String> _tiposEmergencia = [
    'Incendio',
    'Inundación',
    'Accidente de Tránsito',
    'Robo / Inseguridad',
    'Emergencia Médica',
    'Otro',
  ];

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  void _enviarReporte() async {
    final descripcion = _descripcionController.text.trim();
    if (descripcion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa una descripción del suceso')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final nuevaEmergencia = EmergenciaModel(
      id: 'SOS_${DateTime.now().millisecondsSinceEpoch}',
      tipo: _tipoSeleccionado,
      descripcion: descripcion,
      lat: widget.ubicacion?.latitude ?? 10.39972,
      lng: widget.ubicacion?.longitude ?? -75.51444,
      fecha: DateTime.now(),
    );

    final exito = await _emergenciaService.guardarEmergencia(nuevaEmergencia);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 ¡Emergencia registrada e ingresada al sistema!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Devuelve 'true' para refrescar el Dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    final latStr = widget.ubicacion?.latitude.toStringAsFixed(4) ?? '10.3997';
    final lngStr = widget.ubicacion?.longitude.toStringAsFixed(4) ?? '-75.5144';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFDC3545),
        title: const Text(
          'Reportar Emergencia',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detalles de la Emergencia',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Emergencia',
                  border: OutlineInputBorder(),
                ),
                items: _tiposEmergencia.map((String tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _tipoSeleccionado = val);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descripcionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descripción del suceso',
                  hintText: 'Describe brevemente lo que ocurre en el lugar...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.grey.shade100,
                child: ListTile(
                  leading: const Icon(Icons.my_location, color: Colors.red),
                  title: const Text('Ubicación fijada'),
                  subtitle: Text('Lat: $latStr, Lng: $lngStr'),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC3545),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isSubmitting ? null : _enviarReporte,
                  icon: _isSubmitting
                      ? const SizedBox.shrink()
                      : const Icon(Icons.send),
                  label: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'ENVIAR REPORTE',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}