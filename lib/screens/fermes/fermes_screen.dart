import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../../services/api_service.dart';
import 'ferme_detail_screen.dart';
import 'add_ferme_screen.dart';

class FermesScreen extends StatefulWidget {
  const FermesScreen({super.key});
  @override
  State<FermesScreen> createState() => _FermesScreenState();
}

class _FermesScreenState extends State<FermesScreen> {
  List _fermes = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final f = await ApiService.getFermes();
    setState(() { _fermes = f is List ? f : []; _loading = false; });
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('🏡 Mes Fermes', style: TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                Text('${_fermes.length} ferme(s) enregistrée(s)',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ]),
              if (SessionManager.isProprietaire || SessionManager.isAdmin)
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AddFermeScreen()));
                    if (result == true) _load();
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kBlueLight, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                ),
            ]),
          ]),
        ),

        // Liste
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlue))
            : RefreshIndicator(
          onRefresh: _load, color: kBlue,
          child: _fermes.isEmpty
              ? _empty()
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _fermes.length,
            itemBuilder: (_, i) => _fermeCard(_fermes[i]),
          ),
        )),
      ]),
      floatingActionButton: SessionManager.isProprietaire || SessionManager.isAdmin
          ? FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddFermeScreen()));
            if (result == true) _load();
          },
          backgroundColor: kBlue,
          child: const Icon(Icons.add_rounded, color: Colors.white))
          : null,
    );
  }

  Widget _fermeCard(Map f) {
    final superficie = f['superficie'] ?? 0;
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context,
            MaterialPageRoute(builder: (_) => FermeDetailScreen(ferme: f)));
        if (result == true) _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
        child: Column(children: [
          // Top
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [kBlue.withOpacity(0.08), kBlue.withOpacity(0.03)]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(children: [
              Container(width: 50, height: 50,
                  decoration: BoxDecoration(
                      color: kBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Text('🏡', style: TextStyle(fontSize: 26)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f['nom'] ?? 'Ferme sans nom', style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1E293B))),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.location_on_rounded, size: 13, color: Colors.grey),
                  const SizedBox(width: 3),
                  Text(f['localisation'] ?? '-',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
              ])),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
            ]),
          ),
          // Bottom
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              _chip(Icons.square_foot_rounded, '$superficie m²', kBlue),
              const SizedBox(width: 8),
              _chip(Icons.agriculture_rounded, 'Aviculture', kGreen),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]));

  Widget _empty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('🏡', style: TextStyle(fontSize: 56)),
    const SizedBox(height: 16),
    const Text('Aucune ferme', style: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
    const SizedBox(height: 8),
    const Text('Ajoutez votre première ferme', style: TextStyle(color: Colors.grey)),
  ]));
}