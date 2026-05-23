import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../../services/api_service.dart';
import '../cycles/add_cycle_screen.dart';
import '../fermes/operations_screen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List _cycles = [];
  List _donnees = [];
  List _alertes = [];
  Map _meteo = {};
  bool _loading = true;
  bool _fabOpen = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cycles = await ApiService.getCycles();
    final donnees = await ApiService.getDonnees();
    final alertes = await ApiService.getAlertes();
    final meteo = await ApiService.getMeteo('Mbour');
    setState(() {
      _cycles = cycles is List ? cycles : [];
      _donnees = donnees is List ? donnees : [];
      _alertes = alertes is List ? alertes : [];
      _meteo = meteo is Map ? meteo : {};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 400;

    if (_loading) return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(child: CircularProgressIndicator(color: kBlue)),
    );

    final cyclesActifs = _cycles.where((c) =>
    c['statut'] == 'actif' || c['statut'] == 'en_cours').length;
    final totalPoulets = _cycles.fold<int>(0, (sum, c) =>
    sum + ((c['nombre_sujets'] ?? 0) as num).toInt());
    final totalMorts = _donnees.fold<int>(0, (sum, d) =>
    sum + ((d['mortalite'] ?? 0) as num).toInt());
    final dernierProd = _donnees.isNotEmpty ?
    ((_donnees.last['production'] ?? 0) as num).toInt() : 0;
    final temp = _meteo.isNotEmpty ?
    (_meteo['main']?['temp'] ?? 0).toStringAsFixed(0) : '--';
    final alertesCritiques = _alertes.where((a) =>
    a['type'] == 'danger').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: _buildFAB(context),
      body: RefreshIndicator(
        onRefresh: _load, color: kBlue,
        child: CustomScrollView(slivers: [

          // ── HEADER ──
          SliverToBoxAdapter(child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Greeting
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    'Bonjour, ${SessionManager.nom.isNotEmpty ? SessionManager.nom.split(' ').first : 'Propriétaire'} 👋',
                    style: TextStyle(color: Colors.white70, fontSize: isSmall ? 11 : 13),
                  ),
                  Text('Tableau de bord', style: TextStyle(
                      color: Colors.white, fontSize: isSmall ? 16 : 18,
                      fontWeight: FontWeight.w900)),
                ]),
                Row(children: [
                  if (_meteo.isNotEmpty) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('$temp°C', style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                    ]),
                  ),
                  IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 20),
                      onPressed: _load),
                ]),
              ]),
              const SizedBox(height: 16),

              // Alerte critique badge
              if (alertesCritiques > 0) Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: kRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kRed.withOpacity(0.4))),
                child: Row(children: [
                  const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Text('$alertesCritiques alerte(s) critique(s) !',
                      style: const TextStyle(color: Colors.redAccent,
                          fontWeight: FontWeight.w700, fontSize: 12)),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.redAccent, size: 12),
                ]),
              ),

              // KPI Cards
              Row(children: [
                _kpiCard(Icons.pets_rounded, '$totalPoulets', 'Poulets',
                    const Color(0xFF3B82F6), isSmall),
                const SizedBox(width: 8),
                _kpiCard(Icons.loop_rounded, '$cyclesActifs', 'Actifs',
                    const Color(0xFF10B981), isSmall),
                const SizedBox(width: 8),
                _kpiCard(Icons.warning_rounded, '$totalMorts', 'Morts',
                    const Color(0xFFEF4444), isSmall),
                const SizedBox(width: 8),
                _kpiCard(Icons.inventory_rounded, '$dernierProd', 'Prod.',
                    const Color(0xFF8B5CF6), isSmall),
              ]),
            ]),
          )),

          // ── CONTENU ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            sliver: SliverList(delegate: SliverChildListDelegate([

              // Actions rapides
              _sectionHeader('⚡ Actions Rapides', ''),
              const SizedBox(height: 10),
              Row(children: [
                _quickAction(Icons.add_circle_rounded, 'Nouveau\nCycle', kBlue, () async {
                  final result = await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AddCycleScreen()));
                  if (result == true) _load();
                }),
                const SizedBox(width: 8),
                _quickAction(Icons.assignment_add, 'Saisir\nDonnées', kGreen, () {
                  if (_cycles.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Créez d\'abord un cycle'),
                        backgroundColor: Colors.orange));
                    return;
                  }
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => OperationsScreen(
                          ferme: {}, cycles: _cycles)));
                }),
                const SizedBox(width: 8),
                _quickAction(Icons.notifications_active_rounded, 'Voir\nAlertes',
                    alertesCritiques > 0 ? kRed : kOrange, () {}),
                const SizedBox(width: 8),
                _quickAction(Icons.refresh_rounded, 'Actualiser', Colors.grey, _load),
              ]),
              const SizedBox(height: 20),

              // Cycles actifs
              if (_cycles.isNotEmpty) ...[
                _sectionHeader('🔄 Cycles', '${_cycles.length} total'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cycles.take(5).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _cycleCard(_cycles[i], isSmall),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Alertes critiques en premier
              if (_alertes.isNotEmpty) ...[
                _sectionHeader('🚨 Alertes', '${_alertes.length}'),
                const SizedBox(height: 10),
                ..._alertes.take(3).map((a) => _alerteCard(a)),
                const SizedBox(height: 20),
              ],

              // Météo
              if (_meteo.isNotEmpty) ...[
                _sectionHeader('🌤️ Météo', 'Mbour'),
                const SizedBox(height: 10),
                _meteoCard(),
                const SizedBox(height: 20),
              ],

              // Dernières données
              if (_donnees.isNotEmpty) ...[
                _sectionHeader('📊 Données', '${_donnees.length} entrées'),
                const SizedBox(height: 10),
                ..._donnees.reversed.take(3).map((d) => _donneeCard(d, isSmall)),
              ],

            ])),
          ),
        ]),
      ),
    );
  }

  // ── FAB MENU ──
  Widget _buildFAB(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (_fabOpen) ...[
        _fabItem(Icons.add_circle_rounded, 'Nouveau Cycle', kBlue, () async {
          setState(() => _fabOpen = false);
          final result = await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddCycleScreen()));
          if (result == true) _load();
        }),
        const SizedBox(height: 8),
        _fabItem(Icons.assignment_add, 'Saisir Données', kGreen, () {
          setState(() => _fabOpen = false);
          if (_cycles.isEmpty) return;
          Navigator.push(context, MaterialPageRoute(
              builder: (_) => OperationsScreen(ferme: {}, cycles: _cycles)));
        }),
        const SizedBox(height: 8),
        _fabItem(Icons.inventory_2_rounded, 'Ajouter Stock', kOrange, () {
          setState(() => _fabOpen = false);
        }),
        const SizedBox(height: 8),
      ],
      FloatingActionButton(
        onPressed: () => setState(() => _fabOpen = !_fabOpen),
        backgroundColor: kBlue,
        child: AnimatedRotation(
          turns: _fabOpen ? 0.125 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    ]);
  }

  Widget _fabItem(IconData icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
            child: Text(label, style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)]),
              child: Icon(icon, color: Colors.white, size: 20)),
        ]),
      );

  // ── WIDGETS ──
  Widget _kpiCard(IconData icon, String value, String label, Color color, bool isSmall) =>
      Expanded(child: Container(
        padding: EdgeInsets.all(isSmall ? 8 : 10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: isSmall ? 16 : 18),
          SizedBox(height: isSmall ? 4 : 6),
          Text(value, style: TextStyle(
              color: Colors.white, fontSize: isSmall ? 14 : 16,
              fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(
              color: Colors.white60, fontSize: isSmall ? 8 : 9)),
        ]),
      ));

  Widget _quickAction(IconData icon, String label, Color color, VoidCallback onTap) =>
      Expanded(child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
          child: Column(children: [
            Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
          ]),
        ),
      ));

  Widget _sectionHeader(String title, String subtitle) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        if (subtitle.isNotEmpty)
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: kBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(subtitle, style: const TextStyle(
                  color: kBlue, fontSize: 10, fontWeight: FontWeight.w600))),
      ]);

  Widget _cycleCard(Map c, bool isSmall) {
    final statut = c['statut'] ?? '';
    final isActif = statut == 'actif' || statut == 'en_cours';
    final color = isActif ? const Color(0xFF10B981) : Colors.grey;
    return Container(
      width: isSmall ? 130 : 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(isActif ? Icons.pets_rounded : Icons.check_circle_rounded,
              color: color, size: 20),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(statut, style: TextStyle(
                  color: color, fontSize: 8, fontWeight: FontWeight.w700))),
        ]),
        const Spacer(),
        Text(c['nom'] ?? 'Cycle', style: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF1E293B)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('${c['nombre_sujets'] ?? 0} sujets',
            style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ]),
    );
  }

  Widget _meteoCard() {
    final humidity = _meteo['main']?['humidity'] ?? 0;
    final windSpeed = (_meteo['wind']?['speed'] ?? 0).toStringAsFixed(1);
    final temp = (_meteo['main']?['temp'] ?? 0).toStringAsFixed(1);
    final tempVal = double.tryParse(temp) ?? 0;
    final color = tempVal > 35 ? kRed : tempVal > 30 ? kOrange : kGreen;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)]),
      child: Row(children: [
        const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 40),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$temp°C', style: const TextStyle(
              color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          Text(_meteo['weather']?[0]?['description'] ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _meteoChip(Icons.water_drop_rounded, '$humidity%'),
          const SizedBox(height: 4),
          _meteoChip(Icons.air_rounded, '${windSpeed}m/s'),
        ]),
      ]),
    );
  }

  Widget _meteoChip(IconData icon, String value) => Row(children: [
    Icon(icon, color: Colors.white70, size: 12),
    const SizedBox(width: 3),
    Text(value, style: const TextStyle(
        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
  ]);

  Widget _donneeCard(Map d, bool isSmall) {
    final mortalite = ((d['mortalite'] ?? 0) as num).toInt();
    final production = ((d['production'] ?? 0) as num).toInt();
    final temp = ((d['temperature'] ?? 0) as num).toDouble();
    final color = mortalite > 10 ? kRed : mortalite > 5 ? kOrange : kGreen;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d['date_releve'] ?? '-', style: TextStyle(
              fontWeight: FontWeight.w700, color: color, fontSize: 11)),
          const SizedBox(height: 3),
          Row(children: [
            _chip(Icons.inventory_rounded, '$production', kPurple),
            const SizedBox(width: 4),
            _chip(Icons.thermostat_rounded, '${temp.toStringAsFixed(0)}°', kOrange),
          ]),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(Icons.warning_rounded, color: color, size: 14),
              const SizedBox(width: 3),
              Text('$mortalite', style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 14, color: color)),
            ])),
      ]),
    );
  }

  Widget _chip(IconData icon, String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 2),
        Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]));

  Widget _alerteCard(Map a) {
    final type = a['type'] ?? 'info';
    final color = type == 'danger' ? kRed : type == 'warning' ? kOrange : kBlue;
    final icon = type == 'danger' ? Icons.dangerous_rounded
        : type == 'warning' ? Icons.warning_rounded : Icons.info_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 16)),
        const SizedBox(width: 10),
        Expanded(child: Text(a['titre'] ?? a['message'] ?? '',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: color))),
        Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.5), size: 12),
      ]),
    );
  }
}