import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';

class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key});
  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  List _stocks = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await ApiService.getStocks();
    setState(() { _stocks = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading ? const Center(child: CircularProgressIndicator(color: kBlue)) :
      RefreshIndicator(onRefresh: _load, color: kBlue,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Stocks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kBlue)),
                Text('${_stocks.length} produit(s)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
              ElevatedButton.icon(onPressed: () => _showAdd(context),
                  icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(backgroundColor: kBlue, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0)),
            ]),
            const SizedBox(height: 16),
            if (_stocks.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40),
                child: Text('📦 Aucun stock', style: TextStyle(color: Colors.grey, fontSize: 16)))),
            ..._stocks.map((s) => _stockCard(s)),
          ])),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAdd(context),
          backgroundColor: kBlue, child: const Icon(Icons.add_rounded, color: Colors.white)),
    );
  }

  Widget _stockCard(Map s) {
    final quantite = (s['quantite'] as num? ?? 0).toDouble();
    final seuil = (s['seuil_alerte'] as num? ?? 0).toDouble();
    final isAlerte = quantite <= seuil;
    final color = isAlerte ? kRed : kGreen;
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(isAlerte ? '⚠️' : '📦', style: const TextStyle(fontSize: 22)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s['produit'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text('Seuil alerte : $seuil ${s['unite'] ?? ''}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$quantite', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: color)),
            Text(s['unite'] ?? '', style: TextStyle(color: color, fontSize: 12)),
          ]),
        ]));
  }

  void _showAdd(BuildContext context) {
    final produitCtrl = TextEditingController();
    final quantiteCtrl = TextEditingController();
    final seuilCtrl = TextEditingController();
    final uniteCtrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Nouveau Stock', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kBlue)),
              const SizedBox(height: 16),
              _field(produitCtrl, 'Nom du produit', Icons.inventory_rounded),
              const SizedBox(height: 10),
              _field(quantiteCtrl, 'Quantité', Icons.numbers_rounded, isNumber: true),
              const SizedBox(height: 10),
              _field(seuilCtrl, 'Seuil alerte', Icons.warning_rounded, isNumber: true),
              const SizedBox(height: 10),
              _field(uniteCtrl, 'Unité (kg, sac, litre...)', Icons.scale_rounded),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 50,
                  child: ElevatedButton(
                      onPressed: () async {
                        final ok = await ApiService.createStock({
                          'produit': produitCtrl.text,
                          'quantite': double.tryParse(quantiteCtrl.text) ?? 0,
                          'seuil_alerte': double.tryParse(seuilCtrl.text) ?? 0,
                          'unite': uniteCtrl.text,
                          'ferme_id': '11111111-1111-1111-1111-111111111111',
                        });
                        Navigator.pop(context);
                        if (ok) _load();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: kBlue, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                      child: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.w700)))),
              const SizedBox(height: 20),
            ])));
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false}) =>
      TextField(controller: ctrl, keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: kBlueLight, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true, fillColor: const Color(0xFFF8FAFC)));
}