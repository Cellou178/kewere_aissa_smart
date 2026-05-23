import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../../core/utils/auth_guard.dart';
import '../../core/utils/session_timeout.dart';
import '../dashboard/dashboard_page.dart';
import '../fermes/fermes_screen.dart';
import '../cycles/cycles_screen.dart';
import '../graphiques/graphiques_screen.dart';
import '../finances/finances_screen.dart';
import '../alertes/alertes_screen.dart';
import '../profil/profil_screen.dart';
import '../meteo/meteo_screen.dart';
import '../predictions/predictions_screen.dart';
import '../stocks/stocks_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    const DashboardPage(),
    const FermesScreen(),
    const CyclesScreen(),
    const StocksScreen(),
    const GraphiquesScreen(),
    AuthGuard(
      rolesAutorises: const ['admin', 'proprietaire'],
      child: const FinanceScreen(),
    ),
    const PredictionsScreen(),
    const MeteoScreen(),
    const AlertesScreen(),
    const SettingsScreen(),
    const ProfilScreen(),
    // Pages vides pour l'instant
    _emptyPage('🌍', 'Marché', 'Bientôt disponible'),
    _emptyPage('💬', 'Chat', 'Bientôt disponible'),
    _emptyPage('📊', 'Rapports', 'Bientôt disponible'),
    _emptyPage('📅', 'Agenda', 'Bientôt disponible'),
    _emptyPage('🏪', 'Vitrine', 'Bientôt disponible'),
    _emptyPage('💳', 'Paiement', 'Bientôt disponible'),
    _emptyPage('📈', 'Invest.', 'Bientôt disponible'),
    _emptyPage('🔧', 'Maint.', 'Bientôt disponible'),
    _emptyPage('⚙️', 'Gestion', 'Bientôt disponible'),
    _emptyPage('🔒', 'Sécurité', 'Bientôt disponible'),
    _emptyPage('👥', 'Accès', 'Bientôt disponible'),
  ];

  Widget _emptyPage(String emoji, String title, String subtitle) => Scaffold(
    backgroundColor: const Color(0xFFF1F5F9),
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: kBlue.withOpacity(0.1), shape: BoxShape.circle),
          child: Text(emoji, style: const TextStyle(fontSize: 48))),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
      const SizedBox(height: 8),
      Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      const SizedBox(height: 24),
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: kBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: const Text('En cours de développement',
              style: TextStyle(color: kBlue, fontWeight: FontWeight.w600, fontSize: 12))),
    ])),
  );

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      child: SessionTimeout(
        timeout: const Duration(minutes: 30),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A), elevation: 0,
            title: const Row(children: [
              Text('🐔', style: TextStyle(fontSize: 22)),
              SizedBox(width: 10),
              Text('Kewere Aissa Smart', style: TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const CircleAvatar(radius: 4, backgroundColor: Colors.greenAccent),
                  const SizedBox(width: 5),
                  Text(SessionManager.role.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ),
          body: _pages[_currentIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20, offset: const Offset(0, -4))],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
                type: BottomNavigationBarType.fixed,
                selectedItemColor: kBlue,
                unselectedItemColor: Colors.grey.shade400,
                selectedFontSize: 9, unselectedFontSize: 8,
                backgroundColor: Colors.transparent, elevation: 0,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Accueil'),
                  BottomNavigationBarItem(icon: Icon(Icons.agriculture_rounded), label: 'Fermes'),
                  BottomNavigationBarItem(icon: Icon(Icons.loop_rounded), label: 'Cycles'),
                  BottomNavigationBarItem(icon: Icon(Icons.inventory_rounded), label: 'Stock'),
                  BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Stats'),
                  BottomNavigationBarItem(icon: Icon(Icons.attach_money_rounded), label: 'Finance'),
                  BottomNavigationBarItem(icon: Icon(Icons.psychology_rounded), label: 'IA'),
                  BottomNavigationBarItem(icon: Icon(Icons.cloud_rounded), label: 'Météo'),
                  BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Alertes'),
                  BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Réglages'),
                  BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
                  BottomNavigationBarItem(icon: Icon(Icons.store_rounded), label: 'Marché'),
                  BottomNavigationBarItem(icon: Icon(Icons.chat_rounded), label: 'Chat'),
                  BottomNavigationBarItem(icon: Icon(Icons.assessment_rounded), label: 'Rapports'),
                  BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Agenda'),
                  BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'Vitrine'),
                  BottomNavigationBarItem(icon: Icon(Icons.payment_rounded), label: 'Paiement'),
                  BottomNavigationBarItem(icon: Icon(Icons.trending_up_rounded), label: 'Invest.'),
                  BottomNavigationBarItem(icon: Icon(Icons.build_rounded), label: 'Maint.'),
                  BottomNavigationBarItem(icon: Icon(Icons.manage_accounts_rounded), label: 'Gestion'),
                  BottomNavigationBarItem(icon: Icon(Icons.lock_rounded), label: 'Sécurité'),
                  BottomNavigationBarItem(icon: Icon(Icons.group_rounded), label: 'Accès'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}