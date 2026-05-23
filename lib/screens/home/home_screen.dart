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
    _emptyPage('🌍', 'Marché'),
    _emptyPage('💬', 'Chat'),
    _emptyPage('📊', 'Rapports'),
    _emptyPage('📅', 'Agenda'),
    _emptyPage('🏪', 'Vitrine'),
    _emptyPage('💳', 'Paiement'),
    _emptyPage('📈', 'Invest.'),
    _emptyPage('🔧', 'Maint.'),
    _emptyPage('⚙️', 'Gestion'),
    _emptyPage('🔒', 'Sécurité'),
    _emptyPage('👥', 'Accès'),
  ];

  Widget _emptyPage(String emoji, String title) => Scaffold(
    backgroundColor: const Color(0xFFF1F5F9),
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: kBlue.withOpacity(0.1), shape: BoxShape.circle),
          child: Text(emoji, style: const TextStyle(fontSize: 48))),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
      const SizedBox(height: 8),
      const Text('Bientôt disponible', style: TextStyle(color: Colors.grey, fontSize: 14)),
      const SizedBox(height: 24),
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: kBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: const Text('En cours de développement',
              style: TextStyle(color: kBlue, fontWeight: FontWeight.w600, fontSize: 12))),
    ])),
  );

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        width: 70,
        color: Colors.transparent,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon,
              color: isSelected ? kBlue : Colors.grey.shade400,
              size: 22),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? kBlue : Colors.grey.shade400)),
          if (isSelected)
            Container(margin: const EdgeInsets.only(top: 3),
                width: 20, height: 3,
                decoration: BoxDecoration(
                    color: kBlue, borderRadius: BorderRadius.circular(2))),
        ]),
      ),
    );
  }

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
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20, offset: const Offset(0, -4))],
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _navItem(0, Icons.dashboard_rounded, 'Accueil'),
                _navItem(1, Icons.agriculture_rounded, 'Fermes'),
                _navItem(2, Icons.loop_rounded, 'Cycles'),
                _navItem(3, Icons.inventory_rounded, 'Stock'),
                _navItem(4, Icons.bar_chart_rounded, 'Stats'),
                _navItem(5, Icons.attach_money_rounded, 'Finance'),
                _navItem(6, Icons.psychology_rounded, 'IA'),
                _navItem(7, Icons.cloud_rounded, 'Météo'),
                _navItem(8, Icons.notifications_rounded, 'Alertes'),
                _navItem(9, Icons.settings_rounded, 'Réglages'),
                _navItem(10, Icons.person_rounded, 'Profil'),
                _navItem(11, Icons.store_rounded, 'Marché'),
                _navItem(12, Icons.chat_rounded, 'Chat'),
                _navItem(13, Icons.assessment_rounded, 'Rapports'),
                _navItem(14, Icons.calendar_month_rounded, 'Agenda'),
                _navItem(15, Icons.storefront_rounded, 'Vitrine'),
                _navItem(16, Icons.payment_rounded, 'Paiement'),
                _navItem(17, Icons.trending_up_rounded, 'Invest.'),
                _navItem(18, Icons.build_rounded, 'Maint.'),
                _navItem(19, Icons.manage_accounts_rounded, 'Gestion'),
                _navItem(20, Icons.lock_rounded, 'Sécurité'),
                _navItem(21, Icons.group_rounded, 'Accès'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}