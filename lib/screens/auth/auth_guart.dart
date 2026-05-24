import 'package:flutter/material.dart';
import '../../managers/session_manager.dart';
import '../../screens/auth/login_screen.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final List<String>? rolesAutorises;

  const AuthGuard({
    super.key,
    required this.child,
    this.rolesAutorises,
  });

  @override
  Widget build(BuildContext context) {
    // Non connecté → rediriger vers login
    if (!SessionManager.isLoggedIn) {
      return const LoginScreen();
    }

    // Vérifier le rôle si spécifié
    if (rolesAutorises != null && rolesAutorises!.isNotEmpty) {
      final role = SessionManager.role.toLowerCase();
      final autorise = rolesAutorises!
          .map((r) => r.toLowerCase())
          .contains(role);

      if (!autorise) {
        return _accessRefuse(context);
      }
    }

    return child;
  }

  Widget _accessRefuse(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F5F9),
    body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle),
          child: const Icon(Icons.lock_rounded,
              color: Colors.red, size: 48)),
      const SizedBox(height: 20),
      const Text('Accès Refusé', style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w900,
          color: Color(0xFF1E293B))),
      const SizedBox(height: 8),
      const Text('Vous n\'avez pas les permissions\npour accéder à cette page',
          style: TextStyle(color: Colors.grey, fontSize: 14),
          textAlign: TextAlign.center),
      const SizedBox(height: 24),
      ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Retour',
              style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B3A6B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              elevation: 0)),
    ])),
  );
}