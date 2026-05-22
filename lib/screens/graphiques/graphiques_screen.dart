import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';

class GraphiquesScreen extends StatefulWidget {
  const GraphiquesScreen({super.key});
  @override
  State<GraphiquesScreen> createState() => _GraphiquesScreenState();
}

class _GraphiquesScreenState extends State<GraphiquesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List _cycles = [];
  List _donnees = [];
  String? _selectedCycleId;
  bool _loading = true;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 4, vsync: this); _load(); }
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
  }

  List _donneesFiltered() {
    final filtered = _selectedCycleId == null ? _donnees :
    _donnees.where((d) => d['cycle_id']?.toString() == _selectedCycleId).toList();
    filtered.sort((a, b) => (a['date_releve'] ?? '').compareTo(b['date_releve'] ?? ''));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kBlue));
    final filtered = _donneesFiltered();
    return Column(children: [
      Container(color: kBlue, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButtonFormField<String>(
              value: _selectedCycleId, dropdownColor: kBlue, style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  labelText: 'Sélectionner un cycle',
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white30)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white30)),
                  filled: true, fillColor: Colors.white.withOpacity(0.1),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              items: _cycles.map((c) => DropdownMenuItem<String>(
                  value: c['id']?.toString(),
                  child: Text(c['nom']?.toString() ?? '', style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (v) => setState(() => _selectedCycleId = v))),
      Container(color: kBlue, child: TabBar(
          controller: _tabCtrl, isScrollable: true,
          labelColor: Colors.white, unselectedLabelColor: Colors.white54, indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: const [
            Tab(text: '💀 Mortalité'),
            Tab(text: '🌡️ Température'),
            Tab(text: '💧 Humidité'),
            Tab(text: '📦 Production'),
          ])),
      Expanded(child: TabBarView(controller: _tabCtrl, children: [
        _buildMortaliteChart(filtered),
        _buildTemperatureChart(filtered),
        _buildHumiditeChart(filtered),
        _buildProductionChart(filtered),
      ])),
    ]);
  }

  Widget _buildMortaliteChart(List data) {
    if (data.isEmpty) return _emptyChart('Aucune donnée de mortalité');
    int cumul = 0;
    final spots = data.asMap().entries.map((e) {
      cumul += ((e.value['mortalite'] ?? 0) as num).toInt();
      return FlSpot(e.key.toDouble(), cumul.toDouble());
    }).toList();
    if (spots.isEmpty) return _emptyChart('Aucune donnée de mortalité');
    return _chartContainer('Mortalité Cumulée',
        LineChart(LineChartData(
            gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1)),
            titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                    getTitlesWidget: (v, _) => Text('J${v.toInt()+1}', style: const TextStyle(fontSize: 9)), reservedSize: 20)),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 9)), reservedSize: 30)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
            borderData: FlBorderData(show: false),
            lineBarsData: [LineChartBarData(
                spots: spots, isCurved: true, color: kRed, barWidth: 3,
                belowBarData: BarAreaData(show: true, color: kRed.withOpacity(0.1)),
                dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) =>
                    FlDotCirclePainter(radius: 3, color: kRed, strokeWidth: 1, strokeColor: Colors.white)))])));
  }

  Widget _buildTemperatureChart(List data) {
    if (data.isEmpty) return _emptyChart('Aucune donnée de température');
    final spots = data.asMap().entries
        .where((e) => (e.value['temperature'] ?? 0) != 0)
        .map((e) => FlSpot(e.key.toDouble(), ((e.value['temperature'] ?? 0) as num).toDouble()))
        .toList();
    if (spots.isEmpty) return _emptyChart('Aucune donnée de température');
    return _chartContainer('Température (°C)',
        LineChart(LineChartData(
            gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1)),
            titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                    getTitlesWidget: (v, _) => Text('J${v.toInt()+1}', style: const TextStyle(fontSize: 9)), reservedSize: 20)),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}°', style: const TextStyle(fontSize: 9)), reservedSize: 35)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
            borderData: FlBorderData(show: false),
            lineBarsData: [LineChartBarData(
                spots: spots, isCurved: true, color: kOrange, barWidth: 3,
                dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) =>
                    FlDotCirclePainter(radius: 3, color: kOrange, strokeWidth: 1, strokeColor: Colors.white)))])));
  }

  Widget _buildHumiditeChart(List data) {
    if (data.isEmpty) return _emptyChart('Aucune donnée d\'humidité');
    final spots = data.asMap().entries
        .where((e) => (e.value['humidite'] ?? 0) != 0)
        .map((e) => FlSpot(e.key.toDouble(), ((e.value['humidite'] ?? 0) as num).toDouble()))
        .toList();
    if (spots.isEmpty) return _emptyChart('Aucune donnée d\'humidité');
    return _chartContainer('Humidité (%)',
        LineChart(LineChartData(
            gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1)),
            titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                    getTitlesWidget: (v, _) => Text('J${v.toInt()+1}', style: const TextStyle(fontSize: 9)), reservedSize: 20)),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: const TextStyle(fontSize: 9)), reservedSize: 35)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
            borderData: FlBorderData(show: false),
            lineBarsData: [LineChartBarData(
                spots: spots, isCurved: true, color: Colors.blue, barWidth: 3,
                belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
                dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) =>
                    FlDotCirclePainter(radius: 3, color: Colors.blue, strokeWidth: 1, strokeColor: Colors.white)))])));
  }

  Widget _buildProductionChart(List data) {
    if (data.isEmpty) return _emptyChart('Aucune donnée de production');
    final bars = data.asMap().entries
        .where((e) => ((e.value['production'] ?? 0) as num) > 0)
        .map((e) => BarChartGroupData(x: e.key,
        barRods: [BarChartRodData(
            toY: ((e.value['production'] ?? 0) as num).toDouble(),
            color: kGreen, width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]))
        .toList();
    if (bars.isEmpty) return _emptyChart('Aucune donnée de production');
    return _chartContainer('Production',
        BarChart(BarChartData(
            gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1)),
            titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                    getTitlesWidget: (v, _) => Text('J${v.toInt()+1}', style: const TextStyle(fontSize: 9)), reservedSize: 20)),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 9)), reservedSize: 40)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
            borderData: FlBorderData(show: false), barGroups: bars)));
  }

  Widget _chartContainer(String title, Widget chart, {Widget? legend, Widget? extra}) =>
      SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kBlue)),
        const SizedBox(height: 16),
        Container(height: 250, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)]),
            child: chart),
        if (legend != null) ...[const SizedBox(height: 12), legend],
        if (extra != null) extra,
      ]));

  Widget _legendItem(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 16, height: 3, color: color), const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 12))]);

  Widget _emptyChart(String msg) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('📊', style: TextStyle(fontSize: 48)), const SizedBox(height: 12),
    Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 14))]));
}