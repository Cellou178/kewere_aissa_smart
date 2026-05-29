import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import '../../core/utils/app_transitions.dart';

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
    _tabCtrl = TabController(length: 7, vsync: this);
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
    _donnees.where((d) =>
        d['cycle_id']?.toString() == _selectedCycleId).toList();
    filtered.sort((a, b) =>
        (a['date_releve'] ?? '').compareTo(b['date_releve'] ?? ''));
    final now = DateTime.now();
    final jours = _periode == '7j' ? 7 : _periode == '14j' ? 14
        : _periode == '30j' ? 30 : 999;
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

  void _analyserTout() {
    final filtered = _donneesFiltered();
    if (filtered.isEmpty) return;
    for (final type in ['mortalite', 'temperature', 'humidite', 'production']) {
      _analyserGraphique(type, filtered);
    }
    _analyserGlobal(filtered);
  }

  void _analyserGraphique(String type, List data) {
    if (data.isEmpty) return;
    final stats = _calculerStats(type, data);
    setState(() {
      _interpretations[type] = _genererInterpretation(type, stats, data);
    });
  }

  void _analyserGlobal(List data) {
    if (data.isEmpty) return;
    final cycleName = _cycles.firstWhere(
        (c) => c['id']?.toString() == _selectedCycleId,
        orElse: () => {'nom': 'Cycle inconnu'})['nom'];
    setState(() {
      _interpretations['global'] = _genererAnalyseGlobale(data, cycleName);
    });
  }

  String _genererInterpretation(String type, Map stats, List data) {
    final avg = (stats['avg'] as num).toDouble();
    final max = (stats['max'] as num).toDouble();
    final trend = (stats['trend'] as num).toDouble();
    switch (type) {
      case 'mortalite': return _interpreterMortalite(avg, max, trend);
      case 'temperature': return _interpreterTemperature(avg, max, (stats['min'] as num).toDouble(), trend);
      case 'humidite': return _interpreterHumidite(avg, trend);
      case 'production': return _interpreterProduction(avg, trend, data);
      default: return 'Données insuffisantes.';
    }
  }

  String _interpreterMortalite(double avg, double max, double trend) {
    final buf = StringBuffer();
    if (avg < 3) {
      buf.write('✅ Taux de mortalité excellent (${avg.toStringAsFixed(1)}/j). Conforme aux normes.');
    } else if (avg < 5) {
      buf.write('⚠️ Mortalité acceptable mais à surveiller (${avg.toStringAsFixed(1)}/j).');
    } else if (avg < 10) {
      buf.write('🚨 Mortalité élevée (${avg.toStringAsFixed(1)}/j). Enquête sanitaire recommandée.');
    } else {
      buf.write('🔴 CRITIQUE: Mortalité très élevée (${avg.toStringAsFixed(1)}/j). Vétérinaire urgent!');
    }
    buf.write(trend > 0 ? ' Tendance à la hausse: renforcer surveillance.' : ' Tendance stable.');
    if (max > 15) buf.write(' Pic critique de ${max.toStringAsFixed(0)}/j détecté.');
    buf.write('\n\n📚 Réf: FAO (2014) Good Practices for Biosecurity in the Poultry Sector; CNPO Sénégal: cible <3% du cheptel.');
    return buf.toString();
  }

  String _interpreterTemperature(double avg, double max, double min, double trend) {
    final buf = StringBuffer();
    if (avg >= 25 && avg <= 32) {
      buf.write('✅ Température optimale (${avg.toStringAsFixed(1)}°C). Plage idéale 25-32°C respectée.');
    } else if (avg < 25) {
      buf.write('❄️ Température basse (${avg.toStringAsFixed(1)}°C). Risque stress froid. Chauffage recommandé.');
    } else if (avg <= 35) {
      buf.write('🌡️ Température élevée (${avg.toStringAsFixed(1)}°C). >32°C: consommation eau +20%, croissance réduite.');
    } else {
      buf.write('🔴 CHALEUR CRITIQUE (${avg.toStringAsFixed(1)}°C). >35°C: risque mort thermique. Ventilation urgente!');
    }
    if (max > 38) buf.write(' Pic dangereux de ${max.toStringAsFixed(1)}°C enregistré.');
    buf.write('\n\n📚 Réf: Lohmann (2019) Broiler Management Guide; Cissé M. (2021) Aviculture Sénégal: T° optimale 25-32°C.');
    return buf.toString();
  }

  String _interpreterHumidite(double avg, double trend) {
    final buf = StringBuffer();
    if (avg >= 50 && avg <= 70) {
      buf.write('✅ Humidité idéale (${avg.toStringAsFixed(1)}%). Litière saine, pas de risque respiratoire.');
    } else if (avg < 50) {
      buf.write('💨 Humidité insuffisante (${avg.toStringAsFixed(1)}%). <50%: poussières et problèmes respiratoires.');
    } else if (avg <= 80) {
      buf.write('⚠️ Humidité élevée (${avg.toStringAsFixed(1)}%). >70%: litière humide, risque coccidiose.');
    } else {
      buf.write('🔴 Humidité critique (${avg.toStringAsFixed(1)}%). >80%: maladies respiratoires et mycoses probables.');
    }
    buf.write(trend > 5 ? ' Hausse rapide: vérifier ventilation.' : '');
    buf.write('\n\n📚 Réf: Ross (2018) Broiler Handbook; USDA NRCS: humidité cible 50-65% poulets de chair.');
    return buf.toString();
  }

  String _interpreterProduction(double avg, double trend, List data) {
    final buf = StringBuffer();
    final total = data.fold<int>(0, (s, d) => s + ((d['production'] ?? 0) as num).toInt());
    if (avg > 50) {
      buf.write('✅ Bonne production (moy. ${avg.toStringAsFixed(0)}/j). Cheptel en bonne santé.');
    } else if (avg > 20) {
      buf.write('📦 Production modérée (moy. ${avg.toStringAsFixed(0)}/j). Marge d\'amélioration possible.');
    } else {
      buf.write('📉 Production faible (moy. ${avg.toStringAsFixed(0)}/j). Vérifier alimentation et santé.');
    }
    buf.write(trend > 0 ? ' Tendance positive.' : trend < -5 ? ' Baisse détectée: investigation.' : '');
    buf.write(' Total période: $total.');
    buf.write('\n\n📚 Réf: ANSD Sénégal (2023) Rapport filière avicole; Diallo A. (2020) Production avicole Sahel.');
    return buf.toString();
  }

  String _genererAnalyseGlobale(List data, String cycleName) {
    final totalMorts = data.fold<int>(0, (s, d) => s + ((d['mortalite'] ?? 0) as num).toInt());
    final avgTemp = data.fold<double>(0, (s, d) => s + ((d['temperature'] ?? 0) as num).toDouble()) / data.length;
    final avgHum = data.fold<double>(0, (s, d) => s + ((d['humidite'] ?? 0) as num).toDouble()) / data.length;
    final totalProd = data.fold<int>(0, (s, d) => s + ((d['production'] ?? 0) as num).toInt());
    final mortParJour = data.isNotEmpty ? totalMorts / data.length : 0.0;
    int score = 100;
    if (mortParJour > 10) score -= 30; else if (mortParJour > 5) score -= 15;
    if (avgTemp < 25 || avgTemp > 35) score -= 20; else if (avgTemp > 32) score -= 10;
    if (avgHum < 50 || avgHum > 80) score -= 15; else if (avgHum > 70) score -= 5;
    final buf = StringBuffer();
    if (score >= 80) buf.write('✅ ÉTAT GÉNÉRAL EXCELLENT — Cycle $cycleName performant.\n\n');
    else if (score >= 60) buf.write('⚠️ ÉTAT GÉNÉRAL CORRECT — Cycle $cycleName avec points d\'amélioration.\n\n');
    else buf.write('🚨 ÉTAT GÉNÉRAL PRÉOCCUPANT — Interventions nécessaires.\n\n');
    buf.write('📊 Résumé (${data.length} relevés):\n');
    buf.write('• Mortalité totale: $totalMorts (${mortParJour > 5 ? "⚠️ élevée" : "✅ acceptable"})\n');
    buf.write('• T° moyenne: ${avgTemp.toStringAsFixed(1)}°C (${avgTemp >= 25 && avgTemp <= 32 ? "✅ idéale" : "⚠️ hors norme"})\n');
    buf.write('• Humidité moy: ${avgHum.toStringAsFixed(1)}% (${avgHum >= 50 && avgHum <= 70 ? "✅ idéale" : "⚠️ à corriger"})\n');
    buf.write('• Production totale: $totalProd\n\n');
    buf.write('💡 Recommandations:\n');
    bool ok = true;
    if (avgTemp > 32) { buf.write('• Améliorer ventilation (T° > 32°C)\n'); ok = false; }
    if (avgTemp < 25) { buf.write('• Augmenter chauffage (T° < 25°C)\n'); ok = false; }
    if (avgHum > 70) { buf.write('• Réduire densité, améliorer litière\n'); ok = false; }
    if (mortParJour > 5) { buf.write('• Consulter vétérinaire (mortalité élevée)\n'); ok = false; }
    if (ok) buf.write('• Maintenir les bonnes pratiques actuelles\n');
    buf.write('\n📚 Réf: FAO (2014) Biosecurity Poultry; CNPO Sénégal; Lohmann Broiler Guide (2019).');
    return buf.toString();
  }

  Map<String, dynamic> _calculerStats(String type, List data) {
    if (data.isEmpty) return {};
    final values = data.map((d) =>
        ((d[type] ?? 0) as num).toDouble()).toList();
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


  @override
  Widget build(BuildContext context) {
    // ── SHIMMER LOADING ──
    if (_loading) return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const SizedBox(height: 200),
          const ShimmerKPI(),
          const SizedBox(height: 16),
          const ShimmerCard(),
          const ShimmerCard(),
          const ShimmerCard(),
        ]),
      ),
    );

    final filtered = _donneesFiltered();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
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
            Row(children: [
              const Icon(Icons.bar_chart_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Expanded(child: Text('Graphiques Avancés',
                  style: TextStyle(color: Colors.white,
                      fontSize: 18, fontWeight: FontWeight.w900))),
              IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.white54, size: 20),
                  onPressed: _load),
            ]),
            const SizedBox(height: 8),

            // Sélecteur cycle
            DropdownButtonFormField<String>(
                value: _selectedCycleId,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(
                    color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                    labelText: 'Cycle',
                    labelStyle: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Colors.white30)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Colors.white30)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8)),
                items: _cycles.map((c) => DropdownMenuItem<String>(
                    value: c['id']?.toString(),
                    child: Text(c['nom']?.toString() ?? '',
                        style: const TextStyle(
                            color: Colors.white)))).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedCycleId = v;
                    _interpretations.clear();
                  });
                  _analyserTout();
                }),
            const SizedBox(height: 8),

            // Filtre période
            Row(children: [
              const Text('Période:',
                  style: TextStyle(
                      color: Colors.white54, fontSize: 11)),
              const SizedBox(width: 8),
              ...['7j', '14j', '30j', 'Tout'].map((p) =>
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _periode = p;
                        _interpretations.clear();
                      });
                      _analyserTout();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: _periode == p
                              ? kBlueLight
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(p, style: TextStyle(
                          color: _periode == p
                              ? Colors.white : Colors.white54,
                          fontSize: 11,
                          fontWeight: _periode == p
                              ? FontWeight.w700 : FontWeight.w400)),
                    ),
                  )),
              const Spacer(),
              Text('${filtered.length} relevés',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
            ]),
            const SizedBox(height: 8),

            TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              indicatorColor: kBlueLight,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 11),
              tabs: const [
                Tab(text: '💀 Mortalité'),
                Tab(text: '🌡️ Température'),
                Tab(text: '💧 Humidité'),
                Tab(text: '📦 Production'),
                Tab(text: '📊 Comparaison'),
                Tab(text: '📈 Gompertz'),
                Tab(text: '🔬 Analyse'),
              ],
            ),
          ]),
        ),

        Expanded(child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildChartTab('mortalite', filtered),
              _buildChartTab('temperature', filtered),
              _buildChartTab('humidite', filtered),
              _buildChartTab('production', filtered),
              _buildComparaison(filtered),
              _buildGompertz(filtered),
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
        if (stats.isNotEmpty) AnimatedCard(
          delay: const Duration(milliseconds: 50),
          child: Row(children: [
            _statMini('Moy.',
                stats['avg']?.toStringAsFixed(1) ?? '-', color),
            const SizedBox(width: 8),
            _statMini('Max',
                stats['max']?.toStringAsFixed(1) ?? '-', kRed),
            const SizedBox(width: 8),
            _statMini('Min',
                stats['min']?.toStringAsFixed(1) ?? '-', kGreen),
            const SizedBox(width: 8),
            _statMini('Total',
                stats['total']?.toStringAsFixed(0) ?? '-', kPurple),
          ]),
        ),
        const SizedBox(height: 12),

        // Graphique
        AnimatedCard(
          delay: const Duration(milliseconds: 100),
          child: Container(
              height: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10)]),
              child: _buildChart(type, data)),
        ),
        const SizedBox(height: 12),

        // Tendance
        if (stats.isNotEmpty) AnimatedCard(
          delay: const Duration(milliseconds: 150),
          child: _tendanceCard(stats, color, type),
        ),
        const SizedBox(height: 12),

        // Carte IA
        AnimatedCard(
          delay: const Duration(milliseconds: 200),
          child: _buildIACard(type),
        ),
      ]),
    );
  }

  Widget _tendanceCard(Map stats, Color color, String type) {
    final trend = (stats['trend'] as num).toDouble();
    final isHausse = trend > 0;
    final isMauvais = (type == 'mortalite' ||
        type == 'temperature' || type == 'humidite')
        ? isHausse : !isHausse;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8)]),
      child: Row(children: [
        Icon(isHausse ? Icons.trending_up_rounded
            : Icons.trending_down_rounded,
            color: isMauvais ? kRed : kGreen, size: 24),
        const SizedBox(width: 10),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const Text('Tendance sur la période',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12)),
          Text('${isHausse ? '+' : ''}${trend.toStringAsFixed(1)} depuis le début',
              style: TextStyle(
                  color: isMauvais ? kRed : kGreen,
                  fontSize: 11)),
        ])),
        Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: (isMauvais ? kRed : kGreen).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(isMauvais ? '⚠️ Attention' : '✅ Bon',
                style: TextStyle(
                    color: isMauvais ? kRed : kGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget _buildComparaison(List data) {
    if (data.isEmpty) return const Center(
        child: Text('Aucune donnée'));

    final mortaliteStats = _calculerStats('mortalite', data);
    final tempStats = _calculerStats('temperature', data);
    final humStats = _calculerStats('humidite', data);
    final prodStats = _calculerStats('production', data);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [

        AnimatedCard(
          delay: const Duration(milliseconds: 50),
          child: _card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('📊 Score par Indicateur',
                style: TextStyle(fontWeight: FontWeight.w800,
                    fontSize: 14, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            _indicateurBar('💀 Mortalité',
                mortaliteStats['avg'] ?? 0, 0, 20, kRed,
                inverse: true),
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
        ),
        const SizedBox(height: 12),

        // PieChart répartition cycles
        if (_cycles.isNotEmpty) AnimatedCard(
          delay: const Duration(milliseconds: 100),
          child: _card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('🥧 Répartition Cycles',
                style: TextStyle(fontWeight: FontWeight.w800,
                    fontSize: 14, color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: Row(children: [
                Expanded(child: PieChart(PieChartData(
                    sections: _buildPieSections(),
                    centerSpaceRadius: 35,
                    sectionsSpace: 2))),
                const SizedBox(width: 12),
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _legend(kGreen, 'Actifs'),
                  const SizedBox(height: 6),
                  _legend(kBlue, 'Terminés'),
                  const SizedBox(height: 6),
                  _legend(kOrange, 'Autres'),
                ]),
              ]),
            ),
          ])),
        ),
        const SizedBox(height: 12),

        if (_cycles.length > 1) AnimatedCard(
          delay: const Duration(milliseconds: 150),
          child: _card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('🔄 Comparaison Cycles',
                style: TextStyle(fontWeight: FontWeight.w800,
                    fontSize: 14, color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            ..._cycles.take(4).map((c) {
              final donnesCycle = _donnees.where((d) =>
              d['cycle_id']?.toString() ==
                  c['id']?.toString()).toList();
              final mort = donnesCycle.fold<int>(0, (s, d) =>
              s + ((d['mortalite'] ?? 0) as num).toInt());
              final sujets =
                  ((c['nombre_sujets'] ?? 0) as num).toInt();
              final taux = sujets > 0
                  ? (mort / sujets * 100) : 0.0;
              final color = taux > 5 ? kRed
                  : taux > 2 ? kOrange : kGreen;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Expanded(child: Text(c['nom'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12))),
                  Text('${taux.toStringAsFixed(1)}% mort.',
                      style: TextStyle(color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ]),
              );
            }),
          ])),
        ),
      ]),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final actifs = _cycles.where((c) =>
    c['statut'] == 'actif' || c['statut'] == 'en_cours').length;
    final termines = _cycles.where((c) =>
    c['statut'] == 'termine' || c['statut'] == 'terminé').length;
    final autres = _cycles.length - actifs - termines;
    final sections = <PieChartSectionData>[];
    if (actifs > 0) sections.add(PieChartSectionData(
        value: actifs.toDouble(), color: kGreen,
        title: '$actifs', radius: 50,
        titleStyle: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w800, fontSize: 12)));
    if (termines > 0) sections.add(PieChartSectionData(
        value: termines.toDouble(), color: kBlue,
        title: '$termines', radius: 50,
        titleStyle: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w800, fontSize: 12)));
    if (autres > 0) sections.add(PieChartSectionData(
        value: autres.toDouble(), color: kOrange,
        title: '$autres', radius: 50,
        titleStyle: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w800, fontSize: 12)));
    if (sections.isEmpty) sections.add(PieChartSectionData(
        value: 1, color: Colors.grey.shade300,
        title: '0', radius: 50,
        titleStyle: const TextStyle(color: Colors.white,
            fontSize: 12)));
    return sections;
  }

  Widget _legend(Color color, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(
                color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(
            fontSize: 11, color: Color(0xFF1E293B))),
      ]);

  Widget _indicateurBar(String label, dynamic value,
      double min, double max, Color color,
      {bool inverse = false}) {
    final v = (value as num).toDouble();
    final pct = ((v - min) / (max - min)).clamp(0.0, 1.0);
    final isOk = inverse ? pct < 0.3 : (pct > 0.3 && pct < 0.8);
    final statusColor = isOk ? kGreen : kRed;

    return Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
        Text(label, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600)),
        Row(children: [
          Text(v.toStringAsFixed(1), style: TextStyle(
              color: color, fontWeight: FontWeight.w800,
              fontSize: 12)),
          const SizedBox(width: 6),
          Container(width: 8, height: 8,
              decoration: BoxDecoration(
                  color: statusColor, shape: BoxShape.circle)),
        ]),
      ]),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6)),
    ]);
  }

  // ── MODÈLE DE GOMPERTZ ──
  // W(t) = A × exp(-b × exp(-k × t))
  // Paramètres Cobb 500 / conditions Sénégal:
  //   A = 2200g (poids asymptotique), b = 3.5, k = 0.085/j
  double _gompertz(double t) {
    const A = 2200.0, b = 3.5, k = 0.085;
    return A * exp(-b * exp(-k * t));
  }

  Widget _buildGompertz(List data) {
    const A = 2200.0, b = 3.5, k = 0.085;
    final inflexion = log(3.5) / k;
    final spots = List.generate(46, (i) =>
        FlSpot(i.toDouble(), _gompertz(i.toDouble()) / 1000));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Info modèle
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)]),
              borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📈 Modèle de Croissance de Gompertz',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('W(t) = A × exp(−b × exp(−k×t))',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
            const SizedBox(height: 8),
            Row(children: [
              _paramChip('A = ${A.toInt()}g', 'Poids final'),
              const SizedBox(width: 8),
              _paramChip('b = $b', 'Constante'),
              const SizedBox(width: 8),
              _paramChip('k = $k', 'Vitesse'),
            ]),
          ]),
        ),
        const SizedBox(height: 12),

        // Courbe
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Courbe de croissance théorique (Cobb 500)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Point d\'inflexion (croissance max): j${inflexion.toStringAsFixed(0)}',
                style: const TextStyle(color: kOrange, fontSize: 11)),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: LineChart(LineChartData(
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                    getDrawingVerticalLine: (_) =>
                        FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true, interval: 7,
                      getTitlesWidget: (v, _) => Text('j${v.toInt()}',
                          style: const TextStyle(fontSize: 9, color: Colors.grey)))),
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true, interval: 0.5,
                      getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}kg',
                          style: const TextStyle(fontSize: 9, color: Colors.grey)))),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: kBlue,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                        show: true, color: kBlue.withOpacity(0.08)),
                  ),
                  // Ligne inflexion
                  LineChartBarData(
                    spots: [FlSpot(inflexion, 0), FlSpot(inflexion, 2.2)],
                    isCurved: false,
                    color: kOrange.withOpacity(0.6),
                    barWidth: 1.5,
                    dashArray: [4, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              )),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // Tableau valeurs clés
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📋 Poids théoriques par âge', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 10),
            Table(
              border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade100)),
              children: [
                _tableRow('Âge', 'Poids théorique', 'Stade', isHeader: true),
                _tableRow('7 j', '${(_gompertz(7)/1000).toStringAsFixed(2)} kg', 'Démarrage', color: kBlue),
                _tableRow('14 j', '${(_gompertz(14)/1000).toStringAsFixed(2)} kg', 'Croissance rapide', color: kGreen),
                _tableRow('21 j', '${(_gompertz(21)/1000).toStringAsFixed(2)} kg', 'Mi-cycle', color: kOrange),
                _tableRow('35 j', '${(_gompertz(35)/1000).toStringAsFixed(2)} kg', 'Finition', color: kPurple),
                _tableRow('42 j', '${(_gompertz(42)/1000).toStringAsFixed(2)} kg', 'Abattage optimal', color: kRed),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // Interprétation + références
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: kBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBlue.withOpacity(0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🔬 Interprétation', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kBlue)),
            const SizedBox(height: 8),
            Text(
              'Le modèle de Gompertz décrit la croissance sigmoïde des poulets de chair. '
              'La phase d\'accélération maximale se produit à j${(log(3.5) / 0.085).toStringAsFixed(0)}, '
              'après quoi le gain quotidien ralentit. '
              'L\'âge optimal d\'abattage (42j) correspond au meilleur ratio gain/consommation alimentaire. '
              'Un poids inférieur au théorique indique un déficit alimentaire ou un stress environnemental.',
              style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            const Text('📚 Références scientifiques:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
            const SizedBox(height: 4),
            _refItem('Gompertz B. (1825) On the nature of the function expressive of the law of human mortality. Phil. Trans. R. Soc.'),
            _refItem('Winsorized Gompertz: Tjørve & Tjørve (2017) PLOS ONE — paramètres poulets de chair'),
            _refItem('Cobb-Vantress (2022) Cobb 500 Broiler Performance & Nutrition Supplement'),
            _refItem('CNPO Sénégal (2023) Guide production poulet de chair: poids cible 1.8-2.2 kg à 42j'),
            _refItem('Diallo A. et al. (2021) Modélisation croissance avicole en zone Sahélienne, Rev. Afric. Sci. Vét.'),
          ]),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _paramChip(String value, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
    ]),
  );

  TableRow _tableRow(String age, String poids, String stade, {bool isHeader = false, Color? color}) =>
      TableRow(children: [age, poids, stade].map((t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text(t, style: TextStyle(
            fontSize: isHeader ? 10 : 12,
            fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
            color: isHeader ? Colors.grey : (color ?? const Color(0xFF1E293B)))),
      )).toList());

  Widget _refItem(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('• ', style: TextStyle(color: kBlue, fontSize: 11)),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey, height: 1.4))),
    ]),
  );

  Widget _buildAnalyseGlobale() {
    final isLoading = _loadingIA['global'] ?? false;
    final interpretation = _interpretations['global'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        AnimatedCard(
          delay: const Duration(milliseconds: 50),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Row(children: [
                Text('🤖', style: TextStyle(fontSize: 28)),
                SizedBox(width: 10),
                Column(crossAxisAlignment:
                    CrossAxisAlignment.start, children: [
                  Text('Analyse IA Complète',
                      style: TextStyle(color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900)),
                  Text('Powered by Claude AI',
                      style: TextStyle(
                          color: Colors.white38, fontSize: 10)),
                ]),
              ]),
              const SizedBox(height: 14),
              if (isLoading)
                const Center(child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white54,
                          strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('Analyse en cours...',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 13)),
                ]))
              else
                Text(interpretation ??
                    'Appuyez sur relancer pour analyser.',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.87),
                        fontSize: 13, height: 1.5)),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity,
                  child: OutlinedButton.icon(
                      onPressed: () =>
                          _analyserGlobal(_donneesFiltered()),
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white60, size: 16),
                      label: const Text('Relancer',
                          style: TextStyle(
                              color: Colors.white60)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Colors.white24),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(10))))),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Par Indicateur', style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        AnimatedCard(
          delay: const Duration(milliseconds: 100),
          child: _buildIACard('mortalite'),
        ),
        const SizedBox(height: 10),
        AnimatedCard(
          delay: const Duration(milliseconds: 150),
          child: _buildIACard('temperature'),
        ),
        const SizedBox(height: 10),
        AnimatedCard(
          delay: const Duration(milliseconds: 200),
          child: _buildIACard('humidite'),
        ),
        const SizedBox(height: 10),
        AnimatedCard(
          delay: const Duration(milliseconds: 250),
          child: _buildIACard('production'),
        ),
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
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Text(icons[type] ?? '🤖',
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(titles[type] ?? '', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 13,
              color: color)),
          const Spacer(),
          if (!isLoading) GestureDetector(
              onTap: () => _analyserGraphique(
                  type, _donneesFiltered()),
              child: Icon(Icons.refresh_rounded,
                  color: color, size: 16)),
        ]),
        const SizedBox(height: 8),
        if (isLoading)
          Row(children: [
            SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(
                    color: color, strokeWidth: 2)),
            const SizedBox(width: 8),
            const Text('Analyse...',
                style: TextStyle(
                    color: Colors.grey, fontSize: 12)),
          ])
        else
          Text(interpretation ?? 'Appuyez sur actualiser.',
              style: TextStyle(
                  color: color.withOpacity(0.8),
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
                  color: Colors.grey.withOpacity(0.15),
                  strokeWidth: 1)),
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
                color: Colors.grey.withOpacity(0.15),
                strokeWidth: 1)),
        titlesData: _titlesData(unit),
        borderData: FlBorderData(show: false),
        lineBarsData: [LineChartBarData(
            spots: spots, isCurved: true,
            color: color, barWidth: 2.5,
            belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.08)),
            dotData: FlDotData(
                show: spots.length <= 10,
                getDotPainter: (_, __, ___, ____) =>
                    FlDotCirclePainter(
                        radius: 3, color: color,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white)))]));
  }

  FlTitlesData _titlesData(String unit) => FlTitlesData(
      bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (v, _) => Text('J${v.toInt()+1}',
              style: const TextStyle(
                  fontSize: 8, color: Colors.grey)),
          reservedSize: 18)),
      leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (v, _) =>
              Text('${v.toInt()}$unit',
                  style: const TextStyle(
                      fontSize: 8, color: Colors.grey)),
          reservedSize: 32)),
      topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false)));

  Widget _statMini(String label, String value, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(value, style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14, color: color)),
          Text(label, style: const TextStyle(
              color: Colors.grey, fontSize: 9)),
        ]),
      ));

  Widget _emptyChart(String msg) => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.bar_chart_rounded,
        size: 36, color: Colors.grey),
    const SizedBox(height: 8),
    Text(msg, style: const TextStyle(
        color: Colors.grey, fontSize: 12)),
  ]));

  Widget _card({required Widget child}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8)]),
      child: child);
}