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
import '../maintenance/maintenance_screen.dart';
import '../acces/acces_screen.dart';
//import '../stats/stats_screen.dart';
import '../chat/chat_screen.dart';

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
      rolesAutorises: const ['admin', 'proprietaire', 'comptable'],
      child: const FinanceScreen(),
    ),
    const AlertesScreen(),
    const ProfilScreen(),
  ];

  Widget _getDrawerPage(int index) {
    switch (index) {
      case 0: return const FermesScreen();
      case 1: return const StocksScreen();
      case 2: return const EmployesScreen();
      case 3: return const TerrainScreen();
      case 4: return const GraphiquesScreen();
      case 5: return const PredictionsScreen();
      case 6: return const MeteoScreen();
      case 7: return const ChatScreen();
      case 8: return const RapportsScreen();
      case 9: return const AgendaScreen();
      case 10: return const MarcheScreen();
      case 11: return const VitrineScreen();
      case 12: return const InvestissementScreen();
      case 13: return const MaintenanceScreen();
      case 14: return const AccesScreen();
      case 15: return _emptyPage('Statistiques', Icons.analytics_rounded, kBlue);
      case 16: return const SettingsScreen();
      default: return _emptyPage('Bientôt disponible',
          Icons.construction_rounded, kBlue);
    }
  }

  Widget _emptyPage(String title, IconData icon, Color color) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(
      backgroundColor: kDark,
      foregroundColor: Colors.white,
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
    body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 40, color: color)),
      const SizedBox(height: 14),
      Text(title, style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w900,
          color: Color(0xFF1E293B))),
      const SizedBox(height: 6),
      const Text('En cours de développement',
          style: TextStyle(color: Colors.grey, fontSize: 13)),
    ])),
  );

  void _navigateDrawer(int index) {
    Navigator.pop(context);
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => _getDrawerPage(index)));
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final isSmall = sw < 400;

    return AuthGuard(
      child: SessionTimeout(
        timeout: const Duration(minutes: 30),
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: kBg,

          // ── APP BAR ──
          appBar: AppBar(
            backgroundColor: kDark, elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded,
                  color: Colors.white, size: 22),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: Row(children: [
              const Text('🐔', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              const Text('Kewere Smart', style: TextStyle(
                  color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.w800)),
            ]),
            actions: [
              // Notifications badge
              Stack(children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 22),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) =>
                      const NotificationsScreen())),
                ),
                if (NotificationService.nonLues > 0)
                  Positioned(top: 8, right: 8, child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle),
                      child: Center(child: Text(
                          '${NotificationService.nonLues}',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800))))),
              ]),
              // Badge rôle compact
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: SessionManager.roleColor.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(SessionManager.roleBadge,
                      style: const TextStyle(fontSize: 10)),
                  const SizedBox(width: 3),
                  Text(
                      SessionManager.role.length > 6
                          ? SessionManager.role.substring(0, 6).toUpperCase()
                          : SessionManager.role.toUpperCase(),
                      style: const TextStyle(color: Colors.white,
                          fontSize: 8, fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
          ),

          // ── DRAWER ──
          drawer: SizedBox(
            // ✅ Fix #1 — Drawer 75% largeur écran
            width: sw * 0.75,
            child: Drawer(
              backgroundColor: kDark,
              child: SafeArea(child: Column(children: [
                // Header compact
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04)),
                  child: Row(children: [
                    Container(width: 40, height: 40,
                        decoration: BoxDecoration(
                            color: kBlue.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Center(child: Text('🐔',
                            style: TextStyle(fontSize: 20)))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              SessionManager.nom.isNotEmpty
                                  ? SessionManager.nom : 'Utilisateur',
                              style: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w700, fontSize: 13),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          Row(children: [
                            Text(SessionManager.roleBadge,
                                style: const TextStyle(fontSize: 10)),
                            const SizedBox(width: 3),
                            Text(SessionManager.role, style: TextStyle(
                                color: SessionManager.roleColor,
                                fontSize: 10, fontWeight: FontWeight.w600)),
                          ]),
                        ])),
                  ]),
                ),
                const Divider(color: Colors.white12, height: 1),

                // ── Items scrollables ──
                Expanded(child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    children: [

                      // GESTION
                      _drawerSection('GESTION'),
                      _drawerItem(0, Icons.agriculture_rounded, 'Fermes',
                          const Color(0xFF16A34A)),
                      _drawerItem(1, Icons.inventory_rounded, 'Stocks',
                          const Color(0xFFEA580C)),
                      _drawerItem(2, Icons.people_rounded, 'Employés',
                          const Color(0xFF7C3AED)),
                      _drawerItem(3, Icons.terrain_rounded, 'Terrain',
                          const Color(0xFF16A34A)),

                      // ANALYTICS
                      _drawerSection('ANALYTICS'),
                      _drawerItem(4, Icons.bar_chart_rounded, 'Graphiques',
                          const Color(0xFF2563EB)),
                      _drawerItem(5, Icons.psychology_rounded,
                          'Prédictions IA', const Color(0xFF0891B2)),
                      _drawerItem(6, Icons.cloud_rounded, 'Météo',
                          const Color(0xFF38BDF8)),
                      _drawerItem(7, Icons.chat_rounded, 'Chat IA',
                          const Color(0xFF4C1D95)),
                      _drawerItem(15, Icons.analytics_rounded,
                          'Statistiques', const Color(0xFF2563EB)),

                      // RAPPORTS
                      _drawerSection('RAPPORTS & PLANNING'),
                      _drawerItem(8, Icons.assessment_rounded, 'Rapports',
                          const Color(0xFF6366F1)),
                      _drawerItem(9, Icons.calendar_month_rounded,
                          'Agenda', const Color(0xFF0891B2)),

                      // MARCHÉ
                      _drawerSection('MARCHÉ & VITRINE'),
                      _drawerItem(10, Icons.store_rounded,
                          'Marché AOF', const Color(0xFFD97706)),
                      _drawerItem(11, Icons.storefront_rounded,
                          'Ma Vitrine', const Color(0xFF16A34A)),

                      // FINANCE
                      _drawerSection('FINANCE & INVEST.'),
                      _drawerItem(12, Icons.trending_up_rounded,
                          'Investissement', const Color(0xFF16A34A)),
                      _drawerItem(13, Icons.build_rounded,
                          'Maintenance', const Color(0xFF6B7280)),
                      _drawerItem(14, Icons.security_rounded,
                          'Accès & Rôles', const Color(0xFFDC2626)),
                    ])),

                // ── Fixés en bas ──
                const Divider(color: Colors.white12, height: 1),
                _drawerItem(16, Icons.settings_rounded, 'Paramètres',
                    const Color(0xFF6B7280)),
                ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  leading: Container(padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(7)),
                      child: const Icon(Icons.logout_rounded,
                          color: Colors.redAccent, size: 16)),
                  title: const Text('Déconnexion', style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600, fontSize: 12)),
                  onTap: () async {
                    await SessionManager.clear();
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/', (route) => false);
                  },
                ),
                const SizedBox(height: 6),
              ])),
            ),
          ),

          body: _pages[_currentIndex],

          // ── BOTTOM NAV — compact ──
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              child: SizedBox(
                // ✅ Fix #4 — hauteur réduite
                height: isSmall ? 52 : 56,
                child: Row(children: [
                  _bottomItem(0, Icons.dashboard_rounded,
                      'Accueil', kBlue),
                  _bottomItem(1, Icons.loop_rounded, 'Cycles',
                      kOrange),
                  _bottomItem(2, Icons.attach_money_rounded,
                      'Finance', kRed),
                  _bottomItem(3, Icons.notifications_rounded,
                      'Alertes', const Color(0xFFF59E0B)),
                  _bottomItem(4, Icons.person_rounded, 'Profil',
                      kPurple),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomItem(int index, IconData icon, String label,
      Color color) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.08) : Colors.transparent,
            border: Border(top: BorderSide(
                color: isSelected ? color : Colors.transparent,
                width: 2)),
          ),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: isSelected ? 22 : 20,
                color: isSelected ? color : Colors.grey.shade400),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected
                    ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? color : Colors.grey.shade400)),
          ]),
        ),
      ),
    );
  }

  Widget _drawerSection(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 3),
      child: Text(title, style: const TextStyle(
          color: Colors.white24, fontSize: 9,
          fontWeight: FontWeight.w700, letterSpacing: 1.2)));

  Widget _drawerItem(int index, IconData icon, String label,
      Color color) =>
      ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        leading: Container(padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, color: color, size: 16)),
        title: Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 12,
            fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.white12, size: 10),
        onTap: () => _navigateDrawer(index),
      );
}