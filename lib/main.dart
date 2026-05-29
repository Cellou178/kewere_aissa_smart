import 'package:flutter/material.dart';
import 'managers/session_manager.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'core/constants/app_constants.dart';
import 'services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionManager.init();
  await CacheService.init();
  runApp(const KewereApp());
}

class KewereApp extends StatelessWidget {
  const KewereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kewere Aissa Smart',
      debugShowCheckedModeBanner: false,
      theme: kTheme,
      home: SessionManager.isLoggedIn
          ? const HomeScreen()
          : const SplashScreen(),
    );
  }
}