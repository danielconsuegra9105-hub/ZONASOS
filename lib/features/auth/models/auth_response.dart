class AuthResponse {
  final String token;
  final String email;
  final String rol;

  AuthResponse({
    required this.token,
    required this.email,
    required this.rol,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? json['jwt'] ?? '', 
      email: json['email'] ?? '',
      rol: json['rol'] ?? 'CIUDADANO',
    );
  }
}