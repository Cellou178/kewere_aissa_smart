import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../../services/api_service.dart';

void _snack(BuildContext context, String msg, Color color) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));

class CyclesScreen extends StatefulWidget {
  const CyclesScreen({super.key});
  @override
  State<CyclesScreen> createState() => _CyclesScreenState();
}

class _CyclesScreenState extends State<CyclesScreen> {
  List _cycles = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final c = await ApiService.getCycles();
    setState(() { _cycles = c; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return _loading ? const Center(child: CircularProgressIndicator(color: kBlue)) :
    RefreshIndicator(onRefresh: _load, color: kBlue,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Mes Cycles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kBlue)),
              Text('${_cycles.length} cycle(s)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
            if (SessionManager.isProprietaire || SessionManager.isAdmin)
              ElevatedButton.icon(onPressed: () => _showAdd(context),
                  icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Nouveau'),
                  style: ElevatedButton.styleFrom(backgroundColor: kBlue, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0)),
          ]),
          const SizedBox(height: 16),
          if (_cycles.isEmpty) _empty('Aucun cycle', 'Créez votre premier cycle !', '🐔'),
          ..._cycles.map((c) => _card(c)),
        ]));
  }

  Widget _card(Map c) {
    final statut = c['statut'] ?? '';
    final isActif = statut == 'actif' || statut == 'en_cours';
    final color = isActif ? kGreen : statut == 'terminé' ? Colors.blueGrey : kOrange;
    return Container(margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))]),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.06),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
              child: Row(children: [
                Container(width: 44, height: 44,
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(isActif ? '🐔' : '✅', style: const TextStyle(fontSize: 20)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c['nom'] ?? 'Cycle sans nom',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  Text('${c['souche'] ?? '-'} • Bâtiment ${c['batiment'] ?? '-'}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(statut, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))),
              ])),
          Padding(padding: const EdgeInsets.all(12),
              child: Row(children: [
                _chip(Icons.pets_rounded, '${c['nombre_sujets'] ?? 0} sujets', kBlue),
                const SizedBox(width: 8),
                _chip(Icons.calendar_today_rounded, c['date_debut'] ?? '-', kGreen),
              ])),
        ]));
  }

  Widget _chip(IconData icon, String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color), const SizedBox(width: 3),
        Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600))
      ]));

  void _showAdd(BuildContext context) {
    final nomCtrl = TextEditingController();
    final sujetsCtrl = TextEditingController();
    final batCtrl = TextEditingController();
    final soucheCtrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Nouveau Cycle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kBlue)),
              const SizedBox(height: 16),
              _field(nomCtrl, 'Nom du cycle', Icons.label_rounded),
              const SizedBox(height: 10),
              _field(sujetsCtrl, 'Nombre de sujets', Icons.pets_rounded, isNumber: true),
              const SizedBox(height: 10),
              _field(batCtrl, 'Bâtiment', Icons.home_rounded),
              const SizedBox(height: 10),
              _field(soucheCtrl, 'Souche', Icons.science_rounded),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 50,
                  child: ElevatedButton(
                      onPressed: () async {
                        final fermeId = SessionManager.fermeId.isNotEmpty
                            ? SessionManager.fermeId
                            : '11111111-1111-1111-1111-111111111111';
                        final ok = await ApiService.createCycle({
                          'ferme_id': fermeId,
                          'nom': nomCtrl.text,
                          'date_debut': DateTime.now().toIso8601String().split('T')[0],
                          'nombre_sujets': int.tryParse(sujetsCtrl.text) ?? 0,
                          'type_cycle': 'chair',
                          'batiment': batCtrl.text,
                          'souche': soucheCtrl.text,
                          'statut': 'actif',
                        });
                        Navigator.pop(context);
                        if (ok) { _load(); _snack(context, '✅ Cycle créé !', kGreen); }
                        else { _snack(context, '❌ Erreur création cycle', kRed); }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: kBlue, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                      child: const Text('Créer', style: TextStyle(fontWeight: FontWeight.w700)))),
              const SizedBox(height: 20),
            ])));
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false}) =>
      TextField(controller: ctrl, keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: kBlueLight, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true, fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12)));
}

Widget _empty(String title, String subtitle, String emoji) =>
    Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 48)), const SizedBox(height: 12),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: kBlue)),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
    ])));