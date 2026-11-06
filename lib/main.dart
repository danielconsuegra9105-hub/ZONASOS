import 'package:flutter/material.dart';
import 'package:zonasos_flutter/features/auth/services/auth_service.dart';
import 'package:zonasos_flutter/features/auth/pages/login_page.dart';
import 'package:zonasos_flutter/features/home/pages/dashboard_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return MaterialApp(
      title: 'ZonaSOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFDC3545)),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: authService.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data == true) {
            return const DashboardPage(rol: 'CIUDADANO', email: '');
          }

          return const LoginPage();
        },
      ),
    );
  }
}