import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import 'employe_detail_screen.dart';
import 'add_employe_screen.dart';

class EmployesScreen extends StatefulWidget {
  const EmployesScreen({super.key});
  @override
  State<EmployesScreen> createState() => _EmployesScreenState();
}

class _EmployesScreenState extends State<EmployesScreen>
    with SingleTickerProviderStateMixin {
  List _employes = [];
  bool _loading = true;
  late TabController _tabCtrl;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final e = await ApiService.getEmployes();
    setState(() { _employes = e is List ? e : []; _loading = false; });
  }

  List get _filtres => _employes.where((e) =>
  (e['nom'] ?? '').toLowerCase().contains(_recherche.toLowerCase()) ||
      (e['poste'] ?? '').toLowerCase().contains(_recherche.toLowerCase())).toList();

  List _parPoste(String poste) => _filtres.where((e) =>
  (e['poste'] ?? '') == poste).toList();

  double get _masseSalariale => _employes.fold(0.0, (s, e) =>
  s + ((e['salaire'] ?? 0) as num).toDouble());

  Color _posteColor(String poste) {
    switch (poste) {
      case 'manager': return kPurple;
      case 'veterinaire': return kGreen;
      case 'chauffeur': return kOrange;
      case 'gardien': return Colors.brown;
      case 'comptable': return Colors.teal;
      default: return kBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddEmployeScreen()));
            if (result == true) _load();
          },
          backgroundColor: kBlue,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Ajouter',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
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
            // Stats
            Row(children: [
              _headerStat('${_employes.length}', 'Total', kBlue),
              _headerStat('${_parPoste('manager').length}', 'Managers', kPurple),
              _headerStat('${_parPoste('veterinaire').length}', 'Vétérinaires', kGreen),
              _headerStat(
                  '${(_masseSalariale / 1000).toStringAsFixed(0)}K',
                  'Masse sal.', kOrange),
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
                    hintText: 'Rechercher un employé...',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12)),
                onChanged: (v) => setState(() => _recherche = v),
              ),
            ),
            // Tabs
            TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              isScrollable: true,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              tabs: [
                Tab(text: 'Tous (${_filtres.length})'),
                Tab(text: 'Managers (${_parPoste('manager').length})'),
                Tab(text: 'Vétérinaires (${_parPoste('veterinaire').length})'),
                Tab(text: 'Autres'),
              ],
            ),
          ]),
        ),

        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlue))
            : TabBarView(controller: _tabCtrl, children: [
          _buildList(_filtres),
          _buildList(_parPoste('manager')),
          _buildList(_parPoste('veterinaire')),
          _buildList(_employes.where((e) =>
          !['manager', 'veterinaire'].contains(e['poste'] ?? '')).toList()),
        ])),
      ]),
    );
  }

  Widget _buildList(List employes) => RefreshIndicator(
    onRefresh: _load, color: kBlue,
    child: employes.isEmpty
        ? ListView(children: [
      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
      const Center(child: Column(children: [
        Icon(Icons.people_rounded, size: 56, color: Colors.grey),
        SizedBox(height: 12),
        Text('Aucun employé', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
      ])),
    ])
        : ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: employes.length,
      itemBuilder: (_, i) => _employeCard(employes[i]),
    ),
  );

  Widget _employeCard(Map e) {
    final poste = e['poste'] ?? 'employe';
    final salaire = ((e['salaire'] ?? 0) as num).toDouble();
    final color = _posteColor(poste);
    final nom = e['nom'] ?? 'Employé';

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(context,
            MaterialPageRoute(builder: (_) => EmployeDetailScreen(employe: e)));
        if (result == true) _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
        child: Row(children: [
          // Avatar
          Container(width: 48, height: 48,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)]),
                  shape: BoxShape.circle),
              child: Center(child: Text(
                  nom.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w900, fontSize: 20)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nom, style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
            const SizedBox(height: 3),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(poste, style: TextStyle(
                      color: color, fontSize: 10, fontWeight: FontWeight.w600))),
              if (e['telephone'] != null) ...[
                const SizedBox(width: 8),
                Text(e['telephone'], style: const TextStyle(
                    color: Colors.grey, fontSize: 10)),
              ],
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (salaire > 0) ...[
              Text('${(salaire / 1000).toStringAsFixed(0)}K',
                  style: const TextStyle(fontWeight: FontWeight.w900,
                      fontSize: 15, color: kGreen)),
              const Text('FCFA', style: TextStyle(color: Colors.grey, fontSize: 9)),
            ],
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 12),
          ]),
        ]),
      ),
    );
  }

  Widget _headerStat(String value, String label, Color color) =>
      Expanded(child: Column(children: [
        Text(value, style: TextStyle(
            color: color == kBlue ? Colors.white : color,
            fontSize: 16, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
      ]));
}