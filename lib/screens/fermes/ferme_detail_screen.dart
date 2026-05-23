import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../../services/api_service.dart';
import 'add_ferme_screen.dart';
import '../cycles/cycles_screen.dart';
import 'operations_screen.dart';

class FermeDetailScreen extends StatefulWidget {
  final Map ferme;
  const FermeDetailScreen({super.key, required this.ferme});
  @override
  State<FermeDetailScreen> createState() => _FermeDetailScreenState();
}

class _FermeDetailScreenState extends State<FermeDetailScreen> {
  List _cycles = [];
  List _stocks = [];
  List _employes = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cycles = await ApiService.getCycles();
    final stocks = await ApiService.getStocks();
    final employes = await ApiService.getEmployes();
    setState(() {
      _cycles = (cycles is List ? cycles : [])
          .where((c) => c['ferme_id']?.toString() == widget.ferme['id']?.toString())
          .toList();
      _stocks = (stocks is List ? stocks : [])
          .where((s) => s['ferme_id']?.toString() == widget.ferme['id']?.toString())
          .toList();
      _employes = (employes is List ? employes : [])
          .where((e) => e['ferme_id']?.toString() == widget.ferme['id']?.toString())
          .toList();
      _loading = false;
    });
  }

  Future<void> _deleteFerme() async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Supprimer la ferme ?'),
      content: const Text('Cette action est irréversible.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
        TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (confirm == true) {
      await ApiService.deleteFerme(widget.ferme['id'].toString());
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.ferme;
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(slivers: [
        // App Bar
        SliverAppBar(
        expandedHeight: 180,
        pinned: true,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          if (SessionManager.isProprietaire || SessionManager.isAdmin) ...[
            IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () async {
                  final result = await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => AddFermeScreen(ferme: f)));
                  if (result == true) Navigator.pop(context, true);
                }),
            IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                onPressed: _deleteFerme),
          ],
        ],
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 40),
              const Text('🏡', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 8),
              Text(f['nom'] ?? '', style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              Text(f['localisation'] ?? '', style: const TextStyle(color: Colors.white60, fontSize: 13)),
            ])),
          ),
        ),
      ),

      SliverToBoxAdapter(child: _loading
          ? const Center(child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: kBlue)))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Stats
          Row(children: [
            _statCard('🔄', '${_cycles.length}', 'Cycles', kBlue),
            const SizedBox(width: 10),
            _statCard('📦', '${_stocks.length}', 'Stocks', kGreen),
            const SizedBox(width: 10),
            _statCard('👥', '${_employes.length}', 'Employés', kPurple),
          ]),
          const SizedBox(height: 16),

          // Infos ferme
          _section('📋 Informations', [
            _infoRow('Superficie', '${f['superficie'] ?? 0} m²'),
            _infoRow('Localisation', f['localisation'] ?? '-'),
          ]),
          const SizedBox(height: 12),

          // Actions rapides
          _section('⚡ Actions Rapides', [
            _actionBtn('📊 Saisir données journalières', kBlue, () async {
              if (_cycles.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Créez d\'abord un cycle'),
                    backgroundColor: Colors.orange));
                return;
              }
              await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => OperationsScreen(
                      ferme: f, cycles: _cycles)));
              _load();
            }),
            const SizedBox(height: 8),
            _actionBtn('🔄 Voir les cycles', kGreen, () {
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const CyclesScreen()));
            }),
          ]),
          const SizedBox(height: 12),

          // Cycles récents
          if (_cycles.isNotEmpty) ...[
            _sectionTitle('🔄 Cycles Récents'),
            ..._cycles.take(3).map((c) => _cycleItem(c)),
          ],

          // Stocks
          if (_stocks.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionTitle('📦 Stocks'),
            ..._stocks.take(3).map((s) => _stockItem(s)),
          ],

          // Employés
          if (_employes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionTitle('👥 Employés'),
            ..._employes.take(3).map((e) => _employeItem(e)),
          ],
        ]),
      ),
      ),
      ]),
    );
  }

  Widget _statCard(String emoji, String value, String label, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
      ));

  Widget _section(String title, List<Widget> children) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
        const SizedBox(height: 10),
        ...children,
      ]));

  Widget _sectionTitle(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t, style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))));

  Widget _infoRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
      ]));

  Widget _actionBtn(String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2))),
          child: Row(children: [
            Text(label, style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13, color: color)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
          ]),
        ),
      );

  Widget _cycleItem(Map c) {
    final statut = c['statut'] ?? '';
    final isActif = statut == 'actif' || statut == 'en_cours';
    final color = isActif ? kGreen : Colors.grey;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
      child: Row(children: [
        Text(isActif ? '🐔' : '✅', style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Text(c['nom'] ?? '', style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 13))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(statut, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _stockItem(Map s) {
    final qte = ((s['quantite'] ?? 0) as num).toDouble();
    final seuil = ((s['seuil_alerte'] ?? 0) as num).toDouble();
    final isAlerte = qte <= seuil;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: (isAlerte ? kRed : kGreen).withOpacity(0.2))),
      child: Row(children: [
        Text(isAlerte ? '⚠️' : '📦', style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(child: Text(s['produit'] ?? '', style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 12))),
        Text('$qte ${s['unite'] ?? ''}', style: TextStyle(
            color: isAlerte ? kRed : kGreen, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }

  Widget _employeItem(Map e) => Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        CircleAvatar(backgroundColor: kBlue.withOpacity(0.1), radius: 18,
            child: Text((e['nom'] as String? ?? 'E').substring(0, 1).toUpperCase(),
                style: const TextStyle(color: kBlue, fontWeight: FontWeight.w800))),
        const SizedBox(width: 10),
        Expanded(child: Text(e['nom'] ?? '', style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 13))),
        Text(e['poste'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ]));
}