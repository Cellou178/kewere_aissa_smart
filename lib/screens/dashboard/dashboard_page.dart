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
  List _alertes = [];
  Map _meteo = {};
  bool _loading = true;

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
    final meteoDesc = _meteo.isNotEmpty ?
    (_meteo['weather']?[0]?['description'] ?? '') : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: RefreshIndicator(
        onRefresh: _load, color: kBlue,
        child: CustomScrollView(
          slivers: [
            // ── HEADER SOMBRE ──
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF0F172A), Color(0xFF1E3A5F), Color(0xFF1B3A6B)],
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Top row
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Bonjour, ${SessionManager.nom.isNotEmpty ? SessionManager.nom.split(' ').first : 'Propriétaire'} 👋',
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text('Kewere Aissa Smart', style: TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                    ]),
                    Row(children: [
                      if (_meteo.isNotEmpty) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [
                          const Text('🌤️', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('$temp°C', style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                            Text(meteoDesc, style: const TextStyle(color: Colors.white60, fontSize: 9)),
                          ]),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                          onPressed: _load),
                    ]),
                  ]),
                  const SizedBox(height: 24),
                  // KPI Cards
                  Row(children: [
                    _kpiCard('🐔', '$totalPoulets', 'Poulets', const Color(0xFF3B82F6)),
                    const SizedBox(width: 12),
                    _kpiCard('🔄', '$cyclesActifs', 'Cycles actifs', const Color(0xFF10B981)),
                    const SizedBox(width: 12),
                    _kpiCard('💀', '$totalMorts', 'Mortalité', const Color(0xFFEF4444)),
                    const SizedBox(width: 12),
                    _kpiCard('📦', '$dernierProd', 'Production', const Color(0xFF8B5CF6)),
                  ]),
                ]),
              ),
            ),

            // ── CONTENU CLAIR ──
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(delegate: SliverChildListDelegate([

                // Cycles récents
                if (_cycles.isNotEmpty) ...[
                  _sectionHeader('🔄 Cycles Récents', '${_cycles.length} total'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _cycles.take(5).length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _cycleCard(_cycles[i]),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Météo détaillée
                if (_meteo.isNotEmpty) ...[
                  _sectionHeader('🌤️ Météo Mbour', 'Aujourd\'hui'),
                  const SizedBox(height: 12),
                  _meteoCard(),
                  const SizedBox(height: 20),
                ],

                // Dernières données
                if (_donnees.isNotEmpty) ...[
                  _sectionHeader('📊 Données Récentes', '${_donnees.length} entrées'),
                  const SizedBox(height: 12),
                  ..._donnees.reversed.take(5).map((d) => _donneeCard(d)),
                  const SizedBox(height: 20),
                ],

                // Alertes
                if (_alertes.isNotEmpty) ...[
                  _sectionHeader('🚨 Alertes', '${_alertes.length} alerte(s)'),
                  const SizedBox(height: 12),
                  ..._alertes.take(3).map((a) => _alerteCard(a)),
                ],

                const SizedBox(height: 20),
              ])),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(String emoji, String value, String label, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: Colors.white60, fontSize: 10)),
        ]),
      ));

  Widget _sectionHeader(String title, String subtitle) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: kBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(subtitle, style: const TextStyle(
                color: kBlue, fontSize: 11, fontWeight: FontWeight.w600))),
      ]);

  Widget _cycleCard(Map c) {
    final statut = c['statut'] ?? '';
    final isActif = statut == 'actif' || statut == 'en_cours';
    final color = isActif ? const Color(0xFF10B981) : Colors.grey;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(isActif ? '🐔' : '✅', style: const TextStyle(fontSize: 24)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(statut, style: TextStyle(
                  color: color, fontSize: 9, fontWeight: FontWeight.w700))),
        ]),
        const Spacer(),
        Text(c['nom'] ?? 'Cycle', style: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('${c['nombre_sujets'] ?? 0} sujets',
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ]),
    );
  }

  Widget _meteoCard() {
    final humidity = _meteo['main']?['humidity'] ?? 0;
    final windSpeed = (_meteo['wind']?['speed'] ?? 0).toStringAsFixed(1);
    final tempMax = (_meteo['main']?['temp_max'] ?? 0).toStringAsFixed(0);
    final tempMin = (_meteo['main']?['temp_min'] ?? 0).toStringAsFixed(0);
    final temp = (_meteo['main']?['temp'] ?? 0).toStringAsFixed(1);
    final tempVal = double.tryParse(temp) ?? 0;
    final color = tempVal > 35 ? kRed : tempVal > 30 ? kOrange : kGreen;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color.withOpacity(0.5)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Row(children: [
        const Text('🌤️', style: TextStyle(fontSize: 48)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$temp°C', style: const TextStyle(
              color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          Text(_meteo['weather']?[0]?['description'] ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _meteoInfo('💧', '$humidity%'),
          _meteoInfo('💨', '${windSpeed}m/s'),
          _meteoInfo('↕️', '$tempMin-$tempMax°'),
        ]),
      ]),
    );
  }

  Widget _meteoInfo(String emoji, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ]));

  Widget _donneeCard(Map d) {
    final mortalite = ((d['mortalite'] ?? 0) as num).toInt();
    final production = ((d['production'] ?? 0) as num).toInt();
    final temp = ((d['temperature'] ?? 0) as num).toDouble();
    final color = mortalite > 10 ? kRed : mortalite > 5 ? kOrange : kGreen;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d['date_releve'] ?? '-',
              style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 12)),
          const SizedBox(height: 4),
          Row(children: [
            _donneeChip('📦 $production', kPurple),
            const SizedBox(width: 6),
            _donneeChip('🌡️ ${temp.toStringAsFixed(0)}°', kOrange),
          ]),
        ]),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              Text('$mortalite', style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 18, color: color)),
              Text('morts', style: TextStyle(color: color, fontSize: 9)),
            ])),
      ]),
    );
  }

  Widget _donneeChip(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(
          color: color, fontSize: 11, fontWeight: FontWeight.w600)));

  Widget _alerteCard(Map a) {
    final type = a['type'] ?? 'info';
    final color = type == 'danger' ? kRed : type == 'warning' ? kOrange : kBlue;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Container(width: 40, height: 40,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(
                type == 'danger' ? '🚨' : type == 'warning' ? '⚠️' : 'ℹ️',
                style: const TextStyle(fontSize: 18)))),
        const SizedBox(width: 12),
        Expanded(child: Text(a['titre'] ?? a['message'] ?? '',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color))),
      ]),
    );
  }
}