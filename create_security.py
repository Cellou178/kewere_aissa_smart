import os

# ── AUTH GUARD ──
os.makedirs('lib/core/utils', exist_ok=True)

with open('lib/core/utils/auth_guard.dart', 'w', encoding='utf-8') as f:
    f.write('''import 'package:flutter/material.dart';
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
            Text('Réservé aux : \${rolesAutorises.join(', ')}',
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),
            Text('Votre rôle : \${SessionManager.role}',
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
''')

print("✅ auth_guard.dart créé !")

# ── SESSION TIMEOUT ──
with open('lib/core/utils/session_timeout.dart', 'w', encoding='utf-8') as f:
    f.write('''import 'dart:async';
import 'package:flutter/material.dart';
import '../../managers/session_manager.dart';
import '../../screens/auth/login_screen.dart';

class SessionTimeout extends StatefulWidget {
  final Widget child;
  final Duration timeout;

  const SessionTimeout({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 30),
  });

  @override
  State<SessionTimeout> createState() => _SessionTimeoutState();
}

class _SessionTimeoutState extends State<SessionTimeout> {
  Timer? _timer;
  late DateTime _lastActivity;

  @override
  void initState() {
    super.initState();
    _lastActivity = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (DateTime.now().difference(_lastActivity) >= widget.timeout) {
        _logout();
      }
    });
  }

  void _resetTimer() {
    _lastActivity = DateTime.now();
  }

  Future<void> _logout() async {
    _timer?.cancel();
    await SessionManager.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('⏱️ Session expirée. Reconnectez-vous.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating));
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetTimer,
      onPanDown: (_) => _resetTimer(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
''')

print("✅ session_timeout.dart créé !")

# ── METTRE À JOUR HOME SCREEN ──
home_path = 'lib/screens/home/home_screen.dart'
with open(home_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Ajouter imports
old_imports = "import 'package:flutter/material.dart';"
new_imports = """import 'package:flutter/material.dart';
import '../../core/utils/auth_guard.dart';
import '../../core/utils/session_timeout.dart';"""

content = content.replace(old_imports, new_imports)

# Protéger FinanceScreen
content = content.replace(
    "const FinanceScreen(),",
    """AuthGuard(
      rolesAutorises: const ['admin', 'proprietaire'],
      child: const FinanceScreen(),
    ),"""
)

# Entourer Scaffold avec SessionTimeout et AuthGuard
content = content.replace(
    "    return Scaffold(",
    """    return AuthGuard(
      child: SessionTimeout(
        timeout: const Duration(minutes: 30),
        child: Scaffold("""
)

# Fermer les widgets ajoutés
content = content.replace(
    "    );\n  }\n}",
    "    ),\n      ),\n    );\n  }\n}"
)

with open(home_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ home_screen.dart mis à jour !")
print("\n🎉 Sécurité installée avec succès !")
print("Lancez : flutter run -d chrome --web-browser-flag \"--disable-web-security\"")