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
  // Backend en producción (Render).
  // Para probar contra tu PC con el emulador: 'http://10.0.2.2:8080'
  static const String serverUrl = 'https://alertas-cartagena-backend.onrender.com';
  static const String baseUrl = '$serverUrl/api/auth';

  // Render (plan gratis) puede tardar hasta ~1 minuto en despertar
  static const Duration _timeout = Duration(seconds: 90);

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
      // Los nombres de campo coinciden con el modelo Usuario del backend
      final response = await http
          .post(
            Uri.parse('$baseUrl/registro'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'nombre': nombre,
              'correo': email,
              'telefono': telefono,
              'password': password,
              'rol': 'CIUDADANO',
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isNotEmpty) {
          try {
            final data = json.decode(response.body);
            final token = data['token'] ?? data['jwt'] ?? '';
            if (token.toString().isNotEmpty) {
              await _storage.write(key: 'jwt_token', value: token.toString());
            }
            final id = data['id']?.toString() ?? '';
            if (id.isNotEmpty) {
              await _storage.write(key: 'user_id', value: id);
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
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'correo': email, 'password': password}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'] ?? data['jwt'] ?? '';
        final rol = data['rol'] ?? 'CIUDADANO';
        final userEmail = data['correo'] ?? email;
        final id = data['id']?.toString() ?? '';

        await _storage.write(key: 'jwt_token', value: token);
        if (id.isNotEmpty) {
          await _storage.write(key: 'user_id', value: id);
        }
        return AuthResult(token: token, email: userEmail, rol: rol);
      }
    } catch (e) {
      print('Error en login convencional: $e');
    }
    return null;
  }

  Future<AuthResult?> loginConOAuth(String provider) async {
    try {
      // Este endpoint marca la sesión como "móvil" y continúa con Google/GitHub.
      // Al terminar, el backend redirige a zonasos://oauth-success?token=...
      final url = '$baseUrl/mobile/$provider';
      final resultUrl = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: 'zonasos',
      );

      final uri = Uri.parse(resultUrl);
      final token = uri.queryParameters['token'] ?? '';
      final email = uri.queryParameters['email'] ?? '';
      final rol = uri.queryParameters['rol'] ?? 'CIUDADANO';
      final id = uri.queryParameters['id'] ?? '';

      if (token.isNotEmpty) {
        await _storage.write(key: 'jwt_token', value: token);
        if (id.isNotEmpty) {
          await _storage.write(key: 'user_id', value: id);
        }
        return AuthResult(token: token, email: email, rol: rol);
      }
    } catch (e) {
      print('Error en login OAuth ($provider): $e');
    }
    return null;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_id');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }
}