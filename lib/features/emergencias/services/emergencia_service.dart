import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zonasos_flutter/features/emergencias/models/emergencia_model.dart';

class EmergenciaService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/alertas';
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
      final response = await http.get(Uri.parse(baseUrl), headers: headers);

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
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: json.encode(nueva.toJson()),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error al guardar emergencia en el servidor: $e');
      return false;
    }
  }

  Future<bool> actualizarEstadoEmergencia(String id, String nuevoEstado) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: headers,
        body: json.encode({'estado': nuevoEstado}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error al actualizar estado en el servidor: $e');
      return false;
    }
  }
}