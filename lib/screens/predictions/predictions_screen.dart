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

class _PredictionsScreenState extends State<PredictionsScreen> {
  List _cycles = [];
  List _donnees = [];
  String? _selectedCycleId;
  bool _loading = true;
  bool _loadingIA = false;
  Map<String, dynamic> _predictions = {};

  @override
  void initState() { super.initState(); _load(); }

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

  List get _donneesFiltered => _selectedCycleId == null ? _donnees :
  _donnees.where((d) => d['cycle_id']?.toString() == _selectedCycleId).toList()
    ..sort((a, b) => (a['date_releve'] ?? '').compareTo(b['date_releve'] ?? ''));

  Map get _cycleSelectionne => _cycles.firstWhere(
          (c) => c['id']?.toString() == _selectedCycleId,
      orElse: () => {});

  Future<void> _analyser() async {
    final data = _donneesFiltered;
    if (data.isEmpty) return;
    setState(() { _loadingIA = true; _predictions = {}; });

    final totalMorts = data.fold<int>(0, (s, d) => s + ((d['mortalite'] ?? 0) as num).toInt());
    final avgTemp = data.fold<double>(0, (s, d) => s + ((d['temperature'] ?? 0) as num).toDouble()) / data.length;
    final avgHum = data.fold<double>(0, (s, d) => s + ((d['humidite'] ?? 0) as num).toDouble()) / data.length;
    final totalProd = data.fold<int>(0, (s, d) => s + ((d['production'] ?? 0) as num).toInt());
    final sujets = ((_cycleSelectionne['nombre_sujets'] ?? 0) as num).toInt();
    final tauxMort = sujets > 0 ? (totalMorts / sujets * 100) : 0;

    final prompt = '''Tu es un expert en aviculture et data science au Sénégal.
Analyse ces données d'un élevage de poulets de chair et génère des prédictions précises.

DONNÉES DU CYCLE:
- Nom: ${_cycleSelectionne['nom'] ?? 'Cycle'}
- Nombre de sujets: $sujets
- Nombre de relevés: ${data.length}
- Mortalité totale: $totalMorts (${tauxMort.toStringAsFixed(1)}%)
- Température moyenne: ${avgTemp.toStringAsFixed(1)}°C
- Humidité moyenne: ${avgHum.toStringAsFixed(1)}%
- Production totale: $totalProd

Génère une réponse UNIQUEMENT en JSON valide avec cette structure exacte:
{
  "score_sante": <nombre 0-100>,
  "statut_sante": "<Excellent|Bon|Attention|Critique>",
  "prediction_mortalite_7j": <nombre entier>,
  "prediction_production_fin": <nombre entier>,
  "risque_mortalite": "<Faible|Modéré|Élevé|Critique>",
  "tendance_temperature": "<Normale|Trop chaude|Trop froide>",
  "recommendations": ["<rec1>", "<rec2>", "<rec3>"],
  "alertes": ["<alerte1>", "<alerte2>"],
  "analyse_globale": "<analyse en 2-3 phrases>",
  "actions_immediates": ["<action1>", "<action2>"]
}
Réponds UNIQUEMENT avec le JSON, sans texte avant ou après.''';

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 1000,
          'messages': [{'role': 'user', 'content': prompt}],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'] ?? '{}';
        final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
        final predictions = jsonDecode(clean);
        setState(() { _predictions = predictions; _loadingIA = false; });
      }
    } catch (e) {
      setState(() => _loadingIA = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Text('🤖', style: TextStyle(fontSize: 28)),
              SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Prédictions IA', style: TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                Text('Powered by Claude AI', style: TextStyle(color: Colors.white38, fontSize: 11)),
              ]),
            ]),
            const SizedBox(height: 16),
            // Sélecteur cycle
            DropdownButtonFormField<String>(
                value: _selectedCycleId,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                    labelText: 'Sélectionner un cycle',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white30)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
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
          ]),
        ),

        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlue))
            : _loadingIA
            ? _loadingWidget()
            : _predictions.isEmpty
            ? _emptyWidget()
            : RefreshIndicator(
          onRefresh: _analyser,
          color: kBlue,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _scoreCard(),
              const SizedBox(height: 12),
              _predictionsCard(),
              const SizedBox(height: 12),
              _alertesCard(),
              const SizedBox(height: 12),
              _recommendationsCard(),
              const SizedBox(height: 12),
              _actionsCard(),
              const SizedBox(height: 12),
              _analyseGlobaleCard(),
            ],
          ),
        )),
      ]),
    );
  }

  Widget _loadingWidget() => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: kBlue.withOpacity(0.1), shape: BoxShape.circle),
        child: const Text('🤖', style: TextStyle(fontSize: 48))),
    const SizedBox(height: 20),
    const Text('Analyse IA en cours...', style: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
    const SizedBox(height: 8),
    const Text('Claude analyse vos données d\'élevage',
        style: TextStyle(color: Colors.grey, fontSize: 13)),
    const SizedBox(height: 24),
    const CircularProgressIndicator(color: kBlue),
  ]));

  Widget _emptyWidget() => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('📊', style: TextStyle(fontSize: 48)),
    const SizedBox(height: 16),
    const Text('Aucune donnée disponible',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    const Text('Ajoutez des données journalières pour obtenir des prédictions',
        style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
  ]));

  // Score de santé
  Widget _scoreCard() {
    final score = (_predictions['score_sante'] ?? 0) as num;
    final statut = _predictions['statut_sante'] ?? 'Inconnu';
    final color = score >= 80 ? kGreen : score >= 60 ? kOrange : kRed;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Score de Santé', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text('$score/100', style: const TextStyle(
              color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(statut, style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
        ]),
        const Spacer(),
        SizedBox(width: 80, height: 80,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                  value: score / 100, strokeWidth: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white)),
              Text('${score.toInt()}%', style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
            ])),
      ]),
    );
  }

  // Prédictions chiffrées
  Widget _predictionsCard() {
    final mort7j = _predictions['prediction_mortalite_7j'] ?? 0;
    final prodFin = _predictions['prediction_production_fin'] ?? 0;
    final risque = _predictions['risque_mortalite'] ?? '-';
    final tendTemp = _predictions['tendance_temperature'] ?? '-';
    final risqueColor = risque == 'Faible' ? kGreen : risque == 'Modéré' ? kOrange : kRed;

    return _card(
      title: '🔮 Prédictions',
      child: Column(children: [
        Row(children: [
          _predKpi('💀', '$mort7j', 'Morts prévus\n(7 jours)', kRed),
          const SizedBox(width: 10),
          _predKpi('📦', '$prodFin', 'Production\nestimée finale', kGreen),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _predKpi('⚠️', risque, 'Risque\nmortalité', risqueColor),
          const SizedBox(width: 10),
          _predKpi('🌡️', tendTemp, 'Tendance\ntempérature', kOrange),
        ]),
      ]),
    );
  }

  // Alertes
  Widget _alertesCard() {
    final alertes = (_predictions['alertes'] as List?) ?? [];
    if (alertes.isEmpty) return const SizedBox();
    return _card(
      title: '🚨 Alertes',
      child: Column(children: alertes.map((a) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: kRed.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kRed.withOpacity(0.2))),
        child: Row(children: [
          const Text('🚨', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(child: Text(a.toString(), style: const TextStyle(
              fontSize: 13, color: Color(0xFF1E293B)))),
        ]),
      )).toList()),
    );
  }

  // Recommandations
  Widget _recommendationsCard() {
    final recs = (_predictions['recommendations'] as List?) ?? [];
    return _card(
      title: '💡 Recommandations',
      child: Column(children: recs.asMap().entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 24, height: 24,
              decoration: BoxDecoration(color: kBlue.withOpacity(0.1), shape: BoxShape.circle),
              child: Center(child: Text('${e.key + 1}',
                  style: const TextStyle(color: kBlue, fontSize: 11, fontWeight: FontWeight.w800)))),
          const SizedBox(width: 10),
          Expanded(child: Text(e.value.toString(),
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.4))),
        ]),
      )).toList()),
    );
  }

  // Actions immédiates
  Widget _actionsCard() {
    final actions = (_predictions['actions_immediates'] as List?) ?? [];
    return _card(
      title: '⚡ Actions Immédiates',
      child: Column(children: actions.map((a) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: kGreen.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kGreen.withOpacity(0.2))),
        child: Row(children: [
          const Text('✅', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(child: Text(a.toString(), style: const TextStyle(
              fontSize: 13, color: Color(0xFF1E293B)))),
        ]),
      )).toList()),
    );
  }

  // Analyse globale
  Widget _analyseGlobaleCard() {
    final analyse = _predictions['analyse_globale'] ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('🤖', style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Text('Analyse Globale', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
        ]),
        const SizedBox(height: 10),
        Text(analyse, style: TextStyle(
            color: Colors.white.withOpacity(0.87), fontSize: 13, height: 1.6)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: _analyser,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white60, size: 16),
            label: const Text('Relancer l\'analyse', style: TextStyle(color: Colors.white60)),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
      ]),
    );
  }

  Widget _card({required String title, required Widget child}) => Container(
      padding: const EdgeInsets.all(16),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: TextStyle(
              fontSize: 10, color: color.withOpacity(0.7), height: 1.3)),
        ]),
      ));
}