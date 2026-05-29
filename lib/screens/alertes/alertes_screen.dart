import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';

class AlertesScreen extends StatefulWidget {
  const AlertesScreen({super.key});
  @override
  State<AlertesScreen> createState() => _AlertesScreenState();
}

class _AlertesScreenState extends State<AlertesScreen>
    with SingleTickerProviderStateMixin {
  List _alertes = [];
  List _donnees = [];
  bool _loading = true;
  late TabController _tabCtrl;

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
    final a = await ApiService.getAlertes();
    final d = await ApiService.getDonnees();
    setState(() {
      _alertes = a is List ? a : [];
      _donnees = d is List ? d : [];
      _loading = false;
    });
  }

  List _alertesAuto() {
    List alertes = [];
    final sorted = List.from(_donnees)..sort((a, b) =>
        (b['date_releve'] ?? '').compareTo(a['date_releve'] ?? ''));
    if (sorted.isNotEmpty) {
      final mort = ((sorted.first['mortalite'] ?? 0) as num).toInt();
      final temp = ((sorted.first['temperature'] ?? 0) as num).toDouble();
      if (mort > 10) alertes.add({
        'titre': 'Mortalité critique : $mort morts',
        'message': 'Taux de mortalité très élevé — intervention urgente requise',
        'type': 'danger'
      });
      else if (mort > 5) alertes.add({
        'titre': 'Mortalité élevée : $mort morts',
        'message': 'Surveiller de près les conditions d\'élevage',
        'type': 'warning'
      });
      if (temp > 35) alertes.add({
        'titre': 'Température critique : ${temp.toStringAsFixed(1)}°C',
        'message': 'Risque de stress thermique — ventilation urgente',
        'type': 'danger'
      });
      else if (temp > 32) alertes.add({
        'titre': 'Température élevée : ${temp.toStringAsFixed(1)}°C',
        'message': 'Surveiller la ventilation et l\'hydratation',
        'type': 'warning'
      });
    }
    return alertes;
  }

  List get _toutesAlertes => [..._alertesAuto(), ..._alertes];
  List get _critiques => _toutesAlertes.where((a) => a['type'] == 'danger').toList();
  List get _avertissements => _toutesAlertes.where((a) => a['type'] == 'warning').toList();

  @override
  Widget build(BuildContext context) {
    final nbCritiques = _critiques.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(children: [
        // Header
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: nbCritiques > 0
                  ? [const Color(0xFF7F1D1D), const Color(0xFF991B1B)]
                  : [const Color(0xFF0F172A), const Color(0xFF1E3A5F)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            Row(children: [
              Icon(nbCritiques > 0 ? Icons.warning_rounded : Icons.notifications_rounded,
                  color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(nbCritiques > 0 ? '$nbCritiques Alerte(s) Critique(s)' : 'Alertes',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 18, fontWeight: FontWeight.w900)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 20),
                  onPressed: _load),
            ]),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              tabs: [
                Tab(text: 'Toutes (${_toutesAlertes.length})'),
                Tab(text: '🚨 Critiques (${_critiques.length})'),
                Tab(text: '⚠️ Warnings (${_avertissements.length})'),
              ],
            ),
          ]),
        ),

        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlue))
            : TabBarView(controller: _tabCtrl, children: [
          _buildList(_toutesAlertes),
          _buildList(_critiques),
          _buildList(_avertissements),
        ])),
      ]),
    );
  }

  Widget _buildList(List alertes) => RefreshIndicator(
    onRefresh: _load, color: kBlue,
    child: alertes.isEmpty
        ? ListView(children: [
      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
      const Center(child: Column(children: [
        Icon(Icons.check_circle_rounded, size: 56, color: Colors.green),
        SizedBox(height: 12),
        Text('✅ Aucune alerte', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
        Text('Tout va bien !', style: TextStyle(color: Colors.grey)),
      ])),
    ])
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alertes.length,
      itemBuilder: (_, i) => _alerteCard(alertes[i]),
    ),
  );

  Widget _alerteCard(Map a) {
    final type = a['type'] ?? 'info';
    final color = type == 'danger' ? kRed : type == 'warning' ? kOrange : kBlue;
    final icon = type == 'danger' ? Icons.dangerous_rounded
        : type == 'warning' ? Icons.warning_rounded : Icons.info_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
        title: Text(a['titre'] ?? a['message'] ?? '',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
        subtitle: a['message'] != null && a['titre'] != null
            ? Text(a['message'], style: const TextStyle(fontSize: 11, color: Colors.grey))
            : null,
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            color: color.withOpacity(0.4), size: 12),
      ),
    );
  }
}