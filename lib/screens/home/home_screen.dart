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

  static const List<Map<String, dynamic>> _tabs = [
    {'label': 'Accueil',  'icon': Icons.dashboard_rounded,       'color': 0xFF1B3A6B},
    {'label': 'Terrain',  'icon': Icons.terrain_rounded,         'color': 0xFF16A34A},
    {'label': 'Cycles',   'icon': Icons.loop_rounded,            'color': 0xFFEA580C},
    {'label': 'Opérat.',  'icon': Icons.assignment_rounded,      'color': 0xFF7C3AED},
    {'label': 'Finance',  'icon': Icons.attach_money_rounded,    'color': 0xFFDC2626},
    {'label': 'IA',       'icon': Icons.psychology_rounded,      'color': 0xFF0891B2},
    {'label': 'Marché',   'icon': Icons.store_rounded,           'color': 0xFFD97706},
    {'label': 'Météo',    'icon': Icons.cloud_rounded,           'color': 0xFF38BDF8},
    {'label': 'Chat',     'icon': Icons.chat_rounded,            'color': 0xFF059669},
    {'label': 'Rapports', 'icon': Icons.assessment_rounded,      'color': 0xFF6366F1},
    {'label': 'Ferme',    'icon': Icons.agriculture_rounded,     'color': 0xFF16A34A},
    {'label': 'Stats',    'icon': Icons.bar_chart_rounded,       'color': 0xFF2563EB},
    {'label': 'Réglages', 'icon': Icons.settings_rounded,        'color': 0xFF6B7280},
    {'label': 'Sécurité', 'icon': Icons.lock_rounded,            'color': 0xFFDC2626},
    {'label': 'Accès',    'icon': Icons.group_rounded,           'color': 0xFF7C3AED},
    {'label': 'Alertes',  'icon': Icons.notifications_rounded,   'color': 0xFFF59E0B},
    {'label': 'Stock',    'icon': Icons.inventory_rounded,       'color': 0xFFEA580C},
    {'label': 'Agenda',   'icon': Icons.calendar_month_rounded,  'color': 0xFF0891B2},
    {'label': 'Vitrine',  'icon': Icons.storefront_rounded,      'color': 0xFFD97706},
    {'label': 'Paiement', 'icon': Icons.payment_rounded,         'color': 0xFF059669},
    {'label': 'Invest.',  'icon': Icons.trending_up_rounded,     'color': 0xFF16A34A},
    {'label': 'Maint.',   'icon': Icons.build_rounded,           'color': 0xFF6B7280},
    {'label': 'Profil',   'icon': Icons.person_rounded,          'color': 0xFF1B3A6B},
    {'label': 'Gestion',  'icon': Icons.manage_accounts_rounded, 'color': 0xFF7C3AED},
  ];

  List<Widget> get _pages => [
    const DashboardPage(),
    _emptyPage('Terrain',    Icons.terrain_rounded,          const Color(0xFF16A34A)),
    const CyclesScreen(),
    _emptyPage('Opérations', Icons.assignment_rounded,       const Color(0xFF7C3AED)),
    AuthGuard(rolesAutorises: const ['admin','proprietaire'], child: const FinanceScreen()),
    const PredictionsScreen(),
    _emptyPage('Marché',     Icons.store_rounded,            const Color(0xFFD97706)),
    const MeteoScreen(),
    _emptyPage('Chat',       Icons.chat_rounded,             const Color(0xFF059669)),
    _emptyPage('Rapports',   Icons.assessment_rounded,       const Color(0xFF6366F1)),
    const FermesScreen(),
    const GraphiquesScreen(),
    const SettingsScreen(),
    _emptyPage('Sécurité',   Icons.lock_rounded,             const Color(0xFFDC2626)),
    _emptyPage('Accès',      Icons.group_rounded,            const Color(0xFF7C3AED)),
    const AlertesScreen(),
    const StocksScreen(),
    _emptyPage('Agenda',     Icons.calendar_month_rounded,   const Color(0xFF0891B2)),
    _emptyPage('Vitrine',    Icons.storefront_rounded,       const Color(0xFFD97706)),
    _emptyPage('Paiement',   Icons.payment_rounded,          const Color(0xFF059669)),
    _emptyPage('Invest.',    Icons.trending_up_rounded,      const Color(0xFF16A34A)),
    _emptyPage('Maint.',     Icons.build_rounded,            const Color(0xFF6B7280)),
    const ProfilScreen(),
    _emptyPage('Gestion',    Icons.manage_accounts_rounded,  const Color(0xFF7C3AED)),
  ];

  Widget _emptyPage(String title, IconData icon, Color color) => Scaffold(
    backgroundColor: const Color(0xFFF1F5F9),
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 48, color: color)),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
      const SizedBox(height: 8),
      const Text('Bientôt disponible', style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 24),
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text('En cours de développement',
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12))),
    ])),
  );

  Widget _navRow(List<Map<String, dynamic>> tabs, int startIndex) {
    return SizedBox(
      height: 48,
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final index = startIndex + e.key;
          final tab = e.value;
          final isSelected = _currentIndex == index;
          final color = Color(tab['color'] as int);
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
                  border: isSelected
                      ? Border(bottom: BorderSide(color: color, width: 2))
                      : null,
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(
                    tab['icon'] as IconData,
                    size: 18,
                    color: isSelected ? color : const Color(0xFFB0B7C3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tab['label'] as String,
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
                      color: isSelected ? color : const Color(0xFFB0B7C3),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
              ),
            ),
          );
        }).toList(),
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
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20, offset: const Offset(0, -4))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _navRow(_tabs.sublist(0, 8), 0),
              const Divider(height: 0.5, color: Color(0xFFE5E7EB)),
              _navRow(_tabs.sublist(8, 16), 8),
              const Divider(height: 0.5, color: Color(0xFFE5E7EB)),
              _navRow(_tabs.sublist(16, 24), 16),
            ]),
          ),
        ),
      ),
    );
  }
}