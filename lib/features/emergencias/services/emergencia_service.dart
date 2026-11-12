import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zonasos_flutter/features/emergencias/models/emergencia_model.dart';

class EmergenciaService {
  // Backend en producción (Render).
  // Para probar contra tu PC con el emulador: 'http://10.0.2.2:8080/api/alertas'
  static const String baseUrl = 'https://alertas-cartagena-backend.onrender.com/api/alertas';

  // Render (plan gratis) puede tardar hasta ~1 minuto en despertar
  static const Duration _timeout = Duration(seconds: 90);

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<EmergenciaModel>> obtenerEmergencias() async {
    try {
      final headers = await _getHeaders();
      final response =
          await http.get(Uri.parse(baseUrl), headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((item) => EmergenciaModel.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error al consultar alertas en el servidor: $e');
    }
    return [];
  }

  Future<bool> guardarEmergencia(EmergenciaModel nueva) async {
    try {
      final headers = await _getHeaders();
      final body = nueva.toJson();

      // Igual que la web: asociar la alerta al usuario que la reporta
      final userId = await _storage.read(key: 'user_id');
      if (userId != null && userId.isNotEmpty) {
        body['usuarioId'] = userId;
      }

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(_timeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error al guardar emergencia en el servidor: $e');
      return false;
    }
  }

  Future<bool> actualizarEstadoEmergencia(String id, String nuevoEstado) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl/$id'),
            headers: headers,
            body: json.encode({
              'estado': EmergenciaModel.estadoHaciaBackend(nuevoEstado),
            }),
          )
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Error al actualizar estado en el servidor: $e');
      return false;
    }
  }
}