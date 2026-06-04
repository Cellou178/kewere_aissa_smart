import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});
  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = true;
  bool _loadingIA = false;
  String? _planIA;
  List _taches = [];

  List _equipements = [];

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
      ApiService.getTaches(),
      ApiService.getEquipements(),
    ]);
    setState(() {
      _taches = results[0];
      _equipements = results[1];
      _loading = false;
    });
  }

  Future<void> _genererPlanMaintenance() async {
    setState(() { _loadingIA = true; _planIA = null; });
    try {
      final tachesEnAttente = _taches
          .where((t) => t['statut'] == 'en_attente' || t['statut'] == 'en_cours').length;
      final equipementsCritiques = _equipements
          .where((e) => e['etat'] == 'critique').length;

      final prompt = '''Tu es un expert en maintenance de fermes avicoles au Sénégal.
Génère un plan de maintenance optimisé pour cette ferme.

ÉTAT ACTUEL:
- Tâches en attente/cours: $tachesEnAttente
- Équipements critiques: $equipementsCritiques
- Tâches totales: ${_taches.length}

TÂCHES URGENTES:
${_taches.where((t) => t['priorite'] == 'critique' || t['priorite'] == 'haute').map((t) => '- ${t['titre']} (${t['description'] ?? ''})').join('\n')}

ÉQUIPEMENTS EN MAUVAIS ÉTAT:
${_equipements.where((e) => e['etat'] != 'bon').map((e) => '- ${e['nom']} (${e['etat']})').join('\n')}

Génère un plan de maintenance sur 30 jours incluant:
1. Priorités immédiates (semaine 1)
2. Actions semaine 2-3
3. Maintenance préventive semaine 4
4. Budget recommandé
5. Conseils pour réduire les coûts

En français, pratique et structuré.''';

      final reponse = await ApiService.callIA(prompt,
          contexte: 'Expert maintenance avicole Sénégal. Plan structuré et budgétisé.');
      setState(() => _planIA = reponse.isEmpty ? 'Plan indisponible.' : reponse);
    } catch (e) {
      setState(() => _planIA = 'Plan indisponible.');
    }
    setState(() => _loadingIA = false);
  }

  Color _prioriteColor(String p) => p == 'critique' ? kRed
      : p == 'haute' ? kOrange : p == 'normale' ? kBlue : Colors.grey;

  Color _statutColor(String s) => s == 'termine' ? kGreen
      : s == 'en_cours' ? kBlue : kOrange;

  Color _etatColor(String e) => e == 'bon' ? kGreen
      : e == 'attention' ? kOrange : kRed;

  int get _tachesEnAttente => _taches
      .where((t) => t['statut'] == 'en_attente' || t['statut'] == 'en_cours').length;
  int get _tachesTerminees => _taches
      .where((t) => t['statut'] == 'termine').length;

  @override
  Widget build(BuildContext context) {
    final urgentes = _taches
        .where((t) => t['priorite'] == 'critique').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAjouterTache(),
          backgroundColor: kOrange,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Nouvelle tâche',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700))),
      body: Column(children: [
        // Header
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: urgentes > 0
                  ? [const Color(0xFF7F1D1D), const Color(0xFF1E3A5F)]
                  : [const Color(0xFF0F172A), const Color(0xFF1E3A5F)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(4, 16, 16, 0),
          child: Column(children: [
            Row(children: [
              if (Navigator.canPop(context)) IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
              const Icon(Icons.build_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Maintenance', style: TextStyle(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w900)),
                    Text('Suivi équipements & bâtiments',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ])),
            ]),
            const SizedBox(height: 12),

            // Stats
            Row(children: [
              _headerStat('${_taches.length}', 'Tâches\ntotales',
                  Colors.white),
              _headerStat('$_tachesEnAttente', 'En\nattente',
                  _tachesEnAttente > 0
                      ? Colors.amber : Colors.greenAccent),
              _headerStat('$urgentes', 'Critiques',
                  urgentes > 0
                      ? Colors.redAccent : Colors.greenAccent),
              _headerStat('${(0 / 1000).toStringAsFixed(0)}K',
                  'Budget\n(FCFA)', Colors.amber),
            ]),
            const SizedBox(height: 12),

            TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 11),
              tabs: const [
                Tab(text: '📋 Tâches'),
                Tab(text: '🔧 Équipements'),
                Tab(text: '🤖 Plan IA'),
              ],
            ),
          ]),
        ),

        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _buildTaches(),
          _buildEquipements(),
          _buildPlanIA(),
        ])),
      ]),
    );
  }

  // -- TÂCHES --
  Widget _buildTaches() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
    children: [
      // Critiques d'abord
      ..._taches.where((t) => t['priorite'] == 'critique')
          .map((t) => _tacheCard(t)),
      ..._taches.where((t) => t['priorite'] == 'haute')
          .map((t) => _tacheCard(t)),
      ..._taches.where((t) => t['priorite'] == 'normale')
          .map((t) => _tacheCard(t)),
      ..._taches.where((t) => t['priorite'] == 'faible')
          .map((t) => _tacheCard(t)),
    ],
  );

  Widget _tacheCard(Map t) {
    final priorite = t['priorite'] as String;
    final statut = t['statut'] as String;
    final pColor = _prioriteColor(priorite);
    final sColor = _statutColor(statut);

    return Dismissible(
      key: Key(t['id']?.toString() ?? t['titre']?.toString() ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              color: kGreen, borderRadius: BorderRadius.circular(14)),
          child: const Align(alignment: Alignment.centerRight,
              child: Padding(padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.check_rounded,
                      color: Colors.white, size: 24)))),
      onDismissed: (_) async {
        final id = t['id']?.toString() ?? '';
        if (id.isNotEmpty) await ApiService.terminerTache(id);
        await _load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tâche terminée !'),
                backgroundColor: kGreen,
                behavior: SnackBarBehavior.floating));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: pColor, width: 4)),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha:0.04), blurRadius: 8)]),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 6),
          leading: Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: pColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(_typeIcon(t['type'] as String),
                  color: pColor, size: 20)),
          title: Text(t['titre'] as String, style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13,
              decoration: statut == 'termine'
                  ? TextDecoration.lineThrough : null,
              color: statut == 'termine'
                  ? Colors.grey : const Color(0xFF1E293B))),
          subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${t['description'] ?? ''} • ${t['date_echeance'] ?? ''}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              _chip2(priorite, pColor),
              const SizedBox(width: 6),
              _chip2(statut.replaceAll('_', ' '), sColor),
              const Spacer(),
              Text('${((t['cout'] as num? ?? 0) / 1000).toStringAsFixed(0)}K FCFA'),
            ]),
          ]),
        ),
      ),
    );
  }

  // -- ÉQUIPEMENTS --
  Widget _buildEquipements() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
    children: [
      // Résumé état
      _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📊 État des équipements', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14,
            color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        Row(children: [
          _etatStat(kGreen, 'Bon',
              _equipements.where((e) => e['etat'] == 'bon').length),
          const SizedBox(width: 8),
          _etatStat(kOrange, 'Attention',
              _equipements.where((e) => e['etat'] == 'attention').length),
          const SizedBox(width: 8),
          _etatStat(kRed, 'Critique',
              _equipements.where((e) => e['etat'] == 'critique').length),
        ]),
      ])),
      const SizedBox(height: 12),

      ..._equipements.map((e) => _equipementCard(e)),
    ],
  );

  IconData _equipementIcon(String? type) {
    switch (type ?? '') {
      case 'ventilation': return Icons.air_rounded;
      case 'abreuvement': return Icons.water_drop_rounded;
      case 'chauffage': return Icons.whatshot_rounded;
      case 'alimentation': return Icons.restaurant_rounded;
      case 'eclairage': return Icons.lightbulb_rounded;
      case 'electricite': return Icons.electrical_services_rounded;
      default: return Icons.settings_rounded;
    }
  }

  Widget _equipementCard(Map e) {
    final etat = (e['etat'] as String? ?? 'bon');
    final color = _etatColor(etat);
    final heures = (e['heures_utilisation'] as num? ?? 0).toInt();
    final batiment = e['batiment_nom'] as String? ?? e['ferme_nom'] as String? ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha:0.04), blurRadius: 8)]),
      child: Column(children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(_equipementIcon(e['type'] as String?),
                  color: color, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e['nom'] as String? ?? '', style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 13,
                color: Color(0xFF1E293B))),
            Text(batiment, style: const TextStyle(
                color: Colors.grey, fontSize: 11)),
          ])),
          Container(padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(etat, style: TextStyle(
                  color: color, fontSize: 10,
                  fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 12),

        // Heures d'utilisation
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Heures d\'utilisation: $heures h',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11)),
                Text(etat == 'critique' ? '⚠️ Maintenance urgente'
                    : etat == 'attention' ? '🟠 À surveiller'
                    : '✅ OK',
                    style: TextStyle(color: color, fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ]),
          const SizedBox(height: 4),
          ClipRRect(borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                  value: (heures / 4000).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                      heures > 3000 ? kRed
                          : heures > 2000 ? kOrange : kGreen),
                  minHeight: 5)),
        ]),
        const SizedBox(height: 8),

        Row(children: [
          _infoChip('📅 Dernière: ${e['derniere_maintenance'] ?? '-'}'),
          const SizedBox(width: 8),
          _infoChip('⏰ Prochaine: ${e['prochaine_maintenance'] ?? '-'}'),
        ]),
      ]),
    );
  }

  // -- PLAN IA --
  Widget _buildPlanIA() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          const Icon(Icons.build_rounded, color: Colors.white, size: 36),
          const SizedBox(height: 8),
          const Text('Plan de Maintenance IA', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900,
              fontSize: 16)),
          const Text('Planification optimisée par Claude AI',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                  onPressed: _loadingIA ? null : _genererPlanMaintenance,
                  icon: _loadingIA
                      ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: kOrange, strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(_loadingIA
                      ? 'Génération...' : 'Générer le plan',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: kOrange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0))),
        ]),
      ),
      const SizedBox(height: 16),

      if (_planIA != null) _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.auto_awesome_rounded, color: kOrange, size: 18),
          SizedBox(width: 8),
          Text('Plan de Maintenance', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14,
              color: Color(0xFF1E293B))),
        ]),
        const Divider(),
        const SizedBox(height: 8),
        Text(_planIA!, style: const TextStyle(
            fontSize: 13, color: Color(0xFF1E293B), height: 1.6)),
      ])),
      const SizedBox(height: 16),

      // Résumé budget
      _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('💰 Budget Maintenance', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14,
            color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        ..._taches.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(child: Text(t['titre'] as String,
                style: const TextStyle(fontSize: 12))),
            Text('${((t['cout'] as num? ?? 0) / 1000).toStringAsFixed(0)}K FCFA'),
          ]),
        )),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('TOTAL', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 13)),
          Text('${(0 / 1000).toStringAsFixed(0)}K FCFA',
              style: const TextStyle(color: kOrange,
                  fontWeight: FontWeight.w900, fontSize: 14)),
        ]),
      ])),
    ]),
  );

  // -- MODAL AJOUTER TÂCHE --
  void _showAjouterTache() {
    final titreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final coutCtrl = TextEditingController();
    String priorite = 'normale';
    String type = 'equipement';
    String batiment = 'Bâtiment A';

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModal) => Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20, right: 20, top: 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Nouvelle Tâche', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B))),
              const SizedBox(height: 16),
              _fieldInput(titreCtrl, 'Titre *', Icons.build_rounded),
              const SizedBox(height: 10),
              _fieldInput(descCtrl, 'Description',
                  Icons.notes_rounded),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(
                    value: priorite,
                    decoration: _dropDeco('Priorité'),
                    items: ['faible', 'normale', 'haute', 'critique']
                        .map((p) => DropdownMenuItem(
                        value: p, child: Text(p))).toList(),
                    onChanged: (v) => setModal(() => priorite = v!))),
                const SizedBox(width: 10),
                Expanded(child: DropdownButtonFormField<String>(
                    value: batiment,
                    decoration: _dropDeco('Bâtiment'),
                    items: ['Bâtiment A', 'Bâtiment B',
                      'Bâtiment C', 'Tous']
                        .map((b) => DropdownMenuItem(
                        value: b, child: Text(b))).toList(),
                    onChanged: (v) => setModal(
                            () => batiment = v!))),
              ]),
              const SizedBox(height: 10),
              _fieldInput(coutCtrl, 'Coût estimé (FCFA)',
                  Icons.attach_money_rounded, isNumber: true),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 48,
                  child: ElevatedButton(
                      onPressed: () async {
                        if (titreCtrl.text.isEmpty) return;
                        Navigator.pop(context);
                        await ApiService.createTache({
                          'titre': titreCtrl.text,
                          'description': '[$batiment] ${descCtrl.text}',
                          'type': type,
                          'priorite': priorite,
                          'statut': 'en_cours',
                          'date_echeance': null,
                        });
                        await _load();
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tâche ajoutée !'),
                                backgroundColor: kGreen,
                                behavior: SnackBarBehavior.floating));
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0),
                      child: const Text('Ajouter la tâche',
                          style: TextStyle(
                              fontWeight: FontWeight.w700)))),
            ]),
          )),
    );
  }

  // -- HELPERS --
  IconData _typeIcon(String type) {
    switch (type) {
      case 'ventilation': return Icons.air_rounded;
      case 'hygiene': return Icons.cleaning_services_rounded;
      case 'electricite': return Icons.electrical_services_rounded;
      case 'structure': return Icons.home_repair_service_rounded;
      default: return Icons.build_rounded;
    }
  }

  Widget _etatStat(Color color, String label, int count) =>
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: color.withValues(alpha:0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha:0.2))),
        child: Column(children: [
          Text('$count', style: TextStyle(
              fontWeight: FontWeight.w900, fontSize: 20, color: color)),
          Text(label, style: TextStyle(
              color: color, fontSize: 10)),
        ]),
      ));

  Widget _chip2(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(
          color: color, fontSize: 9, fontWeight: FontWeight.w700)));

  Widget _infoChip(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(
          color: Colors.grey, fontSize: 9)));

  Widget _headerStat(String value, String label, Color color) =>
      Expanded(child: Column(children: [
        Text(value, style: TextStyle(
            color: color, fontSize: 13, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center),
        Text(label, style: const TextStyle(
            color: Colors.white38, fontSize: 8),
            textAlign: TextAlign.center),
      ]));

  Widget _card({required Widget child}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha:0.04), blurRadius: 8)]),
      child: child);

  Widget _fieldInput(TextEditingController ctrl, String label,
      IconData icon, {bool isNumber = false}) =>
      TextField(controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: kBlueLight, size: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true, fillColor: const Color(0xFFF8FAFC)));

  InputDecoration _dropDeco(String label) => InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true, fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 8));
}