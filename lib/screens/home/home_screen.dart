import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../../core/utils/auth_guard.dart';
import '../../core/utils/session_timeout.dart';
import '../../services/notification_service.dart';
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
import '../employes/employes_screen.dart';
import '../notifications/notifications_screen.dart';
import '../rapports/rapports_screen.dart';
import '../terrain/terrain_screen.dart';
import '../agenda/agenda_screen.dart';
import '../marche/marche_screen.dart';
import '../vitrine/vitrine_screen.dart';
import '../investissement/investissement_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> get _pages => [
    const DashboardPage(),
    const CyclesScreen(),
    AuthGuard(
      rolesAutorises: const ['admin', 'proprietaire'],
      child: const FinanceScreen(),
    ),
    const AlertesScreen(),
    const ProfilScreen(),
  ];

  Widget _getDrawerPage(int index) {
    switch (index) {
      case 0: return const TerrainScreen();
      case 1: return const RapportsScreen();
      case 2: return const FermesScreen();
      case 3: return const StocksScreen();
      case 4: return const AgendaScreen();
      case 5: return const EmployesScreen();
      case 6: return const SettingsScreen();
      case 7: return const MarcheScreen();
      case 8: return const GraphiquesScreen();
      case 9: return const PredictionsScreen();
      case 10: return const MeteoScreen();
      case 11: return const VitrineScreen();
      case 12: return const InvestissementScreen();
      default: return _emptyPage('Bientôt disponible',
          Icons.construction_rounded, kBlue);
    }
  }

  Widget _emptyPage(String title, IconData icon, Color color) => Scaffold(
    backgroundColor: const Color(0xFFF1F5F9),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0F172A),
      foregroundColor: Colors.white,
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
    body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 48, color: color)),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w900,
          color: Color(0xFF1E293B))),
      const SizedBox(height: 8),
      const Text('En cours de développement',
          style: TextStyle(color: Colors.grey)),
    ])),
  );

  void _navigateDrawer(int index) {
    Navigator.pop(context);
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => _getDrawerPage(index)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      child: SessionTimeout(
        timeout: const Duration(minutes: 30),
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF1F5F9),

          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A), elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: const Text('Kewere Smart', style: TextStyle(
                color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.w800)),
            actions: [
              Stack(children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen())),
                ),
                if (NotificationService.nonLues > 0)
                  Positioned(top: 8, right: 8, child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle),
                      child: Text('${NotificationService.nonLues}',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800)))),
              ]),
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const CircleAvatar(radius: 3,
                      backgroundColor: Colors.greenAccent),
                  const SizedBox(width: 4),
                  Text(SessionManager.role.toUpperCase(),
                      style: const TextStyle(color: Colors.white,
                          fontSize: 9, fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
          ),

          // ── DRAWER ──
          drawer: Drawer(
            backgroundColor: const Color(0xFF0F172A),
            child: SafeArea(child: Column(children: [
              // ── Header ──
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  Container(width: 48, height: 48,
                      decoration: BoxDecoration(
                          color: kBlue.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(14)),
                      child: const Center(
                          child: Text('🐔',
                              style: TextStyle(fontSize: 24)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(SessionManager.nom.isNotEmpty
                            ? SessionManager.nom : 'Utilisateur',
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w800, fontSize: 14)),
                        Text(SessionManager.role, style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                      ])),
                ]),
              ),
              const Divider(color: Colors.white12),

              // ── Items scrollables ──
              Expanded(child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _drawerSection('GESTION'),
                    _drawerItem(2, Icons.agriculture_rounded, 'Fermes',
                        const Color(0xFF16A34A)),
                    _drawerItem(3, Icons.inventory_rounded, 'Stocks',
                        const Color(0xFFEA580C)),
                    _drawerItem(5, Icons.people_rounded, 'Employés',
                        const Color(0xFF7C3AED)),
                    _drawerItem(0, Icons.terrain_rounded, 'Terrain',
                        const Color(0xFF16A34A)),
                    const SizedBox(height: 8),

                    _drawerSection('ANALYTICS'),
                    _drawerItem(8, Icons.bar_chart_rounded, 'Graphiques',
                        const Color(0xFF2563EB)),
                    _drawerItem(9, Icons.psychology_rounded,
                        'Prédictions IA', const Color(0xFF0891B2)),
                    _drawerItem(10, Icons.cloud_rounded, 'Météo',
                        const Color(0xFF38BDF8)),
                    const SizedBox(height: 8),

                    _drawerSection('RAPPORTS & PLANNING'),
                    _drawerItem(1, Icons.assessment_rounded, 'Rapports',
                        const Color(0xFF6366F1)),
                    _drawerItem(4, Icons.calendar_month_rounded, 'Agenda',
                        const Color(0xFF0891B2)),
                    const SizedBox(height: 8),

                    _drawerSection('MARCHÉ & VITRINE'),
                    _drawerItem(7, Icons.store_rounded,
                        'Marché Afrique de l\'Ouest',
                        const Color(0xFFD97706)),
                    _drawerItem(11, Icons.storefront_rounded, 'Ma Vitrine',
                        const Color(0xFF16A34A)),_drawerSection('FINANCE & INVEST.'),
                    _drawerItem(12, Icons.trending_up_rounded, 'Investissement',
                        const Color(0xFF16A34A)),

                  ])),

              // ── Fixés en bas ──
              const Divider(color: Colors.white12),
              _drawerItem(6, Icons.settings_rounded, 'Paramètres',
                  const Color(0xFF6B7280)),
              ListTile(
                dense: true,
                leading: Container(padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.logout_rounded,
                        color: Colors.redAccent, size: 18)),
                title: const Text('Déconnexion', style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600, fontSize: 13)),
                onTap: () async {
                  await SessionManager.clear();
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/', (route) => false);
                },
              ),
              const SizedBox(height: 8),
            ])),
          ),

          body: _pages[_currentIndex],

          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              child: SizedBox(
                height: 56,
                child: Row(children: [
                  _bottomItem(0, Icons.dashboard_rounded, 'Accueil', kBlue),
                  _bottomItem(1, Icons.loop_rounded, 'Cycles',
                      const Color(0xFFEA580C)),
                  _bottomItem(2, Icons.attach_money_rounded, 'Finance',
                      const Color(0xFFDC2626)),
                  _bottomItem(3, Icons.notifications_rounded, 'Alertes',
                      const Color(0xFFF59E0B)),
                  _bottomItem(4, Icons.person_rounded, 'Profil',
                      const Color(0xFF7C3AED)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomItem(int index, IconData icon, String label, Color color) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.08) : Colors.transparent,
            border: Border(top: BorderSide(
                color: isSelected ? color : Colors.transparent, width: 2)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22,
                    color: isSelected ? color : Colors.grey.shade400),
                const SizedBox(height: 3),
                Text(label, style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected ? color : Colors.grey.shade400)),
              ]),
        ),
      ),
    );
  }

  Widget _drawerSection(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(title, style: const TextStyle(
          color: Colors.white38, fontSize: 10,
          fontWeight: FontWeight.w700, letterSpacing: 1)));

  Widget _drawerItem(int index, IconData icon, String label, Color color) =>
      ListTile(
        dense: true,
        leading: Container(padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18)),
        title: Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 13,
            fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.white24, size: 12),
        onTap: () => _navigateDrawer(index),
      );
}