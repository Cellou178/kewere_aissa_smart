import '../abonnement/abonnement_screen.dart';

// Dans _getDrawerPage :
case 17: return const AbonnementScreen();

// Dans le drawer, section fixée en bas avant Paramètres :
_drawerItem(17, Icons.diamond_rounded, 'Abonnement',
const Color(0xFF16A34A)),