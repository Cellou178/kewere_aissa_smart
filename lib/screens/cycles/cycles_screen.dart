import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../../services/api_service.dart';
import 'add_cycle_screen.dart';

void _snack(BuildContext context, String msg, Color color) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));

class CyclesScreen extends StatefulWidget {
  const CyclesScreen({super.key});
  @override
  State<CyclesScreen> createState() => _CyclesScreenState();
}

class _CyclesScreenState extends State<CyclesScreen>
    with SingleTickerProviderStateMixin {
  List _cycles = [];
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
    final c = await ApiService.getCycles();
    setState(() { _cycles = c is List ? c : []; _loading = false; });
  }

  List get _cyclesActifs => _cycles.where((c) =>
  c['statut'] == 'actif' || c['statut'] == 'en_cours').toList();
  List get _cyclesTermines => _cycles.where((c) =>
  c['statut'] == 'termine' || c['statut'] == 'terminé').toList();
  List get _cyclesPlanifies => _cycles.where((c) =>
  c['statut'] == 'planifie' || c['statut'] == 'planifié').toList();

  @override
  Widget build(BuildContext context) {
    final totalSujets = _cycles.fold<int>(0, (s, c) =>
    s + ((c['nombre_sujets'] ?? 0) as num).toInt());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: SessionManager.isProprietaire || SessionManager.isAdmin
          ? FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddCycleScreen()));
            if (result == true) _load();
          },
          backgroundColor: kBlue,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Nouveau Cycle',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))
          : null,
      body: Column(children: [
        // Header
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            // Stats rapides
            Row(children: [
              _headerStat('${_cycles.length}', 'Total', Icons.loop_rounded, Colors.white),
              _headerStat('${_cyclesActifs.length}', 'Actifs', Icons.play_circle_rounded, Colors.greenAccent),
              _headerStat('${_cyclesTermines.length}', 'Terminés', Icons.check_circle_rounded, Colors.blueAccent),
              _headerStat('$totalSujets', 'Sujets', Icons.pets_rounded, Colors.orangeAccent),
            ]),
            const SizedBox(height: 12),
            // Tabs
            TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              tabs: [
                Tab(text: 'Actifs (${_cyclesActifs.length})'),
                Tab(text: 'Terminés (${_cyclesTermines.length})'),
                Tab(text: 'Tous (${_cycles.length})'),
              ],
            ),
          ]),
        ),

        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlue))
            : TabBarView(controller: _tabCtrl, children: [
          _buildList(_cyclesActifs, 'Aucun cycle actif', 'Créez votre premier cycle'),
          _buildList(_cyclesTermines, 'Aucun cycle terminé', ''),
          _buildList(_cycles, 'Aucun cycle', 'Créez votre premier cycle'),
        ])),
      ]),
    );
  }

  Widget _buildList(List cycles, String emptyTitle, String emptySubtitle) =>
      RefreshIndicator(
        onRefresh: _load, color: kBlue,
        child: cycles.isEmpty
            ? ListView(children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(child: Column(children: [
            Icon(Icons.loop_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(emptyTitle, style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            if (emptySubtitle.isNotEmpty)
              Text(emptySubtitle, style: const TextStyle(color: Colors.grey)),
          ])),
        ])
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: cycles.length,
          itemBuilder: (_, i) => _cycleCard(cycles[i]),
        ),
      );

  Widget _cycleCard(Map c) {
    final statut = c['statut'] ?? '';
    final isActif = statut == 'actif' || statut == 'en_cours';
    final color = isActif ? kGreen : statut == 'terminé' || statut == 'termine'
        ? Colors.blueGrey : kOrange;
    final sujets = ((c['nombre_sujets'] ?? 0) as num).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        // Top
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
          child: Row(children: [
            Container(width: 42, height: 42,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(isActif ? Icons.pets_rounded : Icons.check_circle_rounded,
                    color: color, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c['nom'] ?? 'Cycle', style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
              Text('${c['souche'] ?? '-'} • Bât. ${c['batiment'] ?? '-'}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(statut, style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w700))),
          ]),
        ),
        // Bottom stats
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              _cycleChip(Icons.pets_rounded, '$sujets sujets', kBlue),
              const SizedBox(width: 8),
              _cycleChip(Icons.calendar_today_rounded, c['date_debut'] ?? '-', kGreen),
              const Spacer(),
              if (isActif) Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: kBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Icon(Icons.circle, size: 6, color: kGreen),
                  const SizedBox(width: 4),
                  const Text('En cours', style: TextStyle(
                      color: kBlue, fontSize: 10, fontWeight: FontWeight.w600)),
                ]),
              ),
            ])),
      ]),
    );
  }

  Widget _headerStat(String value, String label, IconData icon, Color color) =>
      Expanded(child: Column(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(
            color: color, fontSize: 16, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
      ]));

  Widget _cycleChip(IconData icon, String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]));
}