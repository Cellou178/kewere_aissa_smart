import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../managers/session_manager.dart';
import '../core/utils/app_transitions.dart';
import '../screens/fermes/fermes_screen.dart';
import '../screens/stocks/stocks_screen.dart';
import '../screens/employes/employes_screen.dart';
import '../screens/terrain/terrain_screen.dart';
import '../screens/graphiques/graphiques_screen.dart';
import '../screens/predictions/predictions_screen.dart';
import '../screens/meteo/meteo_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../screens/rapports/rapports_screen.dart';
import '../screens/agenda/agenda_screen.dart';
import '../screens/marche/marche_screen.dart';
import '../screens/vitrine/vitrine_screen.dart';
import '../screens/investissement/investissement_screen.dart';
import '../screens/maintenance/maintenance_screen.dart';
import '../screens/acces/acces_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/abonnement/abonnement_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Widget _getPage(int index, BuildContext context) {
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
      case 15: return const StatsScreen();
      case 16: return const SettingsScreen();
      case 17: return const AbonnementScreen();
      default: return _emptyPage('Bientôt disponible');
    }
  }

  Widget _emptyPage(String title) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(
      backgroundColor: kDark,
      foregroundColor: Colors.white,
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
    body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction_rounded,
              size: 40, color: kBlue),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('En cours de développement',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ])),
  );

  void _navigate(BuildContext context, int index) {
    Navigator.pop(context);
    Navigator.push(context,
        AppTransitions.slideFade(_getPage(index, context)));
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return SizedBox(
      width: sw * 0.72,
      child: Drawer(
        backgroundColor: kDark,
        child: SafeArea(child: Column(children: [

          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04)),
            child: Row(children: [
              Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                      color: kBlue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Center(
                      child: Text('🐔',
                          style: TextStyle(fontSize: 17)))),
              const SizedBox(width: 8),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        SessionManager.nom.isNotEmpty
                            ? SessionManager.nom : 'Utilisateur',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Row(children: [
                      Text(SessionManager.roleBadge,
                          style: const TextStyle(fontSize: 9)),
                      const SizedBox(width: 2),
                      Text(SessionManager.role,
                          style: TextStyle(
                              color: SessionManager.roleColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ])),
            ]),
          ),
          const Divider(color: Colors.white12, height: 1),

          // ── Menu items ──
          Expanded(child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 2),
              children: [
                _section('GESTION'),
                _item(context, 0, Icons.agriculture_rounded,
                    'Fermes', const Color(0xFF16A34A)),
                _item(context, 1, Icons.inventory_rounded,
                    'Stocks', const Color(0xFFEA580C)),
                _item(context, 2, Icons.people_rounded,
                    'Employés', const Color(0xFF7C3AED)),
                _item(context, 3, Icons.terrain_rounded,
                    'Terrain', const Color(0xFF16A34A)),

                _section('ANALYTICS'),
                _item(context, 4, Icons.bar_chart_rounded,
                    'Graphiques', const Color(0xFF2563EB)),
                _item(context, 5, Icons.psychology_rounded,
                    'Prédictions IA', const Color(0xFF0891B2)),
                _item(context, 6, Icons.cloud_rounded,
                    'Météo', const Color(0xFF38BDF8)),
                _item(context, 7, Icons.chat_rounded,
                    'Chat IA', const Color(0xFF4C1D95)),
                _item(context, 15, Icons.analytics_rounded,
                    'Statistiques', const Color(0xFF2563EB)),

                _section('RAPPORTS & PLANNING'),
                _item(context, 8, Icons.assessment_rounded,
                    'Rapports', const Color(0xFF6366F1)),
                _item(context, 9, Icons.calendar_month_rounded,
                    'Agenda', const Color(0xFF0891B2)),

                _section('MARCHÉ & VITRINE'),
                _item(context, 10, Icons.store_rounded,
                    'Marché AOF', const Color(0xFFD97706)),
                _item(context, 11, Icons.storefront_rounded,
                    'Ma Vitrine', const Color(0xFF16A34A)),

                _section('FINANCE & INVEST.'),
                _item(context, 12, Icons.trending_up_rounded,
                    'Investissement', const Color(0xFF16A34A)),
                _item(context, 13, Icons.build_rounded,
                    'Maintenance', const Color(0xFF6B7280)),
                _item(context, 14, Icons.security_rounded,
                    'Accès & Rôles', const Color(0xFFDC2626)),
                _item(context, 17, Icons.diamond_rounded,
                    'Abonnement', const Color(0xFF059669)),
                const SizedBox(height: 4),
              ])),

          // ── Bas fixe ──
          const Divider(color: Colors.white12, height: 1),
          _item(context, 16, Icons.settings_rounded,
              'Paramètres', const Color(0xFF6B7280)),
          ListTile(
            dense: true,
            visualDensity: const VisualDensity(vertical: -4),
            minLeadingWidth: 0,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 0),
            leading: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.logout_rounded,
                    color: Colors.redAccent, size: 13)),
            title: const Text('Déconnexion',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 10)),
            onTap: () async {
              await SessionManager.clear();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/', (route) => false);
            },
          ),
          const SizedBox(height: 4),
        ])),
      ),
    );
  }

  Widget _section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Text(title, style: const TextStyle(
          color: Colors.white24, fontSize: 7,
          fontWeight: FontWeight.w700, letterSpacing: 0.8)));

  Widget _item(BuildContext context, int index,
      IconData icon, String label, Color color) =>
      ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -4),
        minLeadingWidth: 0,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 0),
        leading: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, color: color, size: 13)),
        title: Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 10,
            fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.white12, size: 8),
        onTap: () => _navigate(context, index),
      );
}