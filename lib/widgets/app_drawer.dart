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

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});
  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final Map<String, bool> _expanded = {
    'gestion': true,
    'analytics': false,
    'planning': false,
    'marche': false,
    'finance': false,
  };

  void _navigate(Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, AppTransitions.slideFade(screen));
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return SizedBox(
      width: sw * 0.20,
      child: Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: SafeArea(child: Column(children: [

          // ── HEADER ──
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05)),
            child: Row(children: [
              Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                      color: kBlue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Center(
                      child: Text('🐔',
                          style: TextStyle(fontSize: 18)))),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        SessionManager.nom.isNotEmpty
                            ? SessionManager.nom : 'Utilisateur',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Row(children: [
                      Text(SessionManager.roleBadge,
                          style: const TextStyle(fontSize: 10)),
                      const SizedBox(width: 3),
                      Text(SessionManager.role,
                          style: TextStyle(
                              color: SessionManager.roleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ])),
            ]),
          ),
          const Divider(color: Colors.white12, height: 1),

          // ── MENU ──
          Expanded(child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [

                // GESTION
                _collapsibleSection(
                  key: 'gestion',
                  title: 'GESTION',
                  icon: Icons.business_center_rounded,
                  color: kGreen,
                  items: [
                    _item(Icons.agriculture_rounded, 'Fermes',
                        const Color(0xFF16A34A),
                        () => _navigate(const FermesScreen())),
                    _item(Icons.inventory_rounded, 'Stocks',
                        const Color(0xFFEA580C),
                        () => _navigate(const StocksScreen())),
                    _item(Icons.people_rounded, 'Employés',
                        const Color(0xFF7C3AED),
                        () => _navigate(const EmployesScreen())),
                    _item(Icons.terrain_rounded, 'Terrain',
                        const Color(0xFF16A34A),
                        () => _navigate(const TerrainScreen())),
                  ],
                ),

                // ANALYTICS
                _collapsibleSection(
                  key: 'analytics',
                  title: 'ANALYTICS & IA',
                  icon: Icons.analytics_rounded,
                  color: kBlue,
                  items: [
                    _item(Icons.bar_chart_rounded, 'Graphiques',
                        const Color(0xFF2563EB),
                        () => _navigate(const GraphiquesScreen())),
                    _item(Icons.psychology_rounded, 'Prédictions IA',
                        const Color(0xFF0891B2),
                        () => _navigate(const PredictionsScreen())),
                    _item(Icons.cloud_rounded, 'Météo',
                        const Color(0xFF38BDF8),
                        () => _navigate(const MeteoScreen())),
                    _item(Icons.chat_rounded, 'Chat IA',
                        const Color(0xFF4C1D95),
                        () => _navigate(const ChatScreen())),
                    _item(Icons.analytics_rounded, 'Statistiques',
                        const Color(0xFF2563EB),
                        () => _navigate(const StatsScreen())),
                  ],
                ),

                // RAPPORTS & PLANNING
                _collapsibleSection(
                  key: 'planning',
                  title: 'RAPPORTS & PLANNING',
                  icon: Icons.calendar_month_rounded,
                  color: kIndigo,
                  items: [
                    _item(Icons.assessment_rounded, 'Rapports',
                        const Color(0xFF6366F1),
                        () => _navigate(const RapportsScreen())),
                    _item(Icons.calendar_month_rounded, 'Agenda',
                        const Color(0xFF0891B2),
                        () => _navigate(const AgendaScreen())),
                  ],
                ),

                // MARCHÉ & VITRINE
                _collapsibleSection(
                  key: 'marche',
                  title: 'MARCHÉ & VITRINE',
                  icon: Icons.store_rounded,
                  color: kOrange,
                  items: [
                    _item(Icons.store_rounded, 'Marché AOF',
                        const Color(0xFFD97706),
                        () => _navigate(const MarcheScreen())),
                    _item(Icons.storefront_rounded, 'Ma Vitrine',
                        const Color(0xFF16A34A),
                        () => _navigate(const VitrineScreen())),
                  ],
                ),

                // FINANCE & INVEST
                _collapsibleSection(
                  key: 'finance',
                  title: 'FINANCE & INVEST.',
                  icon: Icons.trending_up_rounded,
                  color: kGreen,
                  items: [
                    _item(Icons.trending_up_rounded, 'Investissement',
                        const Color(0xFF16A34A),
                        () => _navigate(const InvestissementScreen())),
                    _item(Icons.build_rounded, 'Maintenance',
                        const Color(0xFF6B7280),
                        () => _navigate(const MaintenanceScreen())),
                    _item(Icons.security_rounded, 'Accès & Rôles',
                        const Color(0xFFDC2626),
                        () => _navigate(const AccesScreen())),
                    _item(Icons.diamond_rounded, 'Abonnement',
                        const Color(0xFF059669),
                        () => _navigate(const AbonnementScreen())),
                  ],
                ),

                const SizedBox(height: 4),
              ])),

          // ── BAS FIXE ──
          const Divider(color: Colors.white12, height: 1),
          _item(Icons.settings_rounded, 'Paramètres',
              const Color(0xFF6B7280),
              () => _navigate(const SettingsScreen())),
          ListTile(
            dense: true,
            visualDensity: const VisualDensity(vertical: -4),
            minLeadingWidth: 0,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 0),
            leading: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(7)),
                child: const Icon(Icons.logout_rounded,
                    color: Colors.redAccent, size: 14)),
            title: const Text('Déconnexion',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 11)),
            onTap: () async {
              await SessionManager.clear();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/', (route) => false);
            },
          ),
          const SizedBox(height: 6),
        ])),
      ),
    );
  }

  Widget _collapsibleSection({
    required String key,
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> items,
  }) {
    final isOpen = _expanded[key] ?? false;
    return Column(children: [
      InkWell(
        onTap: () => setState(() => _expanded[key] = !isOpen),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: isOpen
                  ? color.withOpacity(0.08)
                  : Colors.transparent),
          child: Row(children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text(title,
                style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8))),
            Icon(
                isOpen ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: color, size: 16),
          ]),
        ),
      ),
      if (isOpen) ...items,
    ]);
  }

  Widget _item(IconData icon, String label,
      Color color, VoidCallback onTap) =>
      ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -4),
        minLeadingWidth: 0,
        contentPadding: const EdgeInsets.fromLTRB(
            24, 0, 14, 0),
        leading: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, color: color, size: 13)),
        title: Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 11,
            fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.white12, size: 9),
        onTap: onTap,
      );
}