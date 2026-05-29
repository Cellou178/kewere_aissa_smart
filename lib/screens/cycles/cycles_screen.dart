import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../../services/api_service.dart';
import '../../core/utils/app_transitions.dart';
import 'add_cycle_screen.dart';
import 'resume_cycle_screen.dart';

class CyclesScreen extends StatefulWidget {
  const CyclesScreen({super.key});
  @override
  State<CyclesScreen> createState() => _CyclesScreenState();
}

class _CyclesScreenState extends State<CyclesScreen>
    with SingleTickerProviderStateMixin {
  List _cycles = [];
  List _donnees = [];
  bool _loading = true;
  late TabController _tabCtrl;
  String _recherche = '';

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
    ApiService.clearCache();
    final c = await ApiService.getCycles();
    final d = await ApiService.getDonnees();
    setState(() {
      _cycles = c is List ? c : [];
      _donnees = d is List ? d : [];
      _loading = false;
    });
  }

  List get _cyclesFiltres => _cycles.where((c) =>
  (c['nom'] ?? '').toLowerCase().contains(_recherche.toLowerCase()) ||
      (c['souche'] ?? '').toLowerCase().contains(
          _recherche.toLowerCase())).toList();

  List get _cyclesActifs => _cyclesFiltres.where((c) =>
  c['statut'] == 'actif' || c['statut'] == 'en_cours').toList();
  List get _cyclesTermines => _cyclesFiltres.where((c) =>
  c['statut'] == 'termine' || c['statut'] == 'terminé').toList();

  List _donneesForCycle(String? id) => id == null ? [] :
  _donnees.where((d) =>
      d['cycle_id']?.toString() == id).toList();

  int _mortaliteCycle(Map c) =>
      _donneesForCycle(c['id']?.toString())
          .fold<int>(0, (s, d) =>
      s + ((d['mortalite'] ?? 0) as num).toInt());

  double _tauxMortalite(Map c) {
    final sujets = ((c['nombre_sujets'] ?? 0) as num).toInt();
    final morts = _mortaliteCycle(c);
    return sujets > 0 ? (morts / sujets * 100) : 0;
  }

  double _avgTemp(Map c) {
    final data = _donneesForCycle(c['id']?.toString());
    if (data.isEmpty) return 0;
    return data.fold<double>(0, (s, d) =>
    s + ((d['temperature'] ?? 0) as num).toDouble()) / data.length;
  }

  int _joursDepuis(Map c) {
    try {
      final debut = DateTime.parse(c['date_debut'] ?? '');
      return DateTime.now().difference(debut).inDays;
    } catch (_) { return 0; }
  }

  @override
  Widget build(BuildContext context) {
    final totalSujets = _cycles.fold<int>(0, (s, c) =>
    s + ((c['nombre_sujets'] ?? 0) as num).toInt());
    final totalMorts = _cycles.fold<int>(0,
            (s, c) => s + _mortaliteCycle(c));
    final tauxGlobal = totalSujets > 0
        ? (totalMorts / totalSujets * 100) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: SessionManager.isProprietaire ||
          SessionManager.isAdmin
          ? FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(context,
                AppTransitions.slideFade(
                    const AddCycleScreen()));
            if (result == true) {
              ApiService.clearCache();
              _load();
            }
          },
          backgroundColor: kBlue,
          icon: const Icon(Icons.add_rounded,
              color: Colors.white),
          label: const Text('Nouveau Cycle',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700)))
          : null,
      body: Column(children: [

        // ── HEADER ──
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [

            // Stats header
            Row(children: [
              _headerStat('${_cycles.length}', 'Total',
                  Icons.loop_rounded, Colors.white),
              _headerStat('${_cyclesActifs.length}', 'Actifs',
                  Icons.play_circle_rounded, Colors.greenAccent),
              _headerStat('$totalSujets', 'Sujets',
                  Icons.pets_rounded, Colors.orangeAccent),
              _headerStat(
                  '${tauxGlobal.toStringAsFixed(1)}%',
                  'Mortalité',
                  Icons.warning_rounded,
                  tauxGlobal > 5
                      ? Colors.redAccent : Colors.greenAccent),
            ]),
            const SizedBox(height: 12),

            // Recherche
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    hintText: 'Rechercher un cycle...',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Colors.white54, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 12)),
                onChanged: (v) =>
                    setState(() => _recherche = v),
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 11),
              tabs: [
                Tab(text: 'Actifs (${_cyclesActifs.length})'),
                Tab(text: 'Terminés (${_cyclesTermines.length})'),
                Tab(text: 'Tous (${_cyclesFiltres.length})'),
              ],
            ),
          ]),
        ),

        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(
            color: kBlue))
            : RefreshIndicator(
          onRefresh: _load,
          color: kBlue,
          child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList(_cyclesActifs, 'Aucun cycle actif',
                    'Créez votre premier cycle'),
                _buildList(_cyclesTermines,
                    'Aucun cycle terminé', ''),
                _buildList(_cyclesFiltres, 'Aucun cycle',
                    'Créez votre premier cycle'),
              ]),
        )),
      ]),
    );
  }

  Widget _buildList(List cycles, String emptyTitle,
      String emptySubtitle) =>
      cycles.isEmpty
          ? ListView(children: [
        SizedBox(
            height: MediaQuery.of(context).size.height * 0.25),
        Center(child: Column(children: [
          Icon(Icons.loop_rounded,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(emptyTitle, style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B))),
          if (emptySubtitle.isNotEmpty)
            Text(emptySubtitle,
                style: const TextStyle(color: Colors.grey)),
        ])),
      ])
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: cycles.length,
        itemBuilder: (_, i) => AnimatedCard(
          delay: Duration(milliseconds: 50 * i),
          child: _cycleCard(cycles[i]),
        ),
      );

  Widget _cycleCard(Map c) {
    final statut = c['statut'] ?? '';
    final isActif = statut == 'actif' || statut == 'en_cours';
    final isTermine = statut == 'terminé' || statut == 'termine';
    final color = isActif ? kGreen
        : isTermine ? Colors.blueGrey : kOrange;
    final sujets = ((c['nombre_sujets'] ?? 0) as num).toInt();
    final morts = _mortaliteCycle(c);
    final taux = _tauxMortalite(c);
    final temp = _avgTemp(c);
    final jours = _joursDepuis(c);
    final donnees = _donneesForCycle(c['id']?.toString());
    final tauxColor = taux > 5 ? kRed
        : taux > 2 ? kOrange : kGreen;

    return GestureDetector(
      onTap: () => _showCycleDetail(c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))]),
        child: Column(children: [

          // Header carte
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16))),
            child: Row(children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(
                      isActif ? Icons.pets_rounded
                          : isTermine
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      color: color, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(c['nom'] ?? 'Cycle',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF1E293B))),
                Text('${c['souche'] ?? '-'} • '
                    'Bât. ${c['batiment'] ?? '-'}',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11)),
              ])),
              Column(crossAxisAlignment:
                  CrossAxisAlignment.end, children: [
                Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(statut, style: TextStyle(
                        color: color, fontSize: 9,
                        fontWeight: FontWeight.w700))),
                if (isActif) ...[
                  const SizedBox(height: 3),
                  Text('J+$jours', style: TextStyle(
                      color: color, fontSize: 10,
                      fontWeight: FontWeight.w600)),
                ],
              ]),
            ]),
          ),

          // Métriques
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Row(mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, children: [
                Text('Mortalité: $morts/$sujets',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
                Text('${taux.toStringAsFixed(1)}%',
                    style: TextStyle(color: tauxColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                      value: sujets > 0
                          ? (morts / sujets).clamp(0.0, 1.0)
                          : 0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                          tauxColor),
                      minHeight: 4)),
              const SizedBox(height: 10),

              Row(children: [
                _chip(Icons.pets_rounded,
                    '$sujets sujets', kBlue),
                const SizedBox(width: 6),
                if (temp > 0) _chip(Icons.thermostat_rounded,
                    '${temp.toStringAsFixed(1)}°C', kOrange),
                const SizedBox(width: 6),
                _chip(Icons.bar_chart_rounded,
                    '${donnees.length} relevés', kPurple),
                const Spacer(),
                if (isActif) Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                      color: kGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: Row(children: [
                    Container(width: 6, height: 6,
                        decoration: const BoxDecoration(
                            color: kGreen,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('Live', style: TextStyle(
                        color: kGreen, fontSize: 9,
                        fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showCycleDetail(Map c) {
    final sujets = ((c['nombre_sujets'] ?? 0) as num).toInt();
    final morts = _mortaliteCycle(c);
    final taux = _tauxMortalite(c);
    final temp = _avgTemp(c);
    final donnees = _donneesForCycle(c['id']?.toString());
    final statut = c['statut'] ?? '';
    final isActif = statut == 'actif' || statut == 'en_cours';
    final color = isActif ? kGreen : Colors.blueGrey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(24))),
        child: Column(children: [
          Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),

          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(isActif ? Icons.pets_rounded
                      : Icons.check_circle_rounded,
                      color: Colors.white, size: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(c['nom'] ?? '', style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
                Text('${c['souche'] ?? '-'} • '
                    'Bât. ${c['batiment'] ?? '-'}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ])),
              Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(statut, style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11))),
            ]),
          ),

          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              Row(children: [
                _detailKpi('🐔', '$sujets', 'Sujets', kBlue),
                const SizedBox(width: 8),
                _detailKpi('💀', '$morts', 'Morts', kRed),
                const SizedBox(width: 8),
                _detailKpi('📊',
                    '${taux.toStringAsFixed(1)}%',
                    'Taux mort.',
                    taux > 5 ? kRed : kGreen),
                const SizedBox(width: 8),
                _detailKpi('🌡️',
                    '${temp.toStringAsFixed(1)}°',
                    'Temp. moy.', kOrange),
              ]),
              const SizedBox(height: 12),

              _detailCard([
                _infoRow('📅 Date début',
                    c['date_debut'] ?? '-'),
                _infoRow('📅 Date fin', c['date_fin'] ?? '-'),
                _infoRow('🏗️ Bâtiment', c['batiment'] ?? '-'),
                _infoRow('🐥 Souche', c['souche'] ?? '-'),
                _infoRow('📊 Relevés', '${donnees.length}'),
                _infoRow('⏱️ Jours écoulés',
                    'J+${_joursDepuis(c)}'),
              ]),
              const SizedBox(height: 12),

              // Bouton Résumé
              SizedBox(width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, AppTransitions.slideFade(
                      ResumeCycleScreen(
                        cycle: c,
                        donnees: donnees,
                      ),
                    ));
                  },
                  icon: const Icon(Icons.summarize_rounded, size: 16),
                  label: const Text('Voir Résumé & Exporter',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0),
                ),
              ),
              const SizedBox(height: 8),

              if (SessionManager.isProprietaire ||
                  SessionManager.isAdmin) ...[
                Row(children: [
                  Expanded(child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        final ok = await ApiService.updateCycle(
                            c['id'].toString(),
                            {...c, 'statut': 'termine'});
                        if (ok) {
                          ApiService.clearCache();
                          _load();
                        }
                      },
                      icon: const Icon(Icons.check_rounded,
                          size: 16),
                      label: const Text('Terminer',
                          style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(10)),
                          elevation: 0))),
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        final ok = await ApiService.deleteCycle(
                            c['id'].toString());
                        if (ok) {
                          ApiService.clearCache();
                          _load();
                        }
                      },
                      icon: const Icon(Icons.delete_rounded,
                          size: 16),
                      label: const Text('Supprimer',
                          style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(10)),
                          elevation: 0,
                          side: BorderSide(
                              color: Colors.red.shade200)))),
                ]),
              ],
              const SizedBox(height: 20),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _detailKpi(String emoji, String value,
      String label, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6)]),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14, color: color)),
          Text(label, style: const TextStyle(
              color: Colors.grey, fontSize: 9)),
        ]),
      ));

  Widget _detailCard(List<Widget> items) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8)]),
      child: Column(children: items));

  Widget _infoRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
        Text(label, style: const TextStyle(
            color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 12,
            color: Color(0xFF1E293B))),
      ]));

  Widget _chip(IconData icon, String text, Color color) =>
      Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
            Text(text, style: TextStyle(
                color: color, fontSize: 9,
                fontWeight: FontWeight.w600)),
          ]));

  Widget _headerStat(String value, String label,
      IconData icon, Color color) =>
      Expanded(child: Column(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(
            color: color, fontSize: 14,
            fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(
            color: Colors.white38, fontSize: 8)),
      ]));
}