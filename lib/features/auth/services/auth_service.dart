import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

class AuthResult {
  final String token;
  final String email;
  final String rol;

  AuthResult({
    required this.token,
    required this.email,
    required this.rol,
  });
}

class AuthService {
  // Configurado con localhost para pruebas en celular físico mediante ADB reverse
  static const String baseUrl = 'http://localhost:8080/api/auth';
  static const String serverUrl = 'http://localhost:8080';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null && token.isNotEmpty;
  }

  Future<bool> register({
    required String nombre,
    required String email,
    required String telefono,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/registro'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombreCompleto': nombre,
          'email': email,
          'telefono': telefono,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isNotEmpty) {
          try {
            final data = json.decode(response.body);
            final token = data['token'] ?? data['jwt'] ?? '';
            if (token.toString().isNotEmpty) {
              await _storage.write(key: 'jwt_token', value: token.toString());
            }
          } catch (_) {}
        }
        return true;
      }
    } catch (e) {
      print('Error en registro: $e');
    }
    return false;
  }

  Future<AuthResult?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'] ?? data['jwt'] ?? '';
        final rol = data['rol'] ?? 'CIUDADANO';
        final userEmail = data['email'] ?? email;

        await _storage.write(key: 'jwt_token', value: token);
        return AuthResult(token: token, email: userEmail, rol: rol);
      }
    } catch (e) {
      print('Error en login convencional: $e');
    }
    return null;
  }

  Future<AuthResult?> loginConOAuth(String provider) async {
    try {
      final url = '$serverUrl/oauth2/authorization/$provider';
      final resultUrl = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: 'zonasos',
      );

      final uri = Uri.parse(resultUrl);
      final token = uri.queryParameters['token'] ?? '';
      final email = uri.queryParameters['email'] ?? '';
      final rol = uri.queryParameters['rol'] ?? 'CIUDADANO';

      if (token.isNotEmpty) {
        await _storage.write(key: 'jwt_token', value: token);
        return AuthResult(token: token, email: email, rol: rol);
      }
    } catch (e) {
      print('Error en login OAuth ($provider): $e');
    }
    return null;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }
}