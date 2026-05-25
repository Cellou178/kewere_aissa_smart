import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../../core/utils/auth_guard.dart';
import '../../core/utils/session_timeout.dart';
import '../../core/utils/app_transitions.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_drawer.dart';
import '../dashboard/dashboard_page.dart';
import '../cycles/cycles_screen.dart';
import '../finances/finances_screen.dart';
import '../alertes/alertes_screen.dart';
import '../profil/profil_screen.dart';
import '../notifications/notifications_screen.dart';

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
            backgroundColor: kDark,
            elevation: 0,
            toolbarHeight: 50,
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded,
                  color: Colors.white, size: 22),
              onPressed: () =>
                  _scaffoldKey.currentState?.openDrawer(),
            ),
            title: Row(children: [
              const Text('🐔', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text('Kewere Smart', style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmall ? 13 : 15,
                  fontWeight: FontWeight.w800)),
            ]),
            actions: [
              Stack(children: [
                IconButton(
                  icon: Icon(Icons.notifications_outlined,
                      color: Colors.white,
                      size: isSmall ? 20 : 22),
                  onPressed: () => Navigator.push(context,
                      AppTransitions.slideFade(
                          const NotificationsScreen())),
                ),
                if (NotificationService.nonLues > 0)
                  Positioned(top: 8, right: 8,
                      child: Container(
                          width: 14, height: 14,
                          decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle),
                          child: Center(child: Text(
                              '${NotificationService.nonLues}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800))))),
              ]),
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: SessionManager.roleColor.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(SessionManager.roleBadge,
                      style: const TextStyle(fontSize: 9)),
                  const SizedBox(width: 2),
                  Text(
                      SessionManager.role.length > 5
                          ? SessionManager.role
                          .substring(0, 5)
                          .toUpperCase()
                          : SessionManager.role.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
          ),

          // ── DRAWER ──
          drawer: const AppDrawer(),

          // ── BODY ──
          body: _pages[_currentIndex],

          // ── BOTTOM NAV ──
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -1))],
            ),
            child: SafeArea(
              child: SizedBox(
                height: isSmall ? 50 : 54,
                child: Row(children: [
                  _bottomItem(0, Icons.dashboard_rounded,
                      'Accueil', kBlue),
                  _bottomItem(1, Icons.loop_rounded,
                      'Cycles', kOrange),
                  _bottomItem(2, Icons.attach_money_rounded,
                      'Finance', kRed),
                  _bottomItem(3, Icons.notifications_rounded,
                      'Alertes', const Color(0xFFF59E0B)),
                  _bottomItem(4, Icons.person_rounded,
                      'Profil', kPurple),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomItem(int index, IconData icon,
      String label, Color color) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.08)
                : Colors.transparent,
            border: Border(top: BorderSide(
                color: isSelected ? color : Colors.transparent,
                width: 2)),
          ),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: isSelected ? 20 : 18,
                    color: isSelected
                        ? color : Colors.grey.shade400),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(
                    fontSize: 8,
                    fontWeight: isSelected
                        ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? color : Colors.grey.shade400)),
              ]),
        ),
      ),
    );
  }
}