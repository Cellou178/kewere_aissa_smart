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
    const GraphiquesScreen(),
    AuthGuard(
      rolesAutorises: const ['admin', 'proprietaire'],
      child: const FinanceScreen(),
    ),
    const MeteoScreen(),
    const AlertesScreen(),
    const ProfilScreen(),
  ];

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
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: kBlue,
              unselectedItemColor: Colors.grey.shade400,
              selectedFontSize: 10, unselectedFontSize: 9,
              backgroundColor: Colors.transparent, elevation: 0,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Accueil'),
                BottomNavigationBarItem(icon: Icon(Icons.agriculture_rounded), label: 'Fermes'),
                BottomNavigationBarItem(icon: Icon(Icons.loop_rounded), label: 'Cycles'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Graphiques'),
                BottomNavigationBarItem(icon: Icon(Icons.attach_money_rounded), label: 'Finance'),
                BottomNavigationBarItem(icon: Icon(Icons.cloud_rounded), label: 'Météo'),
                BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Alertes'),
                BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}