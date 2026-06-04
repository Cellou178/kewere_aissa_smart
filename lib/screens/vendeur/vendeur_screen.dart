import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import '../../managers/session_manager.dart';

class VendeurScreen extends StatefulWidget {
  const VendeurScreen({super.key});
  @override
  State<VendeurScreen> createState() => _VendeurScreenState();
}

class _VendeurScreenState extends State<VendeurScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List _partenaires = [];
  List _mesCommandes = [];
  List _commandesRecues = [];
  bool _loading = true;

  final bool _isProprietaire =
      SessionManager.role == 'proprietaire' || SessionManager.role == 'admin';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _isProprietaire ? 3 : 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final futures = [
      ApiService.getPartenaires(),
      ApiService.getCommandesVendeur(),
      if (_isProprietaire) ApiService.getCommandesRecues(),
    ];
    final results = await Future.wait(futures);
    setState(() {
      _partenaires = results[0];
      _mesCommandes = results[1];
      if (_isProprietaire) _commandesRecues = results[2];
      _loading = false;
    });
  }

  Color _statutColor(String s) {
    switch (s) {
      case 'confirme': return kGreen;
      case 'livre': return kBlue;
      case 'annule': return kRed;
      default: return kOrange;
    }
  }

  String _statutLabel(String s) {
    switch (s) {
      case 'confirme': return '✅ Confirmé';
      case 'livre': return '📦 Livré';
      case 'annule': return '❌ Annulé';
      default: return '⏳ En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _partenaires.isEmpty ? null : () => _showNouvelleCommande(),
        backgroundColor: kGreen,
        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
        label: const Text('Nouvelle commande',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF14532D)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Espace Vendeur', style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text('${SessionManager.nom} — ${SessionManager.role}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ])),
              IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 20),
                  onPressed: _load),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _stat('${_partenaires.length}', 'Partenaires', Colors.white),
              _stat('${_mesCommandes.length}', 'Mes commandes', Colors.greenAccent),
              _stat(
                  '${_mesCommandes.where((c) => c['statut'] == 'en_attente').length}',
                  'En attente', kOrange),
              if (_isProprietaire)
                _stat('${_commandesRecues.length}', 'Reçues', Colors.blueAccent),
            ]),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              tabs: [
                const Tab(text: '🤝 Partenaires'),
                const Tab(text: '📋 Mes commandes'),
                if (_isProprietaire) const Tab(text: '📥 Reçues'),
              ],
            ),
          ]),
        ),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kGreen))
            : TabBarView(controller: _tabCtrl, children: [
          _buildPartenaires(),
          _buildMesCommandes(),
          if (_isProprietaire) _buildCommandesRecues(),
        ])),
      ]),
    );
  }

  // ── PARTENAIRES ──
  Widget _buildPartenaires() => _partenaires.isEmpty
      ? _empty('Aucun partenaire disponible', '🤝')
      : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _partenaires.length,
          itemBuilder: (_, i) {
            final p = _partenaires[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                        color: kGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Center(
                        child: Text('🏠', style: TextStyle(fontSize: 22)))),
                title: Text(p['nom'] ?? p['entreprise'] ?? 'Partenaire',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p['email'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  if ((p['telephone'] ?? '').isNotEmpty)
                    Text(p['telephone'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ]),
                trailing: ElevatedButton(
                  onPressed: () => _showNouvelleCommande(partenaire: p),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 0),
                  child: const Text('Commander', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
            );
          });

  // ── MES COMMANDES ──
  Widget _buildMesCommandes() => _mesCommandes.isEmpty
      ? _empty('Aucune commande passée', '📋')
      : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: _mesCommandes.length,
          itemBuilder: (_, i) => _commandeCard(_mesCommandes[i], showActions: false));

  // ── COMMANDES REÇUES ──
  Widget _buildCommandesRecues() => _commandesRecues.isEmpty
      ? _empty('Aucune commande reçue', '📥')
      : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: _commandesRecues.length,
          itemBuilder: (_, i) => _commandeCard(_commandesRecues[i], showActions: true));

  Widget _commandeCard(Map c, {required bool showActions}) {
    final statut = c['statut'] as String? ?? 'en_attente';
    final sColor = _statutColor(statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: sColor, width: 4)),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(c['produit'] ?? '', style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)))),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: sColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(_statutLabel(statut),
                    style: TextStyle(color: sColor, fontSize: 10, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 6),
          Text('Partenaire : ${c['partenaire_nom'] ?? '-'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text('Quantité : ${c['quantite'] ?? '-'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if ((c['notes'] ?? '').toString().isNotEmpty)
            Text('Note : ${c['notes']}',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          if (showActions && statut == 'en_attente') ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => _updateStatut(c['id'].toString(), 'confirme'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: kGreen, side: const BorderSide(color: kGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('✅ Confirmer'),
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(
                onPressed: () => _updateStatut(c['id'].toString(), 'annule'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: kRed, side: const BorderSide(color: kRed),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('❌ Refuser'),
              )),
            ]),
          ],
          if (showActions && statut == 'confirme') ...[
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () => _updateStatut(c['id'].toString(), 'livre'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0),
              child: const Text('📦 Marquer livré'),
            )),
          ],
        ]),
      ),
    );
  }

  Future<void> _updateStatut(String id, String statut) async {
    await ApiService.updateStatutCommande(id, statut);
    _load();
  }

  void _showNouvelleCommande({Map? partenaire}) {
    if (_partenaires.isEmpty) return;
    Map? selectedPartenaire = partenaire ?? _partenaires.first;
    final produitCtrl = TextEditingController();
    final qteCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModal) => Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  left: 20, right: 20, top: 24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Nouvelle Commande', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                const SizedBox(height: 16),
                DropdownButtonFormField<Map>(
                  value: selectedPartenaire,
                  decoration: InputDecoration(
                      labelText: 'Partenaire',
                      prefixIcon: const Icon(Icons.handshake_rounded, color: kGreen, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true, fillColor: const Color(0xFFF8FAFC)),
                  items: _partenaires.map<DropdownMenuItem<Map>>((p) =>
                      DropdownMenuItem(value: p,
                          child: Text(p['nom'] ?? p['entreprise'] ?? 'Partenaire'))).toList(),
                  onChanged: (v) => setModal(() => selectedPartenaire = v),
                ),
                const SizedBox(height: 10),
                _field(produitCtrl, 'Produit (ex: Poulets de chair)', Icons.shopping_bag_rounded),
                const SizedBox(height: 10),
                _field(qteCtrl, 'Quantité', Icons.numbers_rounded, isNumber: true),
                const SizedBox(height: 10),
                _field(notesCtrl, 'Notes / conditions', Icons.notes_rounded),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, height: 50,
                    child: ElevatedButton.icon(
                        onPressed: () async {
                          if (produitCtrl.text.isEmpty || selectedPartenaire == null) return;
                          final ok = await ApiService.createCommandeVendeur({
                            'partenaire_id': selectedPartenaire!['id']?.toString() ?? '',
                            'partenaire_nom': selectedPartenaire!['nom'] ??
                                selectedPartenaire!['entreprise'] ?? '',
                            'produit': produitCtrl.text,
                            'quantite': int.tryParse(qteCtrl.text) ?? 1,
                            'notes': notesCtrl.text,
                          });
                          Navigator.pop(context);
                          if (ok) {
                            _load();
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✅ Commande envoyée !'),
                                    backgroundColor: kGreen,
                                    behavior: SnackBarBehavior.floating));
                          } else {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Erreur lors de l\'envoi'),
                                    backgroundColor: kRed,
                                    behavior: SnackBarBehavior.floating));
                          }
                        },
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Envoyer la commande',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: kGreen, foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0))),
                const SizedBox(height: 8),
              ]))),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {bool isNumber = false}) =>
      TextField(
          controller: c,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: kGreen, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true, fillColor: const Color(0xFFF8FAFC)));

  Widget _stat(String value, String label, Color color) =>
      Expanded(child: Column(children: [
        Text(value, style: TextStyle(
            color: color, fontSize: 16, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(
            color: Colors.white38, fontSize: 8), textAlign: TextAlign.center),
      ]));

  Widget _empty(String msg, String emoji) => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
    Text(emoji, style: const TextStyle(fontSize: 48)),
    const SizedBox(height: 12),
    Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 16)),
    const SizedBox(height: 12),
    ElevatedButton(onPressed: _load,
        style: ElevatedButton.styleFrom(backgroundColor: kGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: const Text('Actualiser')),
  ]));
}
