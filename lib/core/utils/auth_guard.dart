import 'package:flutter/material.dart';
import '../../managers/session_manager.dart';
import '../../screens/auth/login_screen.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final List<String> rolesAutorises;

  const AuthGuard({
    super.key,
    required this.child,
    this.rolesAutorises = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (!SessionManager.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false);
      });
      return const SizedBox();
    }

    if (rolesAutorises.isNotEmpty &&
        !rolesAutorises.contains(SessionManager.role)) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle),
              child: const Text('🔒', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 20),
            const Text('Accès Refusé', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text('Réservé aux : ${rolesAutorises.join(', ')}',
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),
            Text('Votre rôle : ${SessionManager.role}',
                style: const TextStyle(
                    color: Color(0xFF1B3A6B),
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        )),
      );
    }

    return child;
  }
}