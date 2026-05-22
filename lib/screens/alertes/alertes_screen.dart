import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import '../../services/api_service.dart';

class AlertesScreen extends StatefulWidget {
  const AlertesScreen({super.key});
  @override
  State<AlertesScreen> createState() => _AlertesScreenState();
}

class _AlertesScreenState extends State<AlertesScreen> {
  List _alertes = [];
  List _donnees = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final a = await ApiService.getAlertes();
    final d = await ApiService.getDonnees();
    setState(() { _alertes = a; _donnees = d; _loading = false; });
  }

  List _alertesAuto() {
    List alertes = [];
    final sorted = List.from(_donnees)..sort((a, b) => (b['age_jours'] as int? ?? 0).compareTo(a['age_jours'] as int? ?? 0));
    if (sorted.isNotEmpty) {
      final mort = sorted.first['mortalite'] as int? ?? 0;
      if (mort > 10) alertes.add({'titre': '🚨 Mortalité élevée', 'description': '$mort morts au J${sorted.first['age_jours']}', 'type': 'danger'});
      else if (mort > 5) alertes.add({'titre': '⚠️ Mortalité à surveiller', 'description': '$mort morts au J${sorted.first['age_jours']}', 'type': 'warning'});
    }
    return alertes;
  }

  @override
  Widget build(BuildContext context) {
    final toutesAlertes = [..._alertesAuto(), ..._alertes];
    return RefreshIndicator(onRefresh: _load, color: kBlue,
        child: _loading ? const Center(child: CircularProgressIndicator(color: kBlue)) :
        ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Alertes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kBlue)),
          const SizedBox(height: 16),
          if (toutesAlertes.isEmpty) const Center(child: Text('✅ Aucune alerte', style: TextStyle(color: Colors.grey))),
          ...toutesAlertes.map((a) => _alerteCard(a)),
        ]));
  }

  Widget _alerteCard(Map a) {
    final type = a['type'] ?? 'info';
    final color = type == 'danger' ? kRed : type == 'warning' ? kOrange : kBlue;
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(type == 'danger' ? '🚨' : type == 'warning' ? '⚠️' : 'ℹ️', style: const TextStyle(fontSize: 20)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a['titre'] ?? a['message'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
            if (a['description'] != null) Text(a['description'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])),
        ]));
  }
}