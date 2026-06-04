import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';

class TerrainScreen extends StatefulWidget {
  const TerrainScreen({super.key});
  @override
  State<TerrainScreen> createState() => _TerrainScreenState();
}

class _TerrainScreenState extends State<TerrainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List _cycles = [];
  List _donnees = [];
  List _batiments = [];
  bool _loading = true;
  bool _loadingIA = false;
  String? _analyseIA;

  // Données bâtiments simulées (à connecter à ton API)
  final List<Map<String, dynamic>> _batimentsData = [
    {
      'nom': 'Bâtiment A', 'capacite': 1000, 'occupe': 850,
      'temperature': 29.5, 'humidite': 68.0, 'statut': 'actif',
      'dernierNettoyage': '2026-05-20',
    },
    {
      'nom': 'Bâtiment B', 'capacite': 800, 'occupe': 0,
      'temperature': 28.0, 'humidite': 65.0, 'statut': 'vide',
      'dernierNettoyage': '2026-05-18',
    },
    {
      'nom': 'Bâtiment C', 'capacite': 1200, 'occupe': 1200,
      'temperature': 32.5, 'humidite': 75.0, 'statut': 'plein',
      'dernierNettoyage': '2026-05-15',
    },
  ];

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
    final cycles = await ApiService.getCycles();
    final donnees = await ApiService.getDonnees();
    setState(() {
      _cycles = cycles is List ? cycles : [];
      _donnees = donnees is List ? donnees : [];
      _loading = false;
    });
  }

  Future<void> _analyserTerrain() async {
    setState(() { _loadingIA = true; _analyseIA = null; });
    try {
      final totalSujets = _cycles.fold<int>(0, (s, c) =>
      s + ((c['nombre_sujets'] ?? 0) as num).toInt());
      final totalMorts = _donnees.fold<int>(0, (s, d) =>
      s + ((d['mortalite'] ?? 0) as num).toInt());
      final avgTemp = _donnees.isEmpty ? 0.0 : _donnees.fold<double>(0, (s, d) =>
      s + ((d['temperature'] ?? 0) as num).toDouble()) / _donnees.length;

      final prompt = '''Tu es un expert en gestion de fermes avicoles au Sénégal.
Analyse l'état du terrain et des bâtiments et donne des recommandations.

DONNÉES TERRAIN:
- Nombre de bâtiments: ${_batimentsData.length}
- Bâtiment A: ${_batimentsData[0]['occupe']}/${_batimentsData[0]['capacite']} sujets, Temp: ${_batimentsData[0]['temperature']}°C, Humidité: ${_batimentsData[0]['humidite']}%
- Bâtiment B: ${_batimentsData[1]['occupe']}/${_batimentsData[1]['capacite']} sujets (vide)
- Bâtiment C: ${_batimentsData[2]['occupe']}/${_batimentsData[2]['capacite']} sujets, Temp: ${_batimentsData[2]['temperature']}°C

DONNÉES CYCLES:
- Total sujets: $totalSujets
- Mortalité totale: $totalMorts
- Température moyenne: ${avgTemp.toStringAsFixed(1)}°C

Donne une analyse en 4-5 phrases incluant:
1. État général des bâtiments
2. Risques identifiés
3. Recommandations d\'optimisation
4. Actions prioritaires
En français, sois précis et pratique.''';

      final reponse = await ApiService.callIA(prompt,
          contexte: 'Expert bâtiments avicoles Sénégal. Analyse concise et recommandations.');
      setState(() => _analyseIA = reponse.isEmpty ? 'Analyse indisponible.' : reponse);
    } catch (e) {
      setState(() => _analyseIA = 'Analyse indisponible.');
    }
    setState(() => _loadingIA = false);
  }

  @override
  Widget build(BuildContext context) {
    final totalCapacite = _batimentsData.fold<int>(0, (s, b) =>
    s + (b['capacite'] as int));
    final totalOccupe = _batimentsData.fold<int>(0, (s, b) =>
    s + (b['occupe'] as int));
    final tauxOccupation = totalCapacite > 0
        ? (totalOccupe / totalCapacite * 100) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(children: [
        // Header
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF166534)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.terrain_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Suivi Terrain', style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text('Gestion des bâtiments', style: TextStyle(
                    color: Colors.white54, fontSize: 11)),
              ])),
              IconButton(icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white54, size: 20), onPressed: _load),
            ]),
            const SizedBox(height: 12),
            // Stats
            Row(children: [
              _headerStat('${_batimentsData.length}', 'Bâtiments',
                  Colors.white),
              _headerStat('$totalOccupe', 'Sujets',
                  Colors.greenAccent),
              _headerStat('${tauxOccupation.toStringAsFixed(0)}%',
                  'Occupation', Colors.amber),
              _headerStat('${_batimentsData.where((b) => b['statut'] == 'actif').length}',
                  'Actifs', Colors.lightBlueAccent),
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
                Tab(text: '🏗️ Bâtiments'),
                Tab(text: '📊 Surveillance'),
                Tab(text: '🤖 Analyse IA'),
              ],
            ),
          ]),
        ),

        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlue))
            : TabBarView(controller: _tabCtrl, children: [
          _buildBatiments(),
          _buildSurveillance(),
          _buildAnalyseIA(),
        ])),
      ]),
    );
  }

  // ── BÂTIMENTS ──
  Widget _buildBatiments() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      ..._batimentsData.map((b) => _batimentCard(b)),
      const SizedBox(height: 12),
      // Ajouter bâtiment
      GestureDetector(
        onTap: () => _showAjouterBatiment(),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kGreen.withOpacity(0.3), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_circle_rounded, color: kGreen, size: 20),
            const SizedBox(width: 8),
            const Text('Ajouter un bâtiment', style: TextStyle(
                color: kGreen, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
      ),
    ],
  );

  Widget _batimentCard(Map<String, dynamic> b) {
    final statut = b['statut'] as String;
    final capacite = b['capacite'] as int;
    final occupe = b['occupe'] as int;
    final temp = b['temperature'] as double;
    final hum = b['humidite'] as double;
    final pct = capacite > 0 ? occupe / capacite : 0.0;
    final color = statut == 'actif' ? kGreen
        : statut == 'plein' ? kRed : Colors.grey;
    final tempColor = temp > 33 ? kRed : temp > 30 ? kOrange : kGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.home_work_rounded, color: color, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b['nom'] as String, style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B))),
            Text('Dernier nettoyage: ${b['dernierNettoyage']}',
                style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(statut, style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 12),

        // Occupation
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Occupation: $occupe/$capacite sujets',
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
          Text('${(pct * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 12)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                    pct > 0.9 ? kRed : pct > 0.7 ? kOrange : kGreen),
                minHeight: 6)),
        const SizedBox(height: 12),

        // Conditions
        Row(children: [
          _conditionChip(Icons.thermostat_rounded, '${temp.toStringAsFixed(1)}°C', tempColor),
          const SizedBox(width: 8),
          _conditionChip(Icons.water_drop_rounded, '${hum.toStringAsFixed(0)}%',
              hum > 70 ? kOrange : kBlue),
          const Spacer(),
          // Actions
          IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.grey, size: 18),
              onPressed: () => _showEditerBatiment(b)),
          IconButton(
              icon: const Icon(Icons.sensors_rounded, color: kBlue, size: 18),
              onPressed: () => _showMetriques(b)),
        ]),
      ]),
    );
  }

  Widget _conditionChip(IconData icon, String value, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]));

  // ── SURVEILLANCE ──
  Widget _buildSurveillance() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // Résumé surveillance
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🌡️ Conditions Actuelles', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
        const SizedBox(height: 14),
        ..._batimentsData.map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b['nom'] as String, style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: _metriqueBar(
                  '🌡️ Température', b['temperature'] as double,
                  15, 45, 25, 32, '°C')),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: _metriqueBar(
                  '💧 Humidité', b['humidite'] as double,
                  0, 100, 50, 70, '%')),
            ]),
          ]),
        )),
      ])),
      const SizedBox(height: 12),

      // Alertes bâtiments
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🚨 Alertes Terrain', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        ..._genererAlertesTerrain(),
      ])),
      const SizedBox(height: 12),

      // Planning nettoyage
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🧹 Planning Nettoyage', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        ..._batimentsData.map((b) => ListTile(
          dense: true,
          leading: const Icon(Icons.cleaning_services_rounded, color: kBlue, size: 20),
          title: Text(b['nom'] as String,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          subtitle: Text('Dernier: ${b['dernierNettoyage']}',
              style: const TextStyle(fontSize: 11)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: kBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Text('Planifier', style: TextStyle(
                color: kBlue, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        )),
      ])),
    ],
  );

  List<Widget> _genererAlertesTerrain() {
    List<Widget> alertes = [];
    for (final b in _batimentsData) {
      final temp = b['temperature'] as double;
      final hum = b['humidite'] as double;
      final pct = (b['occupe'] as int) / (b['capacite'] as int);
      if (temp > 33) alertes.add(_alerteTerrain(
          '🌡️ ${b['nom']}: Température élevée (${temp.toStringAsFixed(1)}°C)', kRed));
      if (hum > 75) alertes.add(_alerteTerrain(
          '💧 ${b['nom']}: Humidité élevée (${hum.toStringAsFixed(0)}%)', kOrange));
      if (pct > 0.95) alertes.add(_alerteTerrain(
          '📦 ${b['nom']}: Surpeuplement (${(pct*100).toStringAsFixed(0)}%)', kRed));
    }
    if (alertes.isEmpty) alertes.add(
        const ListTile(dense: true,
            leading: Icon(Icons.check_circle_rounded, color: kGreen),
            title: Text('Aucune alerte terrain', style: TextStyle(fontSize: 13))));
    return alertes;
  }

  Widget _alerteTerrain(String msg, Color color) => Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Icon(Icons.warning_rounded, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600))),
      ]));

  Widget _metriqueBar(String label, double value, double min, double max,
      double seuilBas, double seuilHaut, String unite) {
    final pct = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final color = value > seuilHaut ? kRed : value < seuilBas ? kBlue : kGreen;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text('${value.toStringAsFixed(1)}$unite',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
      ]),
      const SizedBox(height: 3),
      ClipRRect(borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
              value: pct, backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color), minHeight: 4)),
    ]);
  }

  // ── ANALYSE IA ──
  Widget _buildAnalyseIA() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      // Bouton analyser
      Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF166534)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          const Icon(Icons.terrain_rounded, color: Colors.white, size: 36),
          const SizedBox(height: 8),
          const Text('Analyse IA du Terrain', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          const Text('Optimisation bâtiments & conditions',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                  onPressed: _loadingIA ? null : _analyserTerrain,
                  icon: _loadingIA
                      ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: Color(0xFF166534), strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(_loadingIA ? 'Analyse en cours...' : 'Analyser le terrain',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF166534),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0))),
        ]),
      ),
      const SizedBox(height: 16),

      // Résultat
      if (_analyseIA != null) Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.auto_awesome_rounded, color: kGreen, size: 18),
            SizedBox(width: 8),
            Text('Analyse du Terrain', style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
          ]),
          const Divider(),
          const SizedBox(height: 8),
          Text(_analyseIA!, style: const TextStyle(
              fontSize: 13, color: Color(0xFF1E293B), height: 1.6)),
        ]),
      ),

      // Résumé bâtiments
      const SizedBox(height: 16),
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📊 Résumé Bâtiments', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        ..._batimentsData.map((b) {
          final pct = (b['occupe'] as int) / (b['capacite'] as int);
          final color = pct > 0.9 ? kRed : pct > 0.7 ? kOrange : kGreen;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(b['nom'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              Text('${(pct * 100).toStringAsFixed(0)}% occupé',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          );
        }),
      ])),
    ]),
  );

  // ── MODALS ──
  void _showAjouterBatiment() {
    final nomCtrl = TextEditingController();
    final capaciteCtrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20, right: 20, top: 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Nouveau Bâtiment', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              const SizedBox(height: 16),
              TextField(controller: nomCtrl,
                  decoration: InputDecoration(labelText: 'Nom du bâtiment',
                      prefixIcon: const Icon(Icons.home_work_rounded, color: kBlueLight),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true, fillColor: const Color(0xFFF8FAFC))),
              const SizedBox(height: 12),
              TextField(controller: capaciteCtrl, keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Capacité (nombre de sujets)',
                      prefixIcon: const Icon(Icons.pets_rounded, color: kBlueLight),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true, fillColor: const Color(0xFFF8FAFC))),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 48,
                  child: ElevatedButton(
                      onPressed: () {
                        if (nomCtrl.text.isNotEmpty) {
                          setState(() => _batimentsData.add({
                            'nom': nomCtrl.text,
                            'capacite': int.tryParse(capaciteCtrl.text) ?? 0,
                            'occupe': 0, 'temperature': 28.0, 'humidite': 65.0,
                            'statut': 'vide',
                            'dernierNettoyage': DateTime.now().toString().split(' ')[0],
                          }));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('✅ Bâtiment ajouté !'),
                              backgroundColor: kGreen,
                              behavior: SnackBarBehavior.floating));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)), elevation: 0),
                      child: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.w700)))),
            ])));
  }

  void _showEditerBatiment(Map<String, dynamic> b) {
    final tempCtrl = TextEditingController(text: b['temperature'].toString());
    final humCtrl = TextEditingController(text: b['humidite'].toString());
    showModalBottomSheet(context: context, isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20, right: 20, top: 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Mettre à jour ${b['nom']}', style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextField(controller: tempCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Température (°C)',
                        prefixIcon: const Icon(Icons.thermostat_rounded, color: kOrange),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true, fillColor: const Color(0xFFF8FAFC)))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: humCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Humidité (%)',
                        prefixIcon: const Icon(Icons.water_drop_rounded, color: kBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true, fillColor: const Color(0xFFF8FAFC)))),
              ]),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 48,
                  child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          b['temperature'] = double.tryParse(tempCtrl.text) ?? b['temperature'];
                          b['humidite'] = double.tryParse(humCtrl.text) ?? b['humidite'];
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)), elevation: 0),
                      child: const Text('Mettre à jour',
                          style: TextStyle(fontWeight: FontWeight.w700)))),
            ])));
  }

  void _showMetriques(Map<String, dynamic> b) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(b['nom'] as String),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _metriqueDialog('🌡️ Température', '${b['temperature']}°C',
            b['temperature'] > 32 ? kRed : kGreen),
        _metriqueDialog('💧 Humidité', '${b['humidite']}%',
            b['humidite'] > 70 ? kOrange : kBlue),
        _metriqueDialog('🐔 Occupation',
            '${b['occupe']}/${b['capacite']} sujets', kBlue),
        _metriqueDialog('📅 Dernier nettoyage',
            b['dernierNettoyage'] as String, Colors.grey),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Fermer')),
      ],
    ));
  }

  Widget _metriqueDialog(String label, String value, Color color) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(value, style: TextStyle(
            fontWeight: FontWeight.w700, color: color, fontSize: 13)),
      ]));

  Widget _headerStat(String value, String label, Color color) =>
      Expanded(child: Column(children: [
        Text(value, style: TextStyle(
            color: color, fontSize: 16, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
      ]));

  Widget _card({required Widget child}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: child);
}