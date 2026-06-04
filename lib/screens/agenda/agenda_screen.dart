import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import '../../managers/session_manager.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});
  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List _cycles = [];
  List<Map<String, dynamic>> _taches = [];
  bool _loading = true;
  bool _loadingIA = false;
  String? _planningIA;
  DateTime _selectedDate = DateTime.now();

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
      ApiService.getCycles(),
      ApiService.getTaches(),
    ]);
    setState(() {
      _cycles = results[0];
      _taches = List<Map<String, dynamic>>.from(
          (results[1] as List).map((t) => Map<String, dynamic>.from(t as Map)));
      _loading = false;
    });
    _genererPlanningIA();
  }

  // Normalise un enregistrement API → format UI
  DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now().add(const Duration(days: 1));
    try { return DateTime.parse(val.toString()); } catch (_) {
      return DateTime.now().add(const Duration(days: 1));
    }
  }

  bool _isDone(Map t) => (t['statut'] ?? '') == 'termine';

  Future<void> _toggleDone(Map<String, dynamic> t) async {
    final id = t['id']?.toString() ?? '';
    if (id.isEmpty) return;
    if (!_isDone(t)) {
      await ApiService.terminerTache(id);
    } else {
      await ApiService.updateTache(id, {
        'titre': t['titre'], 'description': t['description'],
        'date_echeance': t['date_echeance'], 'type': t['type'] ?? 'autre',
        'priorite': t['priorite'] ?? 'normale', 'statut': 'en_cours',
      });
    }
    _load();
  }

  Future<void> _deleteTache(String id) async {
    await ApiService.deleteTache(id);
    _load();
  }

  Future<void> _genererPlanningIA() async {
    setState(() { _loadingIA = true; _planningIA = null; });
    try {
      final cyclesActifs = _cycles.where((c) =>
          c['statut'] == 'actif' || c['statut'] == 'en_cours').toList();
      final prompt = '''Tu es un expert en gestion avicole au Sénégal.
Génère un planning hebdomadaire détaillé pour une ferme avicole.

CONTEXTE:
- Éleveur: ${SessionManager.nom}
- Cycles actifs: ${cyclesActifs.length}
- Tâches en cours: ${_taches.where((t) => !_isDone(t)).length}
- Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

Génère un planning pour les 7 prochains jours avec:
- Tâches quotidiennes (alimentation, eau, surveillance)
- Tâches hebdomadaires (pesée, nettoyage, inventaire)
- Tâches sanitaires (vaccinations, traitements)
- Tâches administratives (rapports, commandes)

Format: Jour par jour avec heure et description courte.
En français, pratique et concis.''';
      final reponse = await ApiService.callIA(prompt,
          contexte: 'Expert aviculture Sénégal, génère un planning hebdomadaire.');
      setState(() => _planningIA = reponse.isEmpty ? 'Planning indisponible.' : reponse);
    } catch (_) {
      setState(() => _planningIA = 'Planning indisponible.');
    }
    setState(() => _loadingIA = false);
  }

  List<Map<String, dynamic>> get _tachesAujourdhui => _taches.where((t) {
    final d = _parseDate(t['date_echeance']);
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }).toList();

  List<Map<String, dynamic>> get _tachesAVenir => _taches.where((t) {
    final d = _parseDate(t['date_echeance']);
    return d.isAfter(DateTime.now()) && !_isDone(t);
  }).toList()..sort((a, b) =>
      _parseDate(a['date_echeance']).compareTo(_parseDate(b['date_echeance'])));

  List<Map<String, dynamic>> get _tachesTerminees =>
      _taches.where((t) => _isDone(t)).toList();

  Color _typeColor(String type) {
    switch (type) {
      case 'sante': return kRed;
      case 'suivi': return kBlue;
      case 'hygiene': return kGreen;
      case 'stock': return kOrange;
      case 'admin': return kPurple;
      default: return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'sante': return Icons.medical_services_rounded;
      case 'suivi': return Icons.monitor_weight_rounded;
      case 'hygiene': return Icons.cleaning_services_rounded;
      case 'stock': return Icons.inventory_rounded;
      case 'admin': return Icons.assignment_rounded;
      default: return Icons.task_rounded;
    }
  }

  Color _prioriteColor(String priorite) {
    switch (priorite) {
      case 'critique': return kRed;
      case 'haute': return kOrange;
      default: return kBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tachesRestantes = _taches.where((t) => !_isDone(t)).length;
    final tachesCritiques = _taches.where((t) =>
        (t['priorite'] ?? '') == 'critique' && !_isDone(t)).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAjouterTache(),
          backgroundColor: kBlue,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Nouvelle Tâche',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
      body: Column(children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: tachesCritiques > 0
                  ? [const Color(0xFF7F1D1D), const Color(0xFF991B1B)]
                  : [const Color(0xFF0F172A), const Color(0xFF1E3A5F)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(4, 16, 16, 0),
          child: Column(children: [
            Row(children: [
              if (Navigator.canPop(context)) IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
              const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Agenda & Planning', style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text('${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ])),
              IconButton(icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white54, size: 20), onPressed: _load),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _headerStat('$tachesRestantes', 'À faire', Colors.white),
              _headerStat('${_tachesAujourdhui.length}', 'Aujourd\'hui', Colors.greenAccent),
              _headerStat('$tachesCritiques', 'Critiques',
                  tachesCritiques > 0 ? Colors.redAccent : Colors.greenAccent),
              _headerStat('${_tachesTerminees.length}', 'Terminées', Colors.blueAccent),
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
                Tab(text: '📅 Tâches'),
                Tab(text: '🗓️ Calendrier'),
                Tab(text: '🤖 Planning IA'),
              ],
            ),
          ]),
        ),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlue))
            : TabBarView(controller: _tabCtrl, children: [
          _buildTaches(),
          _buildCalendrier(),
          _buildPlanningIA(),
        ])),
      ]),
    );
  }

  Widget _buildTaches() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
    children: [
      if (_tachesAujourdhui.isNotEmpty) ...[
        _sectionHeader('📅 Aujourd\'hui', '${_tachesAujourdhui.length}', kOrange),
        const SizedBox(height: 8),
        ..._tachesAujourdhui.map(_tacheCard),
        const SizedBox(height: 16),
      ],
      if (_tachesAVenir.isNotEmpty) ...[
        _sectionHeader('⏰ À Venir', '${_tachesAVenir.length}', kBlue),
        const SizedBox(height: 8),
        ..._tachesAVenir.map(_tacheCard),
        const SizedBox(height: 16),
      ],
      if (_taches.isEmpty) Center(child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          const Icon(Icons.task_alt_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          const Text('Aucune tâche', style: TextStyle(color: Colors.grey, fontSize: 16)),
          TextButton(onPressed: _load, child: const Text('Actualiser')),
        ]),
      )),
      if (_tachesTerminees.isNotEmpty) ...[
        _sectionHeader('✅ Terminées', '${_tachesTerminees.length}', kGreen),
        const SizedBox(height: 8),
        ..._tachesTerminees.map(_tacheCard),
      ],
    ],
  );

  Widget _tacheCard(Map<String, dynamic> t) {
    final type = (t['type'] as String? ?? 'autre');
    final priorite = (t['priorite'] as String? ?? 'normale');
    final done = _isDone(t);
    final date = _parseDate(t['date_echeance']);
    final color = done ? Colors.grey : _typeColor(type);
    final prioriteColor = _prioriteColor(priorite);
    final id = t['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: priorite == 'critique' && !done
              ? Border.all(color: kRed.withValues(alpha: 0.3)) : null,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: GestureDetector(
          onTap: () => _toggleDone(t),
          child: Container(width: 36, height: 36,
              decoration: BoxDecoration(
                  color: done ? Colors.grey.withValues(alpha: 0.1)
                      : color.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: done
                  ? const Icon(Icons.check_circle_rounded, color: Colors.grey, size: 20)
                  : Icon(_typeIcon(type), color: color, size: 18)),
        ),
        title: Text(t['titre'] as String? ?? '', style: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 13,
            color: done ? Colors.grey : const Color(0xFF1E293B),
            decoration: done ? TextDecoration.lineThrough : null)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if ((t['description'] ?? '').isNotEmpty)
            Text(t['description'] as String,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 3),
          Row(children: [
            Icon(Icons.schedule_rounded, size: 11, color: color),
            const SizedBox(width: 3),
            Text('${date.day}/${date.month}/${date.year}',
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                    color: prioriteColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(priorite, style: TextStyle(
                    color: prioriteColor, fontSize: 9, fontWeight: FontWeight.w700))),
          ]),
        ]),
        trailing: id.isNotEmpty ? IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 18),
            onPressed: () => _deleteTache(id)) : null,
      ),
    );
  }

  Widget _buildCalendrier() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('📅 Cette Semaine', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
          Text('${DateTime.now().month}/${DateTime.now().year}',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        Row(children: List.generate(7, (i) {
          final day = DateTime.now().subtract(
              Duration(days: DateTime.now().weekday - 1 - i));
          final isToday = day.day == DateTime.now().day;
          final hasTache = _taches.any((t) {
            final d = _parseDate(t['date_echeance']);
            return d.day == day.day && d.month == day.month;
          });
          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _selectedDate = day),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                  color: isToday ? kBlue : _selectedDate.day == day.day
                      ? kBlue.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                Text(['L','M','M','J','V','S','D'][i],
                    style: TextStyle(
                        color: isToday ? Colors.white : Colors.grey,
                        fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${day.day}', style: TextStyle(
                    color: isToday ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 14, fontWeight: FontWeight.w800)),
                if (hasTache) Container(width: 4, height: 4,
                    decoration: BoxDecoration(
                        color: isToday ? Colors.white : kOrange,
                        shape: BoxShape.circle)),
              ]),
            ),
          ));
        })),
      ])),
      const SizedBox(height: 16),
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Tâches du ${_selectedDate.day}/${_selectedDate.month}',
            style: const TextStyle(fontWeight: FontWeight.w800,
                fontSize: 14, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        ...() {
          final tachesJour = _taches.where((t) {
            final d = _parseDate(t['date_echeance']);
            return d.day == _selectedDate.day && d.month == _selectedDate.month;
          }).toList();
          if (tachesJour.isEmpty) {
            return [const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucune tâche ce jour', style: TextStyle(color: Colors.grey)),
            ))];
          }
          return tachesJour.map(_tacheCard).toList();
        }(),
      ])),
      const SizedBox(height: 16),
      if (_cycles.isNotEmpty) _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🔄 Cycles en cours', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        ..._cycles.where((c) =>
            c['statut'] == 'actif' || c['statut'] == 'en_cours')
            .take(3).map((c) => ListTile(
          dense: true,
          leading: Container(padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: kGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.loop_rounded, color: kGreen, size: 16)),
          title: Text(c['nom'] ?? '', style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13)),
          subtitle: Text('Début: ${c['date_debut'] ?? '-'}',
              style: const TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.circle, color: kGreen, size: 8),
        )),
      ])),
    ],
  );

  Widget _buildPlanningIA() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A5F), Color(0xFF4C1D95)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 36),
          const SizedBox(height: 8),
          const Text('Planning IA Automatique', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          const Text('Planification optimisée par Claude AI',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: _loadingIA ? null : _genererPlanningIA,
              icon: _loadingIA
                  ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(color: kPurple, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(_loadingIA ? 'Génération en cours...' : 'Générer le planning',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: kPurple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0))),
        ]),
      ),
      const SizedBox(height: 16),
      if (_planningIA != null) Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.auto_awesome_rounded, color: kPurple, size: 18),
            SizedBox(width: 8),
            Text('Planning de la Semaine', style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
          ]),
          const Divider(),
          const SizedBox(height: 8),
          Text(_planningIA!, style: const TextStyle(
              fontSize: 13, color: Color(0xFF1E293B), height: 1.6)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: _genererPlanningIA,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Regénérer'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: kPurple, side: const BorderSide(color: kPurple),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
        ]),
      ),
    ]),
  );

  void _showAjouterTache() {
    final titreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String typeSelected = 'suivi';
    String prioriteSelected = 'normale';
    DateTime dateSelected = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(context: context, isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setModalState) => Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    left: 20, right: 20, top: 24),
                child: Column(mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Nouvelle Tâche', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                  const SizedBox(height: 16),
                  TextField(controller: titreCtrl,
                      decoration: InputDecoration(labelText: 'Titre *',
                          prefixIcon: const Icon(Icons.task_rounded, color: kBlueLight, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true, fillColor: const Color(0xFFF8FAFC))),
                  const SizedBox(height: 10),
                  TextField(controller: descCtrl,
                      decoration: InputDecoration(labelText: 'Description',
                          prefixIcon: const Icon(Icons.notes_rounded, color: kBlueLight, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true, fillColor: const Color(0xFFF8FAFC))),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: DropdownButtonFormField<String>(
                        value: typeSelected,
                        decoration: InputDecoration(labelText: 'Type',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true, fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: ['suivi','sante','hygiene','stock','admin','autre']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setModalState(() => typeSelected = v!))),
                    const SizedBox(width: 10),
                    Expanded(child: DropdownButtonFormField<String>(
                        value: prioriteSelected,
                        decoration: InputDecoration(labelText: 'Priorité',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true, fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: ['normale','haute','critique']
                            .map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (v) => setModalState(() => prioriteSelected = v!))),
                  ]),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dateSelected,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setModalState(() => dateSelected = picked);
                      },
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text('Échéance: ${dateSelected.day}/${dateSelected.month}/${dateSelected.year}'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: kBlue, side: const BorderSide(color: kBlue))),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, height: 48,
                      child: ElevatedButton.icon(
                          onPressed: () async {
                            if (titreCtrl.text.isEmpty) return;
                            final ok = await ApiService.createTache({
                              'titre': titreCtrl.text,
                              'description': descCtrl.text,
                              'date_echeance': dateSelected.toIso8601String().substring(0, 10),
                              'type': typeSelected,
                              'priorite': prioriteSelected,
                              'statut': 'en_cours',
                            });
                            Navigator.pop(context);
                            if (ok) {
                              _load();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('✅ Tâche ajoutée !'),
                                    backgroundColor: kGreen,
                                    behavior: SnackBarBehavior.floating));
                              }
                            }
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Ajouter la tâche',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: kBlue, foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0))),
                ]))));
  }

  Widget _sectionHeader(String title, String count, Color color) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(count, style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700))),
      ]);

  Widget _headerStat(String value, String label, Color color) =>
      Expanded(child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
      ]));

  Widget _card({required Widget child}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
      child: child);
}
