import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../../services/api_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List _cycles = [];
  List _donnees = [];
  Map _meteo = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cycles = await ApiService.getCycles();
    final donnees = await ApiService.getDonnees();
    final meteo = await ApiService.getMeteo('Mbour');
    setState(() { _cycles = cycles; _donnees = donnees; _meteo = meteo; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kBlue));

    final cyclesActifs = _cycles.where((c) =>
    c['statut'] == 'actif' || c['statut'] == 'en_cours').length;
    final totalPoulets = _cycles.fold(0, (sum, c) =>
    sum + (c['nombre_sujets'] as int? ?? 0));
    final totalMorts = _donnees.fold(0, (sum, d) =>
    sum + (d['mortalite'] as int? ?? 0));
    final dernierProd = _donnees.isNotEmpty ?
    (_donnees.last['production'] ?? 0) : 0;

    return RefreshIndicator(onRefresh: _load, color: kBlue,
        child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: double.infinity, padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [kBlue, Color(0xFF2563EB)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: kBlue.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]),
                  child: Row(children: [
                    Container(width: 50, height: 50,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                        child: const Center(child: Text('🏡', style: TextStyle(fontSize: 26)))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(SessionManager.nom.isNotEmpty ? SessionManager.nom : 'Ferme Inis',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('$cyclesActifs cycle(s) actif(s) • ${SessionManager.role}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ])),
                    if (_meteo.isNotEmpty) Column(children: [
                      Text('${(_meteo['main']?['temp'] ?? 0).toStringAsFixed(0)}°C',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                      Text(_meteo['weather']?[0]?['description'] ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ]),
                    IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _load),
                  ])),
              const SizedBox(height: 16),
              GridView.count(crossAxisCount: 2, shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
                  children: [
                    _kpi('🐔', '$totalPoulets', 'Poulets total', kBlue, const Color(0xFFEFF6FF)),
                    _kpi('🔄', '$cyclesActifs', 'Cycles actifs', kGreen, const Color(0xFFF0FDF4)),
                    _kpi('📦', '$dernierProd', 'Production', kPurple, const Color(0xFFF5F3FF)),
                    _kpi('💀', '$totalMorts', 'Total morts', kRed, const Color(0xFFFEF2F2)),
                  ]),
              const SizedBox(height: 16),
              if (_cycles.isNotEmpty) ...[
                _sectionTitle('🔄 CYCLES RÉCENTS'),
                ..._cycles.take(3).map((c) => _cycleItem(c)),
              ],
              if (_donnees.isNotEmpty) ...[
                const SizedBox(height: 8),
                _sectionTitle('📊 DERNIÈRES DONNÉES'),
                ..._donnees.reversed.take(3).map((d) => _donneeItem(d)),
              ],
            ])));
  }

  Widget _kpi(String icon, String value, String label, Color color, Color bg) =>
      Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(icon, style: const TextStyle(fontSize: 22)), const Spacer(),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
          ]));

  Widget _sectionTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 8),
      child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: Color(0xFF1a7a9a), letterSpacing: 0.5)));

  Widget _cycleItem(Map c) {
    final statut = c['statut'] ?? '';
    final isActif = statut == 'actif' || statut == 'en_cours';
    final color = isActif ? kGreen : Colors.grey;
    return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
        child: Row(children: [
          Text(isActif ? '🐔' : '✅', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c['nom'] ?? 'Cycle sans nom',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text('${c['nombre_sujets'] ?? 0} sujets',
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(statut, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))),
        ]));
  }

  Widget _donneeItem(Map d) {
    final mortalite = d['mortalite'] as int? ?? 0;
    final color = mortalite > 10 ? kRed : mortalite > 5 ? kOrange : kGreen;
    return Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: color, width: 3))),
        child: Row(children: [
          Text('${d['date_releve'] ?? '-'}',
              style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 11)),
          const SizedBox(width: 10),
          Text('Prod: ${d['production'] ?? 0}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const Spacer(),
          Text('💀 $mortalite', style: TextStyle(color: color, fontSize: 12)),
        ]));
  }
}