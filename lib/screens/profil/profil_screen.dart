import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../auth/login_screen.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        child: Column(children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Column(children: [
              // Avatar
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kBlue, kBlueLight]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: kBlue.withOpacity(0.4),
                        blurRadius: 16, offset: const Offset(0, 6))]),
                child: Center(child: Text(
                    SessionManager.nom.isNotEmpty
                        ? SessionManager.nom.substring(0, 1).toUpperCase()
                        : 'U',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 32, fontWeight: FontWeight.w900))),
              ),
              const SizedBox(height: 12),
              Text(SessionManager.nom.isNotEmpty ? SessionManager.nom : 'Utilisateur',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 4),
              Text(SessionManager.email, style: const TextStyle(
                  color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 14),
                  const SizedBox(width: 6),
                  Text(SessionManager.role.toUpperCase(),
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w700, fontSize: 12)),
                ]),
              ),
            ]),
          ),

          Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            // Infos compte
            _section('👤 Informations', [
              _menuItem(Icons.person_rounded, 'Nom', SessionManager.nom, kBlue),
              _menuItem(Icons.email_rounded, 'Email', SessionManager.email, kBlue),
              _menuItem(Icons.badge_rounded, 'Rôle', SessionManager.role, kPurple),
            ]),
            const SizedBox(height: 16),

            // App info
            _section('ℹ️ Application', [
              _menuItem(Icons.api_rounded, 'Backend', 'kewere-aissa-smart.onrender.com', kGreen),
              _menuItem(Icons.phone_android_rounded, 'Version', '1.0.0', Colors.grey),
              _menuItem(Icons.security_rounded, 'Sécurité', 'Session active', kBlue),
            ]),
            const SizedBox(height: 16),

            // Déconnexion
            SizedBox(width: double.infinity,
                child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Déconnexion'),
                            content: const Text('Voulez-vous vous déconnecter ?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Annuler')),
                              TextButton(onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Déconnexion',
                                      style: TextStyle(color: Colors.red))),
                            ],
                          ));
                      if (confirm == true) {
                        await SessionManager.clear();
                        Navigator.pushAndRemoveUntil(context,
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                                (route) => false);
                      }
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Se déconnecter',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                        side: BorderSide(color: Colors.red.shade200)))),
          ])),
        ]),
      ),
    );
  }

  static Widget _section(String title, List<Widget> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: Colors.grey, letterSpacing: 0.5)),
    const SizedBox(height: 8),
    Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
        child: Column(children: items)),
  ]);

  static Widget _menuItem(IconData icon, String title, String value, Color color) =>
      ListTile(
        dense: true,
        leading: Container(padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 16)),
        title: Text(title, style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
        subtitle: Text(value, style: TextStyle(
            color: Colors.grey.shade500, fontSize: 11)),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.grey.shade300, size: 12),
      );
}
