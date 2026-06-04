import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic> _stats = {};
  List _entreprises = [];
  List _parametres = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getAdminStats(),
      ApiService.getAdminEntreprises(),
      ApiService.getAdminParametres(),
    ]);
    setState(() {
      _stats = results[0] as Map<String, dynamic>;
      _entreprises = results[1] as List;
      _parametres = results[2] as List;
      _loading = false;
    });
  }

  Color _planColor(String plan) {
    switch (plan) {
      case 'enterprise': return const Color(0xFF7C3AED);
      case 'pro': return kBlue;
      default: return Colors.grey;
    }
  }

  Color _statutColor(String s) {
    switch (s) {
      case 'suspendu': return kOrange;
      case 'resilie': return kRed;
      default: return kGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nbEnts = _stats['nb_entreprises'] ?? 0;
    final nbUsers = _stats['nb_utilisateurs'] ?? 0;
    final revenu = (_stats['revenu_total'] as num? ?? 0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B0036), Color(0xFF4C1D95)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Super Administration', style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text('Gestion globale de la plateforme',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
              ])),
              IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.white54, size: 20),
                  onPressed: _load),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _stat('$nbEnts', 'Entreprises', Colors.white),
              _stat('$nbUsers', 'Utilisateurs', Colors.purpleAccent),
              _stat('${(_stats['nb_fermes'] ?? 0)}', 'Fermes', Colors.greenAccent),
              _stat('${(revenu / 1000).toStringAsFixed(0)}K', 'Revenu FCFA', Colors.amber),
            ]),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              tabs: const [
                Tab(text: '📊 Dashboard'),
                Tab(text: '🏢 Entreprises'),
                Tab(text: '⚙️ Paramètres'),
              ],
            ),
          ]),
        ),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(
                color: Color(0xFF7C3AED)))
            : TabBarView(controller: _tabCtrl, children: [
          _buildDashboard(),
          _buildEntreprises(),
          _buildParametres(),
        ])),
      ]),
    );
  }

  // ── DASHBOARD ──
  Widget _buildDashboard() {
    final abos = _stats['abonnements'] as Map? ?? {};
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Grille KPIs
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.6,
        children: [
          _kpiCard('🏢 Entreprises', '${_stats['nb_entreprises'] ?? 0}',
              'clients actifs', const Color(0xFF7C3AED)),
          _kpiCard('👥 Utilisateurs', '${_stats['nb_utilisateurs'] ?? 0}',
              'comptes actifs', kBlue),
          _kpiCard('🏠 Fermes', '${_stats['nb_fermes'] ?? 0}',
              'enregistrées', kGreen),
          _kpiCard('🔄 Cycles', '${_stats['nb_cycles_actifs'] ?? 0}',
              '/ ${_stats['nb_cycles_total'] ?? 0} total', kOrange),
          _kpiCard('👨‍💼 Employés', '${_stats['nb_employes'] ?? 0}',
              'enregistrés', kIndigo),
          _kpiCard('💰 Revenu', '${(((_stats['revenu_total'] as num?) ?? 0) / 1000).toStringAsFixed(0)}K FCFA',
              'abonnements actifs', Colors.amber.shade700),
        ],
      ),
      const SizedBox(height: 16),
      // Abonnements
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📦 Abonnements', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14,
            color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        Row(children: [
          _aboStat('Pro', '${abos['pro'] ?? 0}', kBlue),
          const SizedBox(width: 10),
          _aboStat('Enterprise', '${abos['enterprise'] ?? 0}',
              const Color(0xFF7C3AED)),
          const SizedBox(width: 10),
          _aboStat('Expirés', '${abos['expires'] ?? 0}', kRed),
        ]),
      ])),
    ]);
  }

  Widget _kpiCard(String title, String value, String subtitle, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: color, width: 3)),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      );

  Widget _aboStat(String label, String count, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(count, style: TextStyle(
              fontWeight: FontWeight.w900, fontSize: 20, color: color)),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ]),
      ));

  // ── ENTREPRISES ──
  Widget _buildEntreprises() => _entreprises.isEmpty
      ? const Center(child: Text('Aucune entreprise',
          style: TextStyle(color: Colors.grey)))
      : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          itemCount: _entreprises.length,
          itemBuilder: (_, i) {
            final e = _entreprises[i];
            final plan = e['plan'] as String? ?? 'gratuit';
            final statut = e['statut_abo'] as String? ?? 'actif';
            final planColor = _planColor(plan);
            final statutColor = _statutColor(statut);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 4),
                leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: planColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(
                        plan == 'enterprise' ? '🏆'
                            : plan == 'pro' ? '⭐' : '🆓',
                        style: const TextStyle(fontSize: 18)))),
                title: Text(e['nom'] ?? '', style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13,
                    color: Color(0xFF1E293B))),
                subtitle: Row(children: [
                  Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: planColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(plan.toUpperCase(),
                          style: TextStyle(color: planColor,
                              fontSize: 9, fontWeight: FontWeight.w700))),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: statutColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(statut,
                          style: TextStyle(color: statutColor,
                              fontSize: 9, fontWeight: FontWeight.w700))),
                ]),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('📧 ${e['email'] ?? '-'}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      Text('🏠 ${e['nb_fermes'] ?? 0} fermes   '
                          '👥 ${e['nb_users'] ?? 0} users   '
                          '🔄 ${e['nb_cycles_actifs'] ?? 0} cycles actifs',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      if ((e['derniere_activite'] ?? '').isNotEmpty)
                        Text('Dernière activité: ${(e['derniere_activite'] as String).substring(0, 10)}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 12),
                      // Actions
                      Row(children: [
                        if (statut != 'actif')
                          Expanded(child: OutlinedButton(
                            onPressed: () => _actionEntreprise(
                                e['id'].toString(), 'reactiver', e['nom'] ?? ''),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: kGreen,
                                side: const BorderSide(color: kGreen),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8))),
                            child: const Text('✅ Réactiver',
                                style: TextStyle(fontSize: 11)),
                          ))
                        else ...[
                          Expanded(child: OutlinedButton(
                            onPressed: () => _actionEntreprise(
                                e['id'].toString(), 'suspendre', e['nom'] ?? ''),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: kOrange,
                                side: const BorderSide(color: kOrange),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8))),
                            child: const Text('⏸ Suspendre',
                                style: TextStyle(fontSize: 11)),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: OutlinedButton(
                            onPressed: () => _actionEntreprise(
                                e['id'].toString(), 'resilier', e['nom'] ?? ''),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: kRed,
                                side: const BorderSide(color: kRed),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8))),
                            child: const Text('🚫 Résilier',
                                style: TextStyle(fontSize: 11)),
                          )),
                        ],
                      ]),
                    ]),
                  ),
                ],
              ),
            );
          });

  void _actionEntreprise(String id, String action, String nom) {
    if (action == 'reactiver') {
      showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text('Réactiver "$nom" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await ApiService.reactiversEntreprise(id);
                _load();
              },
              style: ElevatedButton.styleFrom(backgroundColor: kGreen,
                  foregroundColor: Colors.white),
              child: const Text('Réactiver')),
        ],
      ));
      return;
    }

    final motifCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(action == 'suspendre'
          ? '⏸ Suspendre "$nom"' : '🚫 Résilier "$nom"'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(action == 'suspendre'
            ? 'L\'entreprise sera bloquée. Un email sera envoyé.'
            : 'L\'abonnement sera résilié. Un email sera envoyé.',
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 12),
        TextField(
            controller: motifCtrl,
            decoration: const InputDecoration(
                labelText: 'Motif *',
                border: OutlineInputBorder()),
            maxLines: 2),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        ElevatedButton(
            onPressed: () async {
              if (motifCtrl.text.isEmpty) return;
              Navigator.pop(context);
              if (action == 'suspendre') {
                await ApiService.suspendreEntreprise(id, motifCtrl.text);
              } else {
                await ApiService.resilierEntreprise(id, motifCtrl.text);
              }
              _load();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: action == 'suspendre' ? kOrange : kRed,
                foregroundColor: Colors.white),
            child: Text(action == 'suspendre' ? 'Suspendre' : 'Résilier')),
      ],
    ));
  }

  // ── PARAMÈTRES SYSTÈME ──
  Widget _buildParametres() => _parametres.isEmpty
      ? const Center(child: Text('Aucun paramètre',
          style: TextStyle(color: Colors.grey)))
      : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _parametres.length,
          itemBuilder: (_, i) {
            final p = _parametres[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                leading: const Icon(Icons.settings_rounded,
                    color: Color(0xFF7C3AED), size: 20),
                title: Text(p['cle'] as String? ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12,
                        color: Color(0xFF1E293B))),
                subtitle: Text(p['description'] as String? ?? '',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
                trailing: SizedBox(
                  width: 120,
                  child: Text(p['valeur'] as String? ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis),
                ),
                onTap: () => _editParametre(p),
              ),
            );
          });

  void _editParametre(Map p) {
    final ctrl = TextEditingController(text: p['valeur'] as String? ?? '');
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Modifier "${p['cle']}"'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        if ((p['description'] ?? '').toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(p['description'] as String,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        TextField(controller: ctrl,
            decoration: const InputDecoration(
                labelText: 'Valeur', border: OutlineInputBorder()),
            maxLines: 3),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.updateAdminParametre(
                  p['cle'].toString(), ctrl.text);
              _load();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white),
            child: const Text('Enregistrer')),
      ],
    ));
  }

  Widget _stat(String value, String label, Color color) =>
      Expanded(child: Column(children: [
        Text(value, style: TextStyle(
            color: color, fontSize: 15, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(
            color: Colors.white38, fontSize: 8),
            textAlign: TextAlign.center),
      ]));

  Widget _card({required Widget child}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
      child: child);
}
