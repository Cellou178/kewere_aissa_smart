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

class _FermesScreenState extends State<FermesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List _fermes = [];
  List _cycles = [];
  List _stocks = [];
  List _employes = [];
  bool _loading = true;
  String _vue = 'grille'; // grille ou liste
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getFermes(),
      ApiService.getCycles(),
      ApiService.getStocks(),
      ApiService.getEmployes(),
    ]);
    setState(() {
      _fermes = results[0] is List ? results[0] as List : [];
      _cycles = results[1] is List ? results[1] as List : [];
      _stocks = results[2] is List ? results[2] as List : [];
      _employes = results[3] is List ? results[3] as List : [];
      _loading = false;
    });
  }

  List get _fermesFiltrees => _fermes.where((f) =>
  (f['nom'] ?? '').toLowerCase().contains(_recherche.toLowerCase()) ||
      (f['localisation'] ?? '').toLowerCase().contains(_recherche.toLowerCase())).toList();

  int _cyclesForFerme(String? id) => _cycles
      .where((c) => c['ferme_id']?.toString() == id).length;

  int _cyclesActifsForFerme(String? id) => _cycles
      .where((c) => c['ferme_id']?.toString() == id &&
      (c['statut'] == 'actif' || c['statut'] == 'en_cours')).length;

  int _stocksForFerme(String? id) => _stocks
      .where((s) => s['ferme_id']?.toString() == id).length;

  int _employesForFerme(String? id) => _employes
      .where((e) => e['ferme_id']?.toString() == id).length;

  int _totalPouletsForFerme(String? id) => _cycles
      .where((c) => c['ferme_id']?.toString() == id &&
      (c['statut'] == 'actif' || c['statut'] == 'en_cours'))
      .fold<int>(0, (s, c) =>
  s + ((c['nombre_sujets'] ?? 0) as num).toInt());

  // Stats globales
  int get _totalFermes => _fermes.length;
  int get _totalCyclesActifs => _cycles
      .where((c) => c['statut'] == 'actif' || c['statut'] == 'en_cours').length;
  int get _totalPoulets => _cycles
      .where((c) => c['statut'] == 'actif' || c['statut'] == 'en_cours')
      .fold<int>(0, (s, c) =>
  s + ((c['nombre_sujets'] ?? 0) as num).toInt());
  int get _totalEmployes => _employes.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: SessionManager.isProprietaire || SessionManager.isAdmin
          ? FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => AddFermeScreen()));
            if (result == true) _load();
          },
          backgroundColor: kBlue,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Nouvelle Ferme',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700)))
          : null,
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            // Titre + actions
            Row(children: [
              const Text('🏡', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Mes Fermes', style: TextStyle(
                    color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w900)),
                Text('Réseau de $_totalFermes ferme(s)',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              ])),
              // Toggle vue
              Container(
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  _vueBtn(Icons.grid_view_rounded, 'grille'),
                  _vueBtn(Icons.view_list_rounded, 'liste'),
                ]),
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white54, size: 20), onPressed: _load),
            ]),
            const SizedBox(height: 12),

            // Stats globales
            Row(children: [
              _headerStat('$_totalFermes', 'Fermes', Colors.white),
              _headerStat('$_totalCyclesActifs', 'Cycles\nactifs',
                  Colors.greenAccent),
              _headerStat('$_totalPoulets', 'Poulets\ntotaux',
                  Colors.orangeAccent),
              _headerStat('$_totalEmployes', 'Employés',
                  Colors.purpleAccent),
            ]),
            const SizedBox(height: 12),

            // Recherche
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    hintText: 'Rechercher une ferme...',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Colors.white54, size: 20),
                    border: InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 12)),
                onChanged: (v) => setState(() => _recherche = v),
              ),
            ),
          ]),
        ),

        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlue))
            : RefreshIndicator(
            onRefresh: _load, color: kBlue,
            child: _fermesFiltrees.isEmpty
                ? _empty()
                : _vue == 'grille'
                ? _buildGrille()
                : _buildListe())),
      ]),
    );
  }

  // ── VUE GRILLE ──
  Widget _buildGrille() => GridView.builder(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
        childAspectRatio: 0.85),
    itemCount: _fermesFiltrees.length,
    itemBuilder: (_, i) => _fermeCardGrille(_fermesFiltrees[i]),
  );

  Widget _fermeCardGrille(Map f) {
    final id = f['id']?.toString();
    final cyclesActifs = _cyclesActifsForFerme(id);
    final totalPoulets = _totalPouletsForFerme(id);
    final color = cyclesActifs > 0 ? kGreen : Colors.grey;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context,
            MaterialPageRoute(builder: (_) => FermeDetailScreen(ferme: f)));
        if (result == true) _load();
      },
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.06), blurRadius: 10)]),
        child: Column(children: [
          // Header coloré
          Container(
            height: 80,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.05)]),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16))),
            child: Stack(children: [
              Center(child: Text('🏡',
                  style: const TextStyle(fontSize: 36))),
              if (cyclesActifs > 0) Positioned(top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: kGreen, borderRadius: BorderRadius.circular(10)),
                    child: Text('$cyclesActifs actif(s)',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 8, fontWeight: FontWeight.w700)),
                  )),
            ]),
          ),
          // Infos
          Expanded(child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f['nom'] ?? 'Ferme', style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13,
                  color: Color(0xFF1E293B)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.location_on_rounded,
                    size: 10, color: Colors.grey),
                const SizedBox(width: 2),
                Expanded(child: Text(f['localisation'] ?? '-',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 10),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const Spacer(),
              // Mini stats
              Row(children: [
                _miniChip('🐔', '$totalPoulets', kOrange),
                const SizedBox(width: 4),
                _miniChip('👥', '${_employesForFerme(id)}', kPurple),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                _miniChip('📦', '${_stocksForFerme(id)} stocks', kBlue),
              ]),
            ]),
          )),
        ]),
      ),
    );
  }

  // ── VUE LISTE ──
  Widget _buildListe() => ListView.builder(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
    itemCount: _fermesFiltrees.length,
    itemBuilder: (_, i) => _fermeCardListe(_fermesFiltrees[i]),
  );

  Widget _fermeCardListe(Map f) {
    final id = f['id']?.toString();
    final cyclesActifs = _cyclesActifsForFerme(id);
    final totalPoulets = _totalPouletsForFerme(id);
    final superficie = f['superficie'] ?? 0;
    final color = cyclesActifs > 0 ? kGreen : Colors.grey;

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
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color.withOpacity(0.06),
                      color.withOpacity(0.02)]),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16))),
            child: Row(children: [
              Container(width: 52, height: 52,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Text('🏡',
                      style: TextStyle(fontSize: 28)))),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f['nom'] ?? 'Ferme', style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15,
                    color: Color(0xFF1E293B))),
                Row(children: [
                  const Icon(Icons.location_on_rounded,
                      size: 12, color: Colors.grey),
                  const SizedBox(width: 3),
                  Text(f['localisation'] ?? '-',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                if (cyclesActifs > 0) Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: kGreen, borderRadius: BorderRadius.circular(20)),
                    child: Text('$cyclesActifs actif(s)',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 9, fontWeight: FontWeight.w700))),
                const SizedBox(height: 3),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.grey, size: 13),
              ]),
            ]),
          ),
          // Stats ferme
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            child: Row(children: [
              _chip2(Icons.square_foot_rounded, '$superficie m²', kBlue),
              const SizedBox(width: 6),
              _chip2(Icons.pets_rounded, '$totalPoulets poulets', kOrange),
              const SizedBox(width: 6),
              _chip2(Icons.people_rounded,
                  '${_employesForFerme(id)} emp.', kPurple),
              const Spacer(),
              if (SessionManager.isProprietaire || SessionManager.isAdmin)
                Row(children: [
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(context,
                          MaterialPageRoute(builder: (_) =>
                              AddFermeScreen(ferme: f)));
                      if (result == true) _load();
                    },
                    child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: kBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.edit_rounded,
                            color: kBlue, size: 14)),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _confirmerSuppression(f),
                    child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: kRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.delete_rounded,
                            color: kRed, size: 14)),
                  ),
                ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _confirmerSuppression(Map f) async {
    final confirm = await showDialog<bool>(context: context,
        builder: (_) => AlertDialog(
          title: const Text('Supprimer la ferme ?'),
          content: Text('Supprimer "${f['nom']}" ?'
              '\nCette action est irréversible.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler')),
            TextButton(onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer',
                    style: TextStyle(color: Colors.red))),
          ],
        ));
    if (confirm == true) {
      await ApiService.deleteFerme(f['id'].toString());
      _load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Ferme supprimée'),
          backgroundColor: kGreen,
          behavior: SnackBarBehavior.floating));
    }
  }

  Widget _vueBtn(IconData icon, String vue) => GestureDetector(
    onTap: () => setState(() => _vue = vue),
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          color: _vue == vue ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6)),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );

  Widget _headerStat(String value, String label, Color color) =>
      Expanded(child: Column(children: [
        Text(value, style: TextStyle(
            color: color, fontSize: 16, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(
            color: Colors.white38, fontSize: 8),
            textAlign: TextAlign.center),
      ]));

  Widget _miniChip(String emoji, String value, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 9)),
        const SizedBox(width: 2),
        Text(value, style: TextStyle(
            color: color, fontSize: 9, fontWeight: FontWeight.w700)),
      ]));

  Widget _chip2(IconData icon, String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(
            color: color, fontSize: 9, fontWeight: FontWeight.w600)),
      ]));

  Widget _empty() => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('🏡', style: TextStyle(fontSize: 56)),
    const SizedBox(height: 16),
    const Text('Aucune ferme', style: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w800,
        color: Color(0xFF1E293B))),
    const SizedBox(height: 8),
    const Text('Ajoutez votre première ferme',
        style: TextStyle(color: Colors.grey)),
    const SizedBox(height: 24),
    if (SessionManager.isProprietaire || SessionManager.isAdmin)
      ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => AddFermeScreen()));
            if (result == true) _load();
          },
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Ajouter une ferme'),
          style: ElevatedButton.styleFrom(
              backgroundColor: kBlue, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)))),
  ]));
}