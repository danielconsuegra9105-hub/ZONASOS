import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:zonasos_flutter/features/auth/pages/login_page.dart';
import 'package:zonasos_flutter/features/auth/services/auth_service.dart';
import 'package:zonasos_flutter/features/emergencias/models/emergencia_model.dart';
import 'package:zonasos_flutter/features/emergencias/pages/reportar_emergencia_page.dart';
import 'package:zonasos_flutter/features/emergencias/services/emergencia_service.dart';

class DashboardPage extends StatefulWidget {
  final String rol;
  final String email;

  const DashboardPage({
    super.key,
    required this.rol,
    required this.email,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final LatLng _cartagenaCoords = const LatLng(10.39972, -75.51444);
  LatLng? _ubicacionSeleccionada;
  final _emergenciaService = EmergenciaService();
  List<EmergenciaModel> _listaEmergencias = [];
  bool _cargandoEmergencias = true;

  @override
  void initState() {
    super.initState();
    _cargarEmergencias();
  }

  Future<void> _cargarEmergencias() async {
    setState(() => _cargandoEmergencias = true);
    final reportes = await _emergenciaService.obtenerEmergencias();
    setState(() {
      _listaEmergencias = reportes;
      _cargandoEmergencias = false;
    });
  }

  void _cambiarEstado(EmergenciaModel item, String nuevoEstado) async {
    final exito = await _emergenciaService.actualizarEstadoEmergencia(item.id, nuevoEstado);
    if (exito) {
      _cargarEmergencias();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a "$nuevoEstado"'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _cerrarSesion() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _abrirReporte() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportarEmergenciaPage(
          ubicacion: _ubicacionSeleccionada ?? _cartagenaCoords,
        ),
      ),
    );

    if (resultado == true) {
      _cargarEmergencias();
    }
  }

  Color _getColorByEstado(String estado) {
    switch (estado) {
      case 'EN_ATENCION':
        return Colors.orange;
      case 'RESUELTO':
        return Colors.green;
      case 'PENDIENTE':
      default:
        return Colors.red;
    }
  }

  String _getNombreEstado(String estado) {
    switch (estado) {
      case 'EN_ATENCION':
        return 'En Atención';
      case 'RESUELTO':
        return 'Resuelto';
      case 'PENDIENTE':
      default:
        return 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = _listaEmergencias.where((e) => e.estado == 'PENDIENTE').length;
    final enAtencion = _listaEmergencias.where((e) => e.estado == 'EN_ATENCION').length;
    final resueltos = _listaEmergencias.where((e) => e.estado == 'RESUELTO').length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFDC3545),
        title: Text(
          '🚨 ZonaSOS - ${widget.rol}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualizar',
            onPressed: _cargarEmergencias,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar Sesión',
            onPressed: _cerrarSesion,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirReporte,
        backgroundColor: const Color(0xFFDC3545),
        icon: const Icon(Icons.add_alert, color: Colors.white),
        label: const Text(
          'REPORTAR SOS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, ${widget.email.isNotEmpty ? widget.email : "Usuario"}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Panel de control de emergencias y reportes ciudadanos.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // === CONTADORES SEPARADOS POR ESTADO ===
            Row(
              children: [
                Expanded(
                  child: _TarjetaContador(
                    titulo: 'Pendientes',
                    cantidad: pendientes,
                    color: Colors.red,
                    icono: Icons.warning_amber_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TarjetaContador(
                    titulo: 'En Atención',
                    cantidad: enAtencion,
                    color: Colors.orange.shade800,
                    icono: Icons.pending_actions_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TarjetaContador(
                    titulo: 'Resueltos',
                    cantidad: resueltos,
                    color: Colors.green.shade700,
                    icono: Icons.check_circle_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // === MAPA CON COLORES SEGÚN EL ESTADO Y USER-AGENT VÁLIDO ===
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🗺️ Mapa de Emergencias',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Toca el mapa para fijar una nueva ubicación SOS.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 300,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: _cartagenaCoords,
                          initialZoom: 13.0,
                          onTap: (tapPosition, point) {
                            setState(() {
                              _ubicacionSeleccionada = point;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Punto fijado: Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.zonasos.cartagena.app',
                          ),
                          MarkerLayer(
                            markers: [
                              ..._listaEmergencias.map((e) => Marker(
                                    point: LatLng(e.lat, e.lng),
                                    width: 35,
                                    height: 35,
                                    child: Icon(
                                      Icons.warning_sharp,
                                      color: _getColorByEstado(e.estado),
                                      size: 35,
                                    ),
                                  )),
                              if (_ubicacionSeleccionada != null)
                                Marker(
                                  point: _ubicacionSeleccionada!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.blue,
                                    size: 40,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // === HISTORIAL DE ALERTAS REGISTRADAS ===
            const Text(
              'Historial de Alertas Registradas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_cargandoEmergencias)
              const Center(child: CircularProgressIndicator())
            else if (_listaEmergencias.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No hay alertas registradas aún.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _listaEmergencias.length,
                itemBuilder: (context, index) {
                  final item = _listaEmergencias[index];
                  final colorEstado = _getColorByEstado(item.estado);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorEstado.withOpacity(0.2),
                        child: Icon(Icons.warning, color: colorEstado),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.tipo,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorEstado.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorEstado),
                            ),
                            child: Text(
                              _getNombreEstado(item.estado),
                              style: TextStyle(
                                color: colorEstado,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${item.descripcion}\nLat: ${item.lat.toStringAsFixed(3)}, Lng: ${item.lng.toStringAsFixed(3)}',
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (nuevoEstado) => _cambiarEstado(item, nuevoEstado),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'PENDIENTE',
                            child: Row(
                              children: [
                                Icon(Icons.report_problem, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Marcar Pendiente'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'EN_ATENCION',
                            child: Row(
                              children: [
                                Icon(Icons.pending_actions, color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Text('Marcar En Atención'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'RESUELTO',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text('Marcar Resuelto'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaContador extends StatelessWidget {
  final String titulo;
  final int cantidad;
  final Color color;
  final IconData icono;

  const _TarjetaContador({
    required this.titulo,
    required this.cantidad,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icono, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              '$cantidad',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}