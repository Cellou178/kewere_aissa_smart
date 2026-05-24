import 'package:flutter/material.dart';
import 'managers/session_manager.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/dashboard/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionManager.init();
  runApp(const KewereApp());
}

class KewereApp extends StatelessWidget {
  const KewereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kewere Aissa Smart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B3A6B)),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        useMaterial3: true,
      ),
      home: SessionManager.isLoggedIn
          ? const DashboardPage()
          : const SplashScreen(),
    );
    // Dans main.dart, dans MaterialApp ajoute :
    theme: kTheme,
  }
}