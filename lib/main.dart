import 'package:flutter/material.dart';
import 'managers/session_manager.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/dashboard/dashboard_page.dart';
import 'core/constants/app_constants.dart';

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
        // Card theme
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        // AppBar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B3A6B),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        // Button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B3A6B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: SessionManager.isLoggedIn
          ? const DashboardPage()
          : const SplashScreen(),
    );
  }
}