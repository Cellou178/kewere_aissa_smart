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
  String _periode = '7j';

  Map<String, String> _interpretations = {};
  Map<String, bool> _loadingIA = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
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
    var filtered = _selectedCycleId == null ? _donnees :
    _donnees.where((d) => d['cycle_id']?.toString() == _selectedCycleId).toList();
    filtered.sort((a, b) => (a['date_releve'] ?? '').compareTo(b['date_releve'] ?? ''));
    // Filtre période
    final now = DateTime.now();
    final jours = _periode == '7j' ? 7 : _periode == '14j' ? 14 : _periode == '30j' ? 30 : 999;
    if (jours < 999) {
      filtered = filtered.where((d) {
        try {
          final date = DateTime.parse(d['date_releve'] ?? '');
          return now.difference(date).inDays <= jours;
        } catch (_) { return true; }
      }).toList();
    }
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
      final totalMorts = data.fold<int>(0, (s, d) =>
      s + ((d['mortalite'] ?? 0) as num).toInt());
      final avgTemp = data.isEmpty ? 0.0 : data.fold<double>(0, (s, d) =>
      s + ((d['temperature'] ?? 0) as num).toDouble()) / data.length;
      final avgHum = data.isEmpty ? 0.0 : data.fold<double>(0, (s, d) =>
      s + ((d['humidite'] ?? 0) as num).toDouble()) / data.length;
      final totalProd = data.fold<int>(0, (s, d) =>
      s + ((d['production'] ?? 0) as num).toInt());

      final prompt = '''Tu es un expert en aviculture au Sénégal.
Analyse globalement ce cycle avicole et donne des recommandations.

Cycle: $cycleName
Relevés: ${data.length} (période: $_periode)
Mortalité totale: $totalMorts
Température moyenne: ${avgTemp.toStringAsFixed(1)}°C
Humidité moyenne: ${avgHum.toStringAsFixed(1)}%
Production totale: $totalProd

Analyse en 4-5 phrases:
1. État général
2. Points positifs
3. Points d'amélioration
4. Recommandations concrètes
Sois précis et pratique. En français.''';

      final interpretation = await _appellerClaude(prompt);
      setState(() {
        _interpretations['global'] = interpretation;
        _loadingIA['global'] = false;
      });
    } catch (e) {
      setState(() {
        _interpretations['global'] = 'Analyse indisponible.';
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
    final trend = values.length > 1 ? values.last - values.first : 0.0;
    final total = values.reduce((a, b) => a + b);
    return {
      'avg': avg, 'max': max, 'min': min,
      'last': last, 'trend': trend,
      'count': values.length, 'total': total,
    };
  }

  String _buildPrompt(String type, Map stats, List data) {
    final labels = {
      'mortalite': 'mortalité',
      'temperature': 'température (°C)',
      'humidite': 'humidité (%)',
      'production': 'production',
    };
    final normes = {
      'mortalite': 'Norme: <5/jour acceptable, >10 critique.',
      'temperature': 'Norme: 25-32°C idéal au Sénégal.',
      'humidite': 'Norme: 50-70% idéal.',
      'production': 'Bonne production = troupeau sain.',
    };
    return '''Expert aviculture Sénégal. Analyse ${labels[type]}.

Stats (${stats['count']} relevés):
- Moyenne: ${stats['avg']?.toStringAsFixed(1)}
- Max: ${stats['max']?.toStringAsFixed(1)}
- Min: ${stats['min']?.toStringAsFixed(1)}
- Tendance: ${(stats['trend'] as num) > 0 ? '📈 Hausse' : '📉 Baisse'}
${normes[type]}

2-3 phrases: évaluation + recommandation. En français.''';
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
      return data['content'][0]['text'] ?? 'Indisponible.';
    }
    return 'Analyse indisponible.';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kBlue));
    final filtered = _donneesFiltered();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
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
            Row(children: [
              const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Expanded(child: Text('Graphiques Avancés', style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))),
              IconButton(icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white54, size: 20), onPressed: _load),
            ]),
            const SizedBox(height: 8),
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
                    filled: true, fillColor: Colors.white.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: _cycles.map((c) => DropdownMenuItem<String>(
                    value: c['id']?.toString(),
                    child: Text(c['nom']?.toString() ?? '',
                        style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) {
                  setState(() { _selectedCycleId = v; _interpretations.clear(); });
                  _analyserTout();
                }),
            const SizedBox(height: 8),
            // Filtre période
            Row(children: [
              const Text('Période:', style: TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(width: 8),
              ...['7j', '14j', '30j', 'Tout'].map((p) => GestureDetector(
                onTap: () {
                  setState(() { _periode = p; _interpretations.clear(); });
                  _analyserTout();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: _periode == p ? kBlueLight : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(p, style: TextStyle(
                      color: _periode == p ? Colors.white : Colors.white54,
                      fontSize: 11, fontWeight: _periode == p
                      ? FontWeight.w700 : FontWeight.w400)),
                ),
              )),
              const Spacer(),
              Text('${filtered.length} relevés',
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              indicatorColor: kBlueLight,
              indicatorWeight: 2,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              tabs: const [
                Tab(text: '💀 Mortalité'),
                Tab(text: '🌡️ Température'),
                Tab(text: '💧 Humidité'),
                Tab(text: '📦 Production'),
                Tab(text: '📊 Comparaison'),
                Tab(text: '🤖 Analyse IA'),
              ],
            ),
          ]),
        ),

        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _buildChartTab('mortalite', filtered),
          _buildChartTab('temperature', filtered),
          _buildChartTab('humidite', filtered),
          _buildChartTab('production', filtered),
          _buildComparaison(filtered),
          _buildAnalyseGlobale(),
        ])),
      ]),
    );
  }

  Widget _buildChartTab(String type, List data) {
    final stats = _calculerStats(type, data);
    final colors = {
      'mortalite': kRed, 'temperature': kOrange,
      'humidite': Colors.blue, 'production': kGreen
    };
    final color = colors[type] ?? kBlue;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Stats rapides
        if (stats.isNotEmpty) Row(children: [
          _statMini('Moy.', stats['avg']?.toStringAsFixed(1) ?? '-', color),
          const SizedBox(width: 8),
          _statMini('Max', stats['max']?.toStringAsFixed(1) ?? '-', kRed),
          const SizedBox(width: 8),
          _statMini('Min', stats['min']?.toStringAsFixed(1) ?? '-', kGreen),
          const SizedBox(width: 8),
          _statMini('Total', stats['total']?.toStringAsFixed(0) ?? '-', kPurple),
        ]),
        const SizedBox(height: 12),

        // Graphique principal
        Container(height: 220, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: _buildChart(type, data)),
        const SizedBox(height: 12),

        // Tendance
        if (stats.isNotEmpty) _tendanceCard(stats, color, type),
        const SizedBox(height: 12),

        // Carte IA
        _buildIACard(type),
      ]),
    );
  }

  Widget _tendanceCard(Map stats, Color color, String type) {
    final trend = (stats['trend'] as num).toDouble();
    final isHausse = trend > 0;
    final isMauvais = (type == 'mortalite' || type == 'temperature' || type == 'humidite')
        ? isHausse : !isHausse;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Row(children: [
        Icon(isHausse ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: isMauvais ? kRed : kGreen, size: 24),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tendance sur la période',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          Text('${isHausse ? '+' : ''}${trend.toStringAsFixed(1)} depuis le début',
              style: TextStyle(color: isMauvais ? kRed : kGreen, fontSize: 11)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: (isMauvais ? kRed : kGreen).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(isMauvais ? '⚠️ Attention' : '✅ Bon',
                style: TextStyle(
                    color: isMauvais ? kRed : kGreen,
                    fontSize: 11, fontWeight: FontWeight.w700))),
      ]),
    );
  }

  // ── COMPARAISON ──
  Widget _buildComparaison(List data) {
    if (data.isEmpty) return const Center(child: Text('Aucune donnée'));

    final mortaliteStats = _calculerStats('mortalite', data);
    final tempStats = _calculerStats('temperature', data);
    final humStats = _calculerStats('humidite', data);
    final prodStats = _calculerStats('production', data);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Radar résumé
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('📊 Score par Indicateur', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          _indicateurBar('💀 Mortalité',
              mortaliteStats['avg'] ?? 0, 0, 20, kRed, inverse: true),
          const SizedBox(height: 10),
          _indicateurBar('🌡️ Température',
              tempStats['avg'] ?? 0, 20, 40, kOrange),
          const SizedBox(height: 10),
          _indicateurBar('💧 Humidité',
              humStats['avg'] ?? 0, 0, 100, Colors.blue),
          const SizedBox(height: 10),
          _indicateurBar('📦 Production',
              prodStats['avg'] ?? 0, 0, 100, kGreen),
        ])),
        const SizedBox(height: 12),

        // Comparaison cycles
        if (_cycles.length > 1) _card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🔄 Comparaison Cycles', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          ..._cycles.take(4).map((c) {
            final donnesCycle = _donnees.where((d) =>
            d['cycle_id']?.toString() == c['id']?.toString()).toList();
            final mort = donnesCycle.fold<int>(0, (s, d) =>
            s + ((d['mortalite'] ?? 0) as num).toInt());
            final sujets = ((c['nombre_sujets'] ?? 0) as num).toInt();
            final taux = sujets > 0 ? (mort / sujets * 100) : 0.0;
            final color = taux > 5 ? kRed : taux > 2 ? kOrange : kGreen;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Expanded(child: Text(c['nom'] ?? '', style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12))),
                Text('${taux.toStringAsFixed(1)}% mort.',
                    style: TextStyle(color: color,
                        fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
            );
          }),
        ])),
      ]),
    );
  }

  Widget _indicateurBar(String label, dynamic value, double min, double max,
      Color color, {bool inverse = false}) {
    final v = (value as num).toDouble();
    final pct = ((v - min) / (max - min)).clamp(0.0, 1.0);
    final isOk = inverse ? pct < 0.3 : (pct > 0.3 && pct < 0.8);
    final statusColor = isOk ? kGreen : kRed;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Row(children: [
          Text(v.toStringAsFixed(1),
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(width: 6),
          Container(width: 8, height: 8,
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
        ]),
      ]),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
              value: pct, backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color), minHeight: 6)),
    ]);
  }

  Widget _buildAnalyseGlobale() {
    final isLoading = _loadingIA['global'] ?? false;
    final interpretation = _interpretations['global'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Text('🤖', style: TextStyle(fontSize: 28)),
              SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Analyse IA Complète', style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                Text('Powered by Claude AI',
                    style: TextStyle(color: Colors.white38, fontSize: 10)),
              ]),
            ]),
            const SizedBox(height: 14),
            if (isLoading)
              const Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)),
                SizedBox(width: 10),
                Text('Analyse en cours...', style: TextStyle(color: Colors.white54, fontSize: 13)),
              ]))
            else
              Text(interpretation ?? 'Appuyez sur relancer pour analyser.',
                  style: TextStyle(color: Colors.white.withOpacity(0.87),
                      fontSize: 13, height: 1.5)),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity,
                child: OutlinedButton.icon(
                    onPressed: () => _analyserGlobal(_donneesFiltered()),
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white60, size: 16),
                    label: const Text('Relancer', style: TextStyle(color: Colors.white60)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))))),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('Par Indicateur', style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        _buildIACard('mortalite'),
        const SizedBox(height: 10),
        _buildIACard('temperature'),
        const SizedBox(height: 10),
        _buildIACard('humidite'),
        const SizedBox(height: 10),
        _buildIACard('production'),
      ]),
    );
  }

  Widget _buildIACard(String type) {
    final isLoading = _loadingIA[type] ?? false;
    final interpretation = _interpretations[type];
    final icons = {
      'mortalite': '💀', 'temperature': '🌡️',
      'humidite': '💧', 'production': '📦'
    };
    final titles = {
      'mortalite': 'Mortalité', 'temperature': 'Température',
      'humidite': 'Humidité', 'production': 'Production'
    };
    final colors = {
      'mortalite': kRed, 'temperature': kOrange,
      'humidite': Colors.blue, 'production': kGreen
    };
    final color = colors[type] ?? kBlue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(icons[type] ?? '🤖', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(titles[type] ?? '', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 13, color: color)),
          const Spacer(),
          if (!isLoading) GestureDetector(
              onTap: () => _analyserGraphique(type, _donneesFiltered()),
              child: Icon(Icons.refresh_rounded, color: color, size: 16)),
        ]),
        const SizedBox(height: 8),
        if (isLoading)
          Row(children: [
            SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(color: color, strokeWidth: 2)),
            const SizedBox(width: 8),
            const Text('Analyse...', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ])
        else
          Text(interpretation ?? 'Appuyez sur actualiser.',
              style: TextStyle(color: color.withOpacity(0.8),
                  fontSize: 12, height: 1.5)),
      ]),
    );
  }

  Widget _buildChart(String type, List data) {
    if (data.isEmpty) return _emptyChart('Aucune donnée');
    final colors = {
      'mortalite': kRed, 'temperature': kOrange,
      'humidite': Colors.blue, 'production': kGreen
    };
    final units = {
      'mortalite': '', 'temperature': '°',
      'humidite': '%', 'production': ''
    };
    final color = colors[type] ?? kBlue;
    final unit = units[type] ?? '';

    if (type == 'production') {
      final bars = data.asMap().entries
          .where((e) => ((e.value[type] ?? 0) as num) > 0)
          .map((e) => BarChartGroupData(x: e.key,
          barRods: [BarChartRodData(
              toY: ((e.value[type] ?? 0) as num).toDouble(),
              color: color, width: 12,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4)))]))
          .toList();
      if (bars.isEmpty) return _emptyChart('Aucune production');
      return BarChart(BarChartData(
          gridData: FlGridData(show: true,
              getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.grey.withOpacity(0.15), strokeWidth: 1)),
          titlesData: _titlesData(unit),
          borderData: FlBorderData(show: false),
          barGroups: bars));
    }

    final spots = data.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(),
        ((e.value[type] ?? 0) as num).toDouble()))
        .toList();

    return LineChart(LineChartData(
        gridData: FlGridData(show: true,
            getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.grey.withOpacity(0.15), strokeWidth: 1)),
        titlesData: _titlesData(unit),
        borderData: FlBorderData(show: false),
        lineBarsData: [LineChartBarData(
            spots: spots, isCurved: true, color: color, barWidth: 2.5,
            belowBarData: BarAreaData(show: true, color: color.withOpacity(0.08)),
            dotData: FlDotData(show: spots.length <= 10,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3, color: color, strokeWidth: 1.5,
                    strokeColor: Colors.white)))]));
  }

  FlTitlesData _titlesData(String unit) => FlTitlesData(
      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
          getTitlesWidget: (v, _) => Text('J${v.toInt()+1}',
              style: const TextStyle(fontSize: 8, color: Colors.grey)),
          reservedSize: 18)),
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
          getTitlesWidget: (v, _) => Text('${v.toInt()}$unit',
              style: const TextStyle(fontSize: 8, color: Colors.grey)),
          reservedSize: 32)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)));

  Widget _statMini(String label, String value, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(value, style: TextStyle(
              fontWeight: FontWeight.w900, fontSize: 14, color: color)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9)),
        ]),
      ));

  Widget _emptyChart(String msg) => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.bar_chart_rounded, size: 36, color: Colors.grey),
    const SizedBox(height: 8),
    Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 12)),
  ]));

  Widget _card({required Widget child}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: child);
}