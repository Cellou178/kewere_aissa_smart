import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});
  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List _cycles = [];
  List _donnees = [];
  String? _selectedCycleId;
  bool _loading = true;
  bool _loadingIA = false;
  Map<String, dynamic> _predictions = {};

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
      if (_cycles.isNotEmpty && _selectedCycleId == null) {
        _selectedCycleId = _cycles.first['id']?.toString();
      }
      _loading = false;
    });
    _analyser();
  }

  List get _donneesFiltered => (_selectedCycleId == null ? _donnees :
  _donnees.where((d) => d['cycle_id']?.toString() == _selectedCycleId).toList())
    ..sort((a, b) => (a['date_releve'] ?? '').compareTo(b['date_releve'] ?? ''));

  Map get _cycleSelectionne => _cycles.firstWhere(
          (c) => c['id']?.toString() == _selectedCycleId,
      orElse: () => {});

  Future<void> _analyser() async {
    final data = _donneesFiltered;
    if (data.isEmpty) return;
    setState(() { _loadingIA = true; _predictions = {}; });

    final totalMorts = data.fold<int>(0, (s, d) =>
    s + ((d['mortalite'] ?? 0) as num).toInt());
    final avgTemp = data.fold<double>(0, (s, d) =>
    s + ((d['temperature'] ?? 0) as num).toDouble()) / data.length;
    final avgHum = data.fold<double>(0, (s, d) =>
    s + ((d['humidite'] ?? 0) as num).toDouble()) / data.length;
    final totalProd = data.fold<int>(0, (s, d) =>
    s + ((d['production'] ?? 0) as num).toInt());
    final sujets = ((_cycleSelectionne['nombre_sujets'] ?? 0) as num).toInt();
    final tauxMort = sujets > 0 ? (totalMorts / sujets * 100) : 0;

    // Calculer tendances
    final mortalites = data.map((d) => ((d['mortalite'] ?? 0) as num).toDouble()).toList();
    final tendanceMort = mortalites.length > 1
        ? mortalites.last - mortalites.first : 0.0;
    final temps = data.map((d) => ((d['temperature'] ?? 0) as num).toDouble()).toList();
    final dernierTemp = temps.isNotEmpty ? temps.last : 0.0;

    final prompt = '''Tu es un expert en aviculture et data science au Sénégal.
Analyse ces données et génère des prédictions PRÉCISES et CHIFFRÉES.

DONNÉES:
- Cycle: ${_cycleSelectionne['nom'] ?? 'Cycle'}
- Sujets: $sujets poulets
- Relevés: ${data.length}
- Mortalité totale: $totalMorts (${tauxMort.toStringAsFixed(1)}%)
- Tendance mortalité: ${tendanceMort > 0 ? 'En hausse' : 'En baisse'} (${tendanceMort.toStringAsFixed(1)})
- Température moy: ${avgTemp.toStringAsFixed(1)}°C (dernière: ${dernierTemp.toStringAsFixed(1)}°C)
- Humidité moy: ${avgHum.toStringAsFixed(1)}%
- Production totale: $totalProd

Génère UNIQUEMENT ce JSON valide:
{
  "score_sante": <0-100>,
  "statut_sante": "<Excellent|Bon|Attention|Critique>",
  "prediction_mortalite_7j": <entier>,
  "prediction_mortalite_30j": <entier>,
  "prediction_production_fin": <entier>,
  "prediction_poids_moyen": <decimal kg>,
  "date_vente_optimale": "<dans X jours>",
  "revenu_estime": <entier FCFA>,
  "risque_mortalite": "<Faible|Modéré|Élevé|Critique>",
  "risque_maladie": "<Faible|Modéré|Élevé>",
  "tendance_temperature": "<Normale|Trop chaude|Trop froide>",
  "indice_croissance": <0-100>,
  "taux_conversion_estime": <decimal>,
  "recommendations": ["<rec1>", "<rec2>", "<rec3>", "<rec4>"],
  "alertes": ["<alerte1>", "<alerte2>"],
  "actions_immediates": ["<action1>", "<action2>", "<action3>"],
  "analyse_globale": "<3-4 phrases>",
  "facteurs_risque": ["<risque1>", "<risque2>"],
  "points_positifs": ["<positif1>", "<positif2>"]
}
UNIQUEMENT le JSON, rien d\'autre.''';

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 1200,
          'messages': [{'role': 'user', 'content': prompt}],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'] ?? '{}';
        final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
        setState(() { _predictions = jsonDecode(clean); _loadingIA = false; });
      }
    } catch (e) {
      setState(() => _loadingIA = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = (_predictions['score_sante'] ?? 0) as num;
    final scoreColor = score >= 80 ? kGreen : score >= 60 ? kOrange : kRed;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(children: [
        // Header
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A5F), Color(0xFF4C1D95)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            Row(children: [
              const Text('🤖', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Prédictions IA', style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text('Powered by Claude AI', style: TextStyle(
                    color: Colors.white38, fontSize: 10)),
              ])),
              IconButton(icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white54, size: 20), onPressed: _analyser),
            ]),
            const SizedBox(height: 12),

            // Sélecteur cycle
            DropdownButtonFormField<String>(
                value: _selectedCycleId,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                    labelText: 'Cycle',
                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white30)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white30)),
                    filled: true, fillColor: Colors.white.withOpacity(0.08),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: _cycles.map((c) => DropdownMenuItem<String>(
                    value: c['id']?.toString(),
                    child: Text(c['nom']?.toString() ?? '',
                        style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) {
                  setState(() { _selectedCycleId = v; _predictions = {}; });
                  _analyser();
                }),
            const SizedBox(height: 12),

            // Score rapide si disponible
            if (_predictions.isNotEmpty) ...[
              Row(children: [
                _headerStat('${score.toInt()}%', 'Score santé', scoreColor),
                _headerStat(
                    '${_predictions['prediction_mortalite_7j'] ?? '-'}',
                    'Morts/7j', kRed),
                _headerStat(
                    '${_predictions['indice_croissance'] ?? '-'}',
                    'Croissance', kGreen),
                _headerStat(
                    _predictions['risque_mortalite'] ?? '-',
                    'Risque', kOrange),
              ]),
              const SizedBox(height: 12),
            ],

            TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              tabs: const [
                Tab(text: '📊 Prédictions'),
                Tab(text: '⚡ Actions'),
                Tab(text: '🤖 Analyse'),
              ],
            ),
          ]),
        ),

        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlue))
            : _loadingIA ? _loadingWidget()
            : _predictions.isEmpty ? _emptyWidget()
            : TabBarView(controller: _tabCtrl, children: [
          _buildPredictions(),
          _buildActions(),
          _buildAnalyse(),
        ])),
      ]),
    );
  }

  // ── PRÉDICTIONS ──
  Widget _buildPredictions() => RefreshIndicator(
    onRefresh: _analyser, color: kBlue,
    child: ListView(padding: const EdgeInsets.all(16), children: [
      // Score santé
      _scoreCard(),
      const SizedBox(height: 12),

      // KPIs prédictions
      _card(title: '🔮 Prédictions Chiffrées', child: Column(children: [
        Row(children: [
          _predKpi('💀', '${_predictions['prediction_mortalite_7j'] ?? 0}',
              'Morts\n7 jours', kRed),
          const SizedBox(width: 8),
          _predKpi('📅', '${_predictions['prediction_mortalite_30j'] ?? 0}',
              'Morts\n30 jours', kOrange),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _predKpi('📦', '${_predictions['prediction_production_fin'] ?? 0}',
              'Production\nfinale', kGreen),
          const SizedBox(width: 8),
          _predKpi('⚖️', '${_predictions['prediction_poids_moyen'] ?? 0} kg',
              'Poids\nmoyen', kBlue),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _predKpi('💰', _formatFcfa(_predictions['revenu_estime'] ?? 0),
              'Revenu\nestimé', kGreen),
          const SizedBox(width: 8),
          _predKpi('📅', _predictions['date_vente_optimale'] ?? '-',
              'Vente\noptimale', kPurple),
        ]),
      ])),
      const SizedBox(height: 12),

      // Risques
      _card(title: '⚠️ Évaluation des Risques', child: Column(children: [
        _risqueBar('Mortalité', _predictions['risque_mortalite'] ?? 'Faible'),
        const SizedBox(height: 10),
        _risqueBar('Maladie', _predictions['risque_maladie'] ?? 'Faible'),
        const SizedBox(height: 12),
        Row(children: [
          _indicateur('🌡️ Température',
              _predictions['tendance_temperature'] ?? '-'),
          const SizedBox(width: 8),
          _indicateur('📈 Croissance',
              '${_predictions['indice_croissance'] ?? 0}/100'),
        ]),
      ])),
      const SizedBox(height: 12),

      // Points positifs
      if ((_predictions['points_positifs'] as List?)?.isNotEmpty == true)
        _card(title: '✅ Points Positifs', child: Column(
            children: ((_predictions['points_positifs'] as List?) ?? [])
                .map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, color: kGreen, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p.toString(), style: const TextStyle(
                      fontSize: 12, color: Color(0xFF1E293B)))),
                ])))
                .toList())),

      const SizedBox(height: 12),

      // Facteurs de risque
      if ((_predictions['facteurs_risque'] as List?)?.isNotEmpty == true)
        _card(title: '🔴 Facteurs de Risque', child: Column(
            children: ((_predictions['facteurs_risque'] as List?) ?? [])
                .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  const Icon(Icons.warning_rounded, color: kRed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r.toString(), style: const TextStyle(
                      fontSize: 12, color: Color(0xFF1E293B)))),
                ])))
                .toList())),
    ]),
  );

  // ── ACTIONS ──
  Widget _buildActions() => RefreshIndicator(
    onRefresh: _analyser, color: kBlue,
    child: ListView(padding: const EdgeInsets.all(16), children: [
      // Alertes urgentes
      if ((_predictions['alertes'] as List?)?.isNotEmpty == true) ...[
        _card(title: '🚨 Alertes', child: Column(
            children: ((_predictions['alertes'] as List?) ?? [])
                .map((a) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: kRed.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kRed.withOpacity(0.2))),
                child: Row(children: [
                  const Icon(Icons.dangerous_rounded, color: kRed, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(a.toString(), style: const TextStyle(
                      fontSize: 12, color: Color(0xFF1E293B)))),
                ])))
                .toList())),
        const SizedBox(height: 12),
      ],

      // Actions immédiates
      _card(title: '⚡ Actions Immédiates', child: Column(
          children: ((_predictions['actions_immediates'] as List?) ?? [])
              .asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: kGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kGreen.withOpacity(0.2))),
              child: Row(children: [
                Container(width: 26, height: 26,
                    decoration: BoxDecoration(
                        color: kGreen, borderRadius: BorderRadius.circular(13)),
                    child: Center(child: Text('${e.key + 1}',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 11, fontWeight: FontWeight.w800)))),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value.toString(), style: const TextStyle(
                    fontSize: 12, color: Color(0xFF1E293B)))),
              ])))
              .toList())),
      const SizedBox(height: 12),

      // Recommandations
      _card(title: '💡 Recommandations', child: Column(
          children: ((_predictions['recommendations'] as List?) ?? [])
              .asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 24, height: 24,
                        decoration: BoxDecoration(
                            color: kBlue.withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: Center(child: Text('${e.key + 1}',
                            style: const TextStyle(color: kBlue,
                                fontSize: 11, fontWeight: FontWeight.w800)))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.value.toString(), style: const TextStyle(
                        fontSize: 12, color: Color(0xFF1E293B), height: 1.4))),
                  ])))
              .toList())),
    ]),
  );

  // ── ANALYSE ──
  Widget _buildAnalyse() => RefreshIndicator(
    onRefresh: _analyser, color: kBlue,
    child: ListView(padding: const EdgeInsets.all(16), children: [
      // Analyse globale
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A5F), Color(0xFF4C1D95)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.all(Radius.circular(20))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Text('🤖', style: TextStyle(fontSize: 24)),
            SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Analyse Globale', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
              Text('Claude AI', style: TextStyle(
                  color: Colors.white38, fontSize: 10)),
            ]),
          ]),
          const SizedBox(height: 14),
          Text(_predictions['analyse_globale'] ?? '',
              style: TextStyle(color: Colors.white.withOpacity(0.87),
                  fontSize: 13, height: 1.6)),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity,
              child: OutlinedButton.icon(
                  onPressed: _analyser,
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.white60, size: 16),
                  label: const Text('Relancer l\'analyse',
                      style: TextStyle(color: Colors.white60)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))))),
        ]),
      ),
      const SizedBox(height: 12),

      // Résumé cycle
      _card(title: '📋 Résumé du Cycle', child: Column(children: [
        _resumeRow('Cycle', _cycleSelectionne['nom'] ?? '-'),
        _resumeRow('Sujets', '${_cycleSelectionne['nombre_sujets'] ?? 0}'),
        _resumeRow('Relevés', '${_donneesFiltered.length}'),
        _resumeRow('Statut santé', _predictions['statut_sante'] ?? '-'),
        _resumeRow('Score', '${_predictions['score_sante'] ?? 0}/100'),
        _resumeRow('Taux conversion', '${_predictions['taux_conversion_estime'] ?? '-'}'),
      ])),
    ]),
  );

  // ── HELPERS ──
  Widget _scoreCard() {
    final score = (_predictions['score_sante'] ?? 0) as num;
    final statut = _predictions['statut_sante'] ?? 'Inconnu';
    final color = score >= 80 ? kGreen : score >= 60 ? kOrange : kRed;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3),
              blurRadius: 16, offset: const Offset(0, 6))]),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Score de Santé', style: TextStyle(
              color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text('$score/100', style: const TextStyle(
              color: Colors.white, fontSize: 32,
              fontWeight: FontWeight.w900)),
          Container(padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(statut, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700,
                  fontSize: 12))),
        ]),
        const Spacer(),
        SizedBox(width: 76, height: 76,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                  value: (score / 100).toDouble(), strokeWidth: 7,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white)),
              Text('${score.toInt()}%', style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900,
                  fontSize: 14)),
            ])),
      ]),
    );
  }

  Widget _risqueBar(String label, String niveau) {
    final levels = ['Faible', 'Modéré', 'Élevé', 'Critique'];
    final idx = levels.indexOf(niveau);
    final color = idx <= 0 ? kGreen : idx == 1 ? kOrange : kRed;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 12)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text(niveau, style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w700))),
      ]),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
              value: idx < 0 ? 0.1 : (idx + 1) / 4,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5)),
    ]);
  }

  Widget _indicateur(String label, String value) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: kBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBlue.withOpacity(0.15))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          Text(value, style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 13,
              color: Color(0xFF1E293B))),
        ]),
      ));

  Widget _resumeRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 12,
            color: Color(0xFF1E293B))),
      ]));

  String _formatFcfa(dynamic v) {
    final val = (v as num).toDouble();
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M FCFA';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(0)}K FCFA';
    return '${val.toStringAsFixed(0)} FCFA';
  }

  Widget _loadingWidget() => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: kPurple.withOpacity(0.1), shape: BoxShape.circle),
        child: const Text('🤖', style: TextStyle(fontSize: 48))),
    const SizedBox(height: 20),
    const Text('Analyse IA en cours...', style: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
    const SizedBox(height: 8),
    const Text('Claude analyse vos données d\'élevage',
        style: TextStyle(color: Colors.grey, fontSize: 13)),
    const SizedBox(height: 24),
    const CircularProgressIndicator(color: kPurple),
  ]));

  Widget _emptyWidget() => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.psychology_rounded, size: 56, color: Colors.grey),
    const SizedBox(height: 16),
    const Text('Aucune donnée disponible', style: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    const Text('Ajoutez des données pour obtenir des prédictions',
        style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
    const SizedBox(height: 24),
    ElevatedButton.icon(
        onPressed: _analyser,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Réessayer'),
        style: ElevatedButton.styleFrom(
            backgroundColor: kBlue, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
  ]));

  Widget _headerStat(String value, String label, Color color) =>
      Expanded(child: Column(children: [
        Text(value, style: TextStyle(
            color: color, fontSize: 13, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(
            color: Colors.white38, fontSize: 8), textAlign: TextAlign.center),
      ]));

  Widget _card({required String title, required Widget child}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        child,
      ]));

  Widget _predKpi(String emoji, String value, String label, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: TextStyle(
              fontSize: 9, color: color.withOpacity(0.7), height: 1.3)),
        ]),
      ));
}