import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants/app_constants.dart';

class MortaliteChart extends StatelessWidget {
  final List donnees;
  const MortaliteChart({super.key, required this.donnees});

  @override
  Widget build(BuildContext context) {
    if (donnees.isEmpty) return _empty('Aucune donnée');
    final sorted = List.from(donnees)
      ..sort((a, b) => (a['date_releve'] ?? '').compareTo(b['date_releve'] ?? ''));
    int cumul = 0;
    final spots = sorted.asMap().entries.map((e) {
      cumul += ((e.value['mortalite'] ?? 0) as num).toInt();
      return FlSpot(e.key.toDouble(), cumul.toDouble());
    }).toList();

    return _chartCard('💀 Mortalité Cumulée', kRed,
        LineChart(LineChartData(
            gridData: FlGridData(show: true,
                getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withOpacity(0.1), strokeWidth: 1)),
            titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text('J${v.toInt() + 1}',
                        style: const TextStyle(fontSize: 8, color: Colors.grey)),
                    reservedSize: 18)),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}',
                        style: const TextStyle(fontSize: 8, color: Colors.grey)),
                    reservedSize: 28)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
            borderData: FlBorderData(show: false),
            lineBarsData: [LineChartBarData(
                spots: spots, isCurved: true, color: kRed, barWidth: 2.5,
                belowBarData: BarAreaData(show: true, color: kRed.withOpacity(0.08)),
                dotData: FlDotData(show: spots.length <= 7,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3, color: kRed, strokeWidth: 1.5,
                        strokeColor: Colors.white)))])));
  }
}

class ProductionChart extends StatelessWidget {
  final List donnees;
  const ProductionChart({super.key, required this.donnees});

  @override
  Widget build(BuildContext context) {
    if (donnees.isEmpty) return _empty('Aucune donnée');
    final sorted = List.from(donnees)
      ..sort((a, b) => (a['date_releve'] ?? '').compareTo(b['date_releve'] ?? ''));
    final bars = sorted.asMap().entries
        .where((e) => ((e.value['production'] ?? 0) as num) > 0)
        .map((e) => BarChartGroupData(x: e.key,
        barRods: [BarChartRodData(
            toY: ((e.value['production'] ?? 0) as num).toDouble(),
            color: kGreen, width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]))
        .toList();

    if (bars.isEmpty) return _empty('Aucune production enregistrée');

    return _chartCard('📦 Production', kGreen,
        BarChart(BarChartData(
            gridData: FlGridData(show: true,
                getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withOpacity(0.1), strokeWidth: 1)),
            titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text('J${v.toInt() + 1}',
                        style: const TextStyle(fontSize: 8, color: Colors.grey)),
                    reservedSize: 18)),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}',
                        style: const TextStyle(fontSize: 8, color: Colors.grey)),
                    reservedSize: 28)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
            borderData: FlBorderData(show: false),
            barGroups: bars)));
  }
}

class TemperatureChart extends StatelessWidget {
  final List donnees;
  const TemperatureChart({super.key, required this.donnees});

  @override
  Widget build(BuildContext context) {
    if (donnees.isEmpty) return _empty('Aucune donnée');
    final sorted = List.from(donnees)
      ..sort((a, b) => (a['date_releve'] ?? '').compareTo(b['date_releve'] ?? ''));
    final spots = sorted.asMap().entries
        .where((e) => ((e.value['temperature'] ?? 0) as num) != 0)
        .map((e) => FlSpot(e.key.toDouble(),
        ((e.value['temperature'] ?? 0) as num).toDouble()))
        .toList();

    if (spots.isEmpty) return _empty('Aucune température enregistrée');

    final refSpots = [FlSpot(0, 32), FlSpot(spots.last.x, 32)];

    return _chartCard('🌡️ Température (°C)', kOrange,
        LineChart(LineChartData(
            gridData: FlGridData(show: true,
                getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withOpacity(0.1), strokeWidth: 1)),
            titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text('J${v.toInt() + 1}',
                        style: const TextStyle(fontSize: 8, color: Colors.grey)),
                    reservedSize: 18)),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}°',
                        style: const TextStyle(fontSize: 8, color: Colors.grey)),
                    reservedSize: 28)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                  spots: spots, isCurved: true, color: kOrange, barWidth: 2.5,
                  belowBarData: BarAreaData(show: true, color: kOrange.withOpacity(0.08)),
                  dotData: FlDotData(show: spots.length <= 7,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 3, color: kOrange, strokeWidth: 1.5,
                          strokeColor: Colors.white))),
              LineChartBarData(
                  spots: refSpots, color: Colors.red.withOpacity(0.4),
                  barWidth: 1, dashArray: [4, 3],
                  dotData: const FlDotData(show: false)),
            ])));
  }
}

class CyclesResumeChart extends StatelessWidget {
  final List cycles;
  const CyclesResumeChart({super.key, required this.cycles});

  @override
  Widget build(BuildContext context) {
    if (cycles.isEmpty) return _empty('Aucun cycle');
    final actifs = cycles.where((c) =>
    c['statut'] == 'actif' || c['statut'] == 'en_cours').length;
    final termines = cycles.where((c) =>
    c['statut'] == 'termine' || c['statut'] == 'terminé').length;
    final autres = cycles.length - actifs - termines;

    final sections = [
      if (actifs > 0) PieChartSectionData(
          value: actifs.toDouble(), color: kGreen,
          title: '$actifs\nActifs', radius: 50,
          titleStyle: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 10)),
      if (termines > 0) PieChartSectionData(
          value: termines.toDouble(), color: kBlue,
          title: '$termines\nTerminés', radius: 50,
          titleStyle: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 10)),
      if (autres > 0) PieChartSectionData(
          value: autres.toDouble(), color: kOrange,
          title: '$autres\nAutres', radius: 50,
          titleStyle: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 10)),
    ];

    return _chartCard('🔄 Répartition Cycles', kBlue,
        Row(children: [
          Expanded(child: PieChart(PieChartData(
              sections: sections, centerSpaceRadius: 30,
              sectionsSpace: 2))),
          Column(mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                _legend(kGreen, 'Actifs ($actifs)'),
                const SizedBox(height: 6),
                _legend(kBlue, 'Terminés ($termines)'),
                if (autres > 0) ...[
                  const SizedBox(height: 6),
                  _legend(kOrange, 'Autres ($autres)'),
                ],
              ]),
        ]));
  }

  Widget _legend(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B))),
  ]);
}

Widget _chartCard(String title, Color color, Widget chart) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 3, height: 16,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B))),
      ]),
      const SizedBox(height: 14),
      SizedBox(height: 160, child: chart),
    ]));

Widget _empty(String msg) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.bar_chart_rounded, size: 32, color: Colors.grey),
      const SizedBox(height: 8),
      Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ])));