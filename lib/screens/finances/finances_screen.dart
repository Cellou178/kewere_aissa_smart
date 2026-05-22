import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import '../../services/api_service.dart';


class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});
  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List _cycles = [];
  List _donnees = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); _load(); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final c = await ApiService.getCycles();
    final d = await ApiService.getDonnees();
    setState(() { _cycles = c; _donnees = d; _loading = false; });
  }

  double _calculerRevenu(Map cycle) {
    final sujets = (cycle['nombre_sujets'] as int? ?? 0).toDouble();
    final mortalite = _donnees.where((d) => d['cycle_id'] == cycle['id']).fold(0, (sum, d) => sum + (d['mortalite'] as int? ?? 0));
    return (sujets - mortalite) * FinanceParams.prixVentePoulet;
  }

  double _calculerDepenses(Map cycle) {
    final sujets = (cycle['nombre_sujets'] as int? ?? 0).toDouble();
    final aliment = _donnees.where((d) => d['cycle_id'] == cycle['id']).fold(0.0, (sum, d) => sum + (d['consommation_aliment'] as num? ?? 0).toDouble());
    return (aliment / 50) * FinanceParams.prixSacAliment + sujets * FinanceParams.prixPoussin +
        sujets * FinanceParams.coutMedicalParPoussin + FinanceParams.salairesMois * 1.5 + FinanceParams.loyerMois * 1.5;
  }

  String _formatFcfa(double v) => '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kBlue));
    double totalRevenu = _cycles.fold(0.0, (sum, c) => sum + _calculerRevenu(c));
    double totalDepenses = _cycles.fold(0.0, (sum, c) => sum + _calculerDepenses(c));
    double marge = totalRevenu - totalDepenses;
    return Column(children: [
      Container(padding: const EdgeInsets.all(16), color: kBlue,
          child: Row(children: [
            _finKpi('💵 Revenus', _formatFcfa(totalRevenu), kGreen),
            const SizedBox(width: 8),
            _finKpi('💸 Dépenses', _formatFcfa(totalDepenses), kRed),
            const SizedBox(width: 8),
            _finKpi('📊 Marge', _formatFcfa(marge), marge >= 0 ? kGreen : kRed),
          ])),
      Container(color: kBlue, child: TabBar(controller: _tabCtrl,
          labelColor: Colors.white, unselectedLabelColor: Colors.white54, indicatorColor: Colors.white,
          tabs: const [Tab(text: '💵 Par Cycle'), Tab(text: '💸 Dépenses'), Tab(text: '⚙️ Paramètres')])),
      Expanded(child: TabBarView(controller: _tabCtrl, children: [_buildParCycle(), _buildDepenses(), _buildParametres()])),
    ]);
  }

  Widget _buildParCycle() => ListView(padding: const EdgeInsets.all(16), children: [
    ..._cycles.map((c) {
      final revenu = _calculerRevenu(c);
      final depenses = _calculerDepenses(c);
      final marge = revenu - depenses;
      return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kBlue)),
            Text('${c['nombre_sujets'] ?? 0} sujets', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            Row(children: [_finRow('💵 Revenus', revenu, kGreen), const SizedBox(width: 8), _finRow('💸 Dépenses', depenses, kRed)]),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: (marge >= 0 ? kGreen : kRed).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('📊 Marge', style: TextStyle(fontWeight: FontWeight.w700, color: marge >= 0 ? kGreen : kRed)),
                  Text(_formatFcfa(marge), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: marge >= 0 ? kGreen : kRed)),
                ])),
          ]));
    }),
  ]);

  Widget _buildDepenses() {
    final cycle = _cycles.isNotEmpty ? _cycles.first : <String, dynamic>{};
    final sujets = (cycle['nombre_sujets'] as int? ?? 1000).toDouble();
    final aliment = _donnees.where((d) => d['cycle_id'] == cycle['id']).fold(0.0, (sum, d) => sum + (d['consommation_aliment'] as num? ?? 0).toDouble());
    final items = [
      {'label': '🐥 Poussins', 'montant': sujets * FinanceParams.prixPoussin},
      {'label': '🌾 Aliment', 'montant': (aliment / 50) * FinanceParams.prixSacAliment},
      {'label': '💊 Médical', 'montant': sujets * FinanceParams.coutMedicalParPoussin},
      {'label': '👥 Salaires', 'montant': FinanceParams.salairesMois * 1.5},
      {'label': '🏠 Loyer', 'montant': FinanceParams.loyerMois * 1.5},
    ];
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Détail des dépenses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kBlue)),
      const SizedBox(height: 12),
      ...items.map((item) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
          child: Row(children: [
            Text(item['label'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            Text(_formatFcfa(item['montant'] as double), style: const TextStyle(fontWeight: FontWeight.w800, color: kRed, fontSize: 14)),
          ]))),
    ]);
  }

  Widget _buildParametres() => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Paramètres financiers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kBlue)),
    const Text('Modifiez selon votre situation', style: TextStyle(color: Colors.grey, fontSize: 12)),
    const SizedBox(height: 16),
    _paramField('Prix sac aliment (FCFA)', FinanceParams.prixSacAliment, (v) => setState(() => FinanceParams.prixSacAliment = v)),
    _paramField('Prix vente poulet (FCFA)', FinanceParams.prixVentePoulet, (v) => setState(() => FinanceParams.prixVentePoulet = v)),
    _paramField('Prix poussin (FCFA)', FinanceParams.prixPoussin, (v) => setState(() => FinanceParams.prixPoussin = v)),
    _paramField('Salaires/mois (FCFA)', FinanceParams.salairesMois, (v) => setState(() => FinanceParams.salairesMois = v)),
    _paramField('Loyer/mois (FCFA)', FinanceParams.loyerMois, (v) => setState(() => FinanceParams.loyerMois = v)),
    _paramField('Coût médical/poussin', FinanceParams.coutMedicalParPoussin, (v) => setState(() => FinanceParams.coutMedicalParPoussin = v)),
  ]);

  Widget _paramField(String label, double value, Function(double) onChanged) {
    final ctrl = TextEditingController(text: value.toStringAsFixed(0));
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          SizedBox(width: 120, child: TextField(controller: ctrl, keyboardType: TextInputType.number, textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800, color: kBlue),
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), filled: true, fillColor: kBg),
              onSubmitted: (v) => onChanged(double.tryParse(v) ?? value))),
        ]));
  }

  Widget _finKpi(String label, String value, Color color) => Expanded(child: Container(padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        Text(value, style: TextStyle(color: color == kGreen ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.w800, fontSize: 12))])));

  Widget _finRow(String label, double montant, Color color) => Expanded(child: Container(padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: color)),
        Text(_formatFcfa(montant), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: color))])));
}