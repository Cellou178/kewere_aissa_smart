import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';

class GraphiquesScreen extends StatefulWidget {
  const GraphiquesScreen({super.key});
  @override
  State<GraphiquesScreen> createState() => _GraphiquesScreenState();
}

class _GraphiquesScreenState extends State<GraphiquesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List _cycles = [];
  List _donnees = [];
  String? _selectedCycleId;
  bool _loading = true;

  Map<String, String> _interpretations = {};
  Map<String, bool> _loadingIA = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
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
    _analyserTout();
  }

  List _donneesFiltered() {
    final filtered = _selectedCycleId == null ? _donnees :
    _donnees.where((d) => d['cycle_id']?.toString() == _selectedCycleId).toList();
    filtered.sort((a, b) => (a['date_releve'] ?? '').compareTo(b['date_releve'] ?? ''));
    return filtered;
  }

  Future<void> _analyserTout() async {
    final filtered = _donneesFiltered();
    if (filtered.isEmpty) return;
    await Future.wait([
      _analyserGraphique('mortalite', filtered),
      _analyserGraphique('temperature', filtered),
      _analyserGraphique('humidite', filtered),
      _analyserGraphique('production', filtered),
      _analyserGlobal(filtered),
    ]);
  }

  Future<void> _analyserGraphique(String type, List data) async {
    setState(() => _loadingIA[type] = true);
    try {
      final stats = _calculerStats(type, data);
      final prompt = _buildPrompt(type, stats, data);
      final interpretation = await _appellerClaude(prompt);
      setState(() {
        _interpretations[type] = interpretation;
        _loadingIA[type] = false;
      });
    } catch (e) {
      setState(() {
        _interpretations[type] = 'Analyse indisponible.';
        _loadingIA[type] = false;
      });
    }
  }

  Future<void> _analyserGlobal(List data) async {
    setState(() => _loadingIA['global'] = true);
    try {
      final cycleName = _cycles.firstWhere(
              (c) => c['id']?.toString() == _selectedCycleId,
          orElse: () => {'nom': 'Cycle inconnu'})['nom'];
      final totalMorts = data.fold<int>(0, (s, d) => s + ((d['mortalite'] ?? 0) as num).toInt());
      final avgTemp = data.isEmpty ? 0 : data.fold<double>(0, (s, d) => s + ((d['temperature'] ?? 0) as num).toDouble()) / data.length;
      final avgHum = data.isEmpty ? 0 : data.fold<double>(0, (s, d) => s + ((d['humidite'] ?? 0) as num).toDouble()) / data.length;
      final totalProd = data.fold<int>(0, (s, d) => s + ((d['production'] ?? 0) as num).toInt());

      final prompt = '''Tu es un expert en aviculture au Sénégal.
Analyse globalement ce cycle avicole et donne des recommandations précises.

Cycle: $cycleName
Nombre de relevés: ${data.length}
Mortalité totale: $totalMorts
Température moyenne: ${avgTemp.toStringAsFixed(1)}°C
Humidité moyenne: ${avgHum.toStringAsFixed(1)}%
Production totale: $totalProd

Donne une analyse globale en 4-5 phrases avec:
1. État général du cycle
2. Points positifs
3. Points d'amélioration
4. Recommandations concrètes pour la prochaine semaine
Sois précis et pratique. Réponds uniquement en français.''';

      final interpretation = await _appellerClaude(prompt);
      setState(() {
        _interpretations['global'] = interpretation;
        _loadingIA['global'] = false;
      });
    } catch (e) {
      setState(() {
        _interpretations['global'] = 'Analyse globale indisponible.';
        _loadingIA['global'] = false;
      });
    }
  }

  Map<String, dynamic> _calculerStats(String type, List data) {
    if (data.isEmpty) return {};
    final values = data.map((d) => ((d[type] ?? 0) as num).toDouble()).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    final last = values.last;
    final trend = values.length > 1 ? values.last - values.first : 0;
    return {'avg': avg, 'max': max, 'min': min, 'last': last, 'trend': trend, 'count': values.length};
  }

  String _buildPrompt(String type, Map stats, List data) {
    final labels = {
      'mortalite': 'mortalité (nombre d\'animaux morts)',
      'temperature': 'température (°C)',
      'humidite': 'humidité (%)',
      'production': 'production',
    };
    final normes = {
      'mortalite': 'La norme acceptable est <5 morts/jour. Au-delà de 10, c\'est critique.',
      'temperature': 'La température idéale en élevage avicole au Sénégal est 25-32°C.',
      'humidite': 'L\'humidité idéale est entre 50-70%.',
      'production': 'Une bonne production indique une croissance saine du troupeau.',
    };
    return '''Tu es un expert en aviculture au Sénégal.
Analyse ces données de ${labels[type]} pour un élevage de poulets de chair.

Statistiques sur ${stats['count']} relevés:
- Moyenne: ${stats['avg']?.toStringAsFixed(1)}
- Maximum: ${stats['max']?.toStringAsFixed(1)}
- Minimum: ${stats['min']?.toStringAsFixed(1)}
- Dernière valeur: ${stats['last']?.toStringAsFixed(1)}
- Tendance: ${(stats['trend'] as num) > 0 ? '📈 En hausse' : '📉 En baisse'}

Norme: ${normes[type]}

Donne une interprétation courte (2-3 phrases max) incluant:
- Évaluation de la situation (bon/attention/critique)
- Une recommandation concrète si nécessaire
Sois direct et pratique. Réponds uniquement en français.''';
  }

  Future<String> _appellerClaude(String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': 'claude-sonnet-4-20250514',
        'max_tokens': 300,
        'messages': [{'role': 'user', 'content': prompt}],
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content'][0]['text'] ?? 'Analyse indisponible.';
    }
    return 'Analyse indisponible.';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kBlue));
    final filtered = _donneesFiltered();
    return Column(children: [
      Container(
        color: const Color(0xFF0F172A),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButtonFormField<String>(
            value: _selectedCycleId, dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
                labelText: 'Sélectionner un cycle',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white30)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white30)),
                filled: true, fillColor: Colors.white.withOpacity(0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            items: _cycles.map((c) => DropdownMenuItem<String>(
                value: c['id']?.toString(),
                child: Text(c['nom']?.toString() ?? '', style: const TextStyle(color: Colors.white)))).toList(),
            onChanged: (v) {
              setState(() { _selectedCycleId = v; _interpretations.clear(); });
              _analyserTout();
            }),
      ),
      Container(
        color: const Color(0xFF0F172A),
        child: TabBar(
            controller: _tabCtrl, isScrollable: true,
            labelColor: Colors.white, unselectedLabelColor: Colors.white38,
            indicatorColor: kBlueLight, indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            tabs: const [
              Tab(text: '💀 Mortalité'),
              Tab(text: '🌡️ Température'),
              Tab(text: '💧 Humidité'),
              Tab(text: '📦 Production'),
              Tab(text: '🤖 Analyse IA'),
            ]),
      ),
      Expanded(child: TabBarView(controller: _tabCtrl, children: [
        _buildChartWithIA('mortalite', filtered),
        _buildChartWithIA('temperature', filtered),
        _buildChartWithIA('humidite', filtered),
        _buildChartWithIA('production', filtered),
        _buildAnalyseGlobale(),
      ])),
    ]);
  }

  Widget _buildChartWithIA(String type, List data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 220, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)]),
            child: _buildChart(type, data)),
        const SizedBox(height: 16),
        _buildIACard(type),
      ]),
    );
  }

  Widget _buildIACard(String type) {
    final isLoading = _loadingIA[type] ?? false;
    final interpretation = _interpretations[type];
    final icons = {'mortalite': '💀', 'temperature': '🌡️', 'humidite': '💧', 'production': '📦'};
    final titles = {'mortalite': 'Analyse Mortalité', 'temperature': 'Analyse Température', 'humidite': 'Analyse Humidité', 'production': 'Analyse Production'};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF1E3A5F), Color(0xFF1B3A6B)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: kBlue.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Text(icons[type] ?? '🤖', style: const TextStyle(fontSize: 18))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titles[type] ?? 'Analyse', style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
            const Text('Powered by Claude AI', style: TextStyle(color: Colors.white38, fontSize: 10)),
          ]),
          const Spacer(),
          if (!isLoading) IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white60, size: 18),
              onPressed: () => _analyserGraphique(type, _donneesFiltered())),
        ]),
        const SizedBox(height: 12),
        if (isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)),
              SizedBox(width: 10),
              Text('Analyse en cours...', style: TextStyle(color: Colors.white54, fontSize: 13)),
            ]),
          ))
        else
          Text(interpretation ?? 'Appuyez sur actualiser pour analyser.',
              style: TextStyle(color: Colors.white.withOpacity(0.87), fontSize: 13, height: 1.5)),
      ]),
    );
  }

  Widget _buildAnalyseGlobale() {
    final isLoading = _loadingIA['global'] ?? false;
    final interpretation = _interpretations['global'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Text('🤖', style: TextStyle(fontSize: 32)),
              SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Analyse IA Complète', style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text('Powered by Claude AI', style: TextStyle(color: Colors.white38, fontSize: 11)),
              ]),
            ]),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Analyse en cours...', style: TextStyle(color: Colors.white54, fontSize: 14)),
                ]),
              ))
            else
              Text(interpretation ?? 'Chargement de l\'analyse...',
                  style: TextStyle(color: Colors.white.withOpacity(0.87), fontSize: 14, height: 1.6)),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity,
                child: OutlinedButton.icon(
                    onPressed: () => _analyserGlobal(_donneesFiltered()),
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white60, size: 16),
                    label: const Text('Relancer l\'analyse', style: TextStyle(color: Colors.white60)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('Résumé par indicateur',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        _buildIACard('mortalite'),
        const SizedBox(height: 12),
        _buildIACard('temperature'),
        const SizedBox(height: 12),
        _buildIACard('humidite'),
        const SizedBox(height: 12),
        _buildIACard('production'),
      ]),
    );
  }

  Widget _buildChart(String type, List data) {
    if (data.isEmpty) return _emptyChart('Aucune donnée');
    final colors = {'mortalite': kRed, 'temperature': kOrange, 'humidite': Colors.blue, 'production': kGreen};
    final units = {'mortalite': '', 'temperature': '°', 'humidite': '%', 'production': ''};
    final color = colors[type] ?? kBlue;
    final unit = units[type] ?? '';

    if (type == 'production') {
      final bars = data.asMap().entries
          .where((e) => ((e.value[type] ?? 0) as num) > 0)
          .map((e) => BarChartGroupData(x: e.key,
          barRods: [BarChartRodData(
              toY: ((e.value[type] ?? 0) as num).toDouble(),
              color: color, width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]))
          .toList();
      if (bars.isEmpty) return _emptyChart('Aucune production enregistrée');
      return BarChart(BarChartData(
          gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1)),
          titlesData: _titlesData(unit),
          borderData: FlBorderData(show: false),
          barGroups: bars));
    }

    final spots = data.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), ((e.value[type] ?? 0) as num).toDouble()))
        .toList();

    return LineChart(LineChartData(
        gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1)),
        titlesData: _titlesData(unit),
        borderData: FlBorderData(show: false),
        lineBarsData: [LineChartBarData(
            spots: spots, isCurved: true, color: color, barWidth: 3,
            belowBarData: BarAreaData(show: true, color: color.withOpacity(0.08)),
            dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) =>
                FlDotCirclePainter(radius: 4, color: color, strokeWidth: 2, strokeColor: Colors.white)))]));
  }

  FlTitlesData _titlesData(String unit) => FlTitlesData(
      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
          getTitlesWidget: (v, _) => Text('J${v.toInt()+1}', style: const TextStyle(fontSize: 9, color: Colors.grey)), reservedSize: 20)),
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
          getTitlesWidget: (v, _) => Text('${v.toInt()}$unit', style: const TextStyle(fontSize: 9, color: Colors.grey)), reservedSize: 35)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)));

  Widget _emptyChart(String msg) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('📊', style: TextStyle(fontSize: 40)),
    const SizedBox(height: 8),
    Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 13))]));
}