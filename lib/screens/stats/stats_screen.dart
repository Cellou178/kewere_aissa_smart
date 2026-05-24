import '../stats/stats_screen.dart';

// Dans _getDrawerPage :
case 15: return const StatsScreen();

// Dans le drawer section ANALYTICS :
_drawerItem(15, Icons.analytics_rounded, 'Statistiques globales',
const Color(0xFF2563EB)),