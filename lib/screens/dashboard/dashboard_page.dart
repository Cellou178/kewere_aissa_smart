import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../../services/api_service.dart';
import '../../widgets/dashboard_charts.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/app_transitions.dart';
import '../cycles/add_cycle_screen.dart';
import '../fermes/operations_screen.dart';
import '../stocks/add_stock_screen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List _cycles = [];
  List _donnees = [];
  List _alertes = [];
  List _stocks = [];
  List _employes = [];
  Map _meteo = {};
  bool _loading = true;
  bool _fabOpen = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getCycles(),
      ApiService.getDonnees(),
      ApiService.getAlertes(),
      ApiService.getMeteo('Mbour'),
      ApiService.getStocks(),
      ApiService.getEmployes(),
    ]);
    setState(() {
      _cycles = results[0] is List ? results[0] as List : [];
      _donnees = results[1] is List ? results[1] as List : [];
      _alertes = results[2] is List ? results[2] as List : [];
      _meteo = results[3] is Map ? results[3] as Map : {};
      _stocks = results[4] is List ? results[4] as List : [];
      _employes = results[5] is List ? results[5] as List : [];
      _loading = false;
    });
  }

  int get _cyclesActifs => _cycles.where((c) =>
  c['statut'] == 'actif' || c['statut'] == 'en_cours').length;
  int get _totalPoulets => _cycles.fold<int>(0, (s, c) =>
  s + ((c['nombre_sujets'] ?? 0) as num).toInt());
  int get _totalMorts => _donnees.fold<int>(0, (s, d) =>
  s + ((d['mortalite'] ?? 0) as num).toInt());
  double get _tauxMortalite => _totalPoulets > 0
      ? (_totalMorts / _totalPoulets * 100) : 0;
  double get _avgTemp => _donnees.isEmpty ? 0 :
  _donnees.fold<double>(0, (s, d) =>
  s + ((d['temperature'] ?? 0) as num).toDouble()) / _donnees.length;
  double get _avgHum => _donnees.isEmpty ? 0 :
  _donnees.fold<double>(0, (s, d) =>
  s + ((d['humidite'] ?? 0) as num).toDouble()) / _donnees.length;
  int get _totalProd => _donnees.fold<int>(0, (s, d) =>
  s + ((d['production'] ?? 0) as num).toInt());
  int get _stocksEnAlerte => _stocks.where((s) {
    final qte = ((s['quantite'] ?? 0) as num).toDouble();
    final seuil = ((s['seuil_alerte'] ?? 0) as num).toDouble();
    return qte <= seuil;
  }).length;
  int get _alertesCritiques => _alertes.where((a) =>
  a['type'] == 'danger').length;
  double get _masseSalariale => _employes.fold<double>(0, (s, e) =>
  s + ((e['salaire'] ?? 0) as num).toDouble());

  int get _scorePerformance {
    int score = 100;
    if (_tauxMortalite > 5) score -= 20;
    if (_tauxMortalite > 10) score -= 20;
    if (_avgTemp > 33) score -= 15;
    if (_avgHum > 75) score -= 10;
    if (_stocksEnAlerte > 0) score -= 10;
    if (_alertesCritiques > 0) score -= 15;
    return score.clamp(0, 100);
  }

  Color get _scoreColor => _scorePerformance >= 80 ? kGreen
      : _scorePerformance >= 60 ? kOrange : kRed;

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    if (_loading) return const Scaffold(
      backgroundColor: kBg,
      body: Center(child: CircularProgressIndicator(color: kBlue)),
    );

    final temp = _meteo.isNotEmpty
        ? (_meteo['main']?['temp'] ?? 0).toStringAsFixed(0) : '--';
    final humidity = _meteo.isNotEmpty
        ? (_meteo['main']?['humidity'] ?? 0) : '--';

    return Scaffold(
      backgroundColor: kBg,
      floatingActionButton: _buildFAB(context),
      body: RefreshIndicator(
        onRefresh: _load, color: kBlue,
        child: CustomScrollView(slivers: [

          // ── HEADER COMPACT ──
          SliverToBoxAdapter(child: Container(
            decoration: const BoxDecoration(
              gradient: kGradientDark,
              borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
                r.horizontalPadding, 12,
                r.horizontalPadding, 20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

              // Greeting + météo
              Row(mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment:
                    CrossAxisAlignment.start, children: [
                  Text('Bonjour, ${SessionManager.prenomNom} 👋',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12)),
                  const Text('Tableau de bord',
                      style: TextStyle(color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                ]),
                Row(children: [
                  if (_meteo.isNotEmpty) Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.wb_sunny_rounded,
                          color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text('$temp°C · $humidity%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ]),
                  ),
                  IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white54, size: 18),
                      onPressed: _load),
                ]),
              ]),

              // Alerte critique
              if (_alertesCritiques > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: kRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: kRed.withOpacity(0.4))),
                  child: Row(children: [
                    const Icon(Icons.warning_rounded,
                        color: Colors.redAccent, size: 14),
                    const SizedBox(width: 8),
                    Text('$_alertesCritiques alerte(s) critique(s) !',
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700,
                            fontSize: 11)),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.redAccent, size: 10),
                  ]),
                ),
              ],

              const SizedBox(height: 12),

              // KPI Cards
              Row(children: [
                _kpiCard(Icons.pets_rounded,
                    '$_totalPoulets', 'Poulets',
                    const Color(0xFF3B82F6), r),
                const SizedBox(width: 8),
                _kpiCard(Icons.loop_rounded,
                    '$_cyclesActifs', 'Actifs',
                    const Color(0xFF10B981), r),
                const SizedBox(width: 8),
                _kpiCard(Icons.warning_rounded,
                    '$_totalMorts', 'Morts',
                    const Color(0xFFEF4444), r),
                const SizedBox(width: 8),
                _kpiCard(Icons.inventory_rounded,
                    '$_totalProd', 'Prod.',
                    const Color(0xFF8B5CF6), r),
              ]),
            ]),
          )),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                r.horizontalPadding, 16,
                r.horizontalPadding, 80),
            sliver: SliverList(
                delegate: SliverChildListDelegate([

              // ── STATS COLORÉES ──
              _sectionHeader('📊 Statistiques', ''),
              const SizedBox(height: 10),
              Row(children: [
                _statCard('Mortalité',
                    '${_tauxMortalite.toStringAsFixed(1)}%',
                    _tauxMortalite > 5 ? kRed : kGreen,
                    Icons.trending_down_rounded),
                const SizedBox(width: 10),
                _statCard('Température',
                    '${_avgTemp.toStringAsFixed(1)}°C',
                    _avgTemp > 33 ? kRed : kOrange,
                    Icons.thermostat_rounded),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _statCard('Humidité',
                    '${_avgHum.toStringAsFixed(1)}%',
                    _avgHum > 75 ? kOrange : kBlue,
                    Icons.water_drop_rounded),
                const SizedBox(width: 10),
                _statCard('Stocks',
                    '$_stocksEnAlerte alertes',
                    _stocksEnAlerte > 0 ? kRed : kGreen,
                    Icons.inventory_rounded),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _statCard('Employés',
                    '${_employes.length} actifs',
                    kPurple, Icons.people_rounded),
                const SizedBox(width: 10),
                _statCard('Masse sal.',
                    '${(_masseSalariale / 1000).toStringAsFixed(0)}K FCFA',
                    kGreen,
                    Icons.account_balance_wallet_rounded),
              ]),
              const SizedBox(height: 20),

              // ── SCORE PERFORMANCE ──
              _scoreCard(),
              const SizedBox(height: 20),

              // ── ACTIONS RAPIDES ──
              _sectionHeader('⚡ Actions Rapides', ''),
              const SizedBox(height: 10),
              Row(children: [
                _quickAction(Icons.add_circle_rounded,
                    'Nouveau\nCycle', kBlue, () async {
                      final result = await Navigator.push(context,
                          AppTransitions.slideFade(
                              const AddCycleScreen()));
                      if (result == true) _load();
                    }),
                const SizedBox(width: 8),
                _quickAction(Icons.assignment_add,
                    'Saisir\nDonnées', kGreen, () {
                      if (_cycles.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Créez d\'abord un cycle'),
                                backgroundColor: Colors.orange));
                        return;
                      }
                      Navigator.push(context,
                          AppTransitions.slideFade(OperationsScreen(
                              ferme: {}, cycles: _cycles)));
                    }),
                const SizedBox(width: 8),
                _quickAction(Icons.add_box_rounded,
                    'Ajouter\nStock', kOrange, () async {
                      final result = await Navigator.push(context,
                          AppTransitions.slideFade(
                              const AddStockScreen()));
                      if (result == true) _load();
                    }),
                const SizedBox(width: 8),
                _quickAction(Icons.refresh_rounded,
                    'Actualiser', Colors.grey, _load),
              ]),
              const SizedBox(height: 20),

              // ── GRAPHIQUE ──
              if (_donnees.isNotEmpty) ...[
                _sectionHeader('📈 Mortalité', ''),
                const SizedBox(height: 10),
                MortaliteChart(donnees: _donnees),
                const SizedBox(height: 20),
              ],

              // ── CYCLES ──
              if (_cycles.isNotEmpty) ...[
                _sectionHeader('🔄 Cycles',
                    '${_cycles.length}'),
                const SizedBox(height: 10),
                SizedBox(height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _cycles.take(5).length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(width: 10),
                      itemBuilder: (_, i) =>
                          _cycleCard(_cycles[i], r),
                    )),
                const SizedBox(height: 20),
              ],

              // ── STOCKS EN ALERTE ──
              if (_stocksEnAlerte > 0) ...[
                _sectionHeader('⚠️ Stocks en alerte',
                    '$_stocksEnAlerte'),
                const SizedBox(height: 10),
                ..._stocks.where((s) {
                  final qte = ((s['quantite'] ?? 0) as num)
                      .toDouble();
                  final seuil = ((s['seuil_alerte'] ?? 0) as num)
                      .toDouble();
                  return qte <= seuil;
                }).take(3).map((s) => _stockAlerteCard(s)),
                const SizedBox(height: 20),
              ],

              // ── ALERTES ──
              if (_alertes.isNotEmpty) ...[
                _sectionHeader('🚨 Alertes',
                    '${_alertes.length}'),
                const SizedBox(height: 10),
                ..._alertes.take(3).map(
                        (a) => _alerteCard(a)),
                const SizedBox(height: 20),
              ],

              // ── MÉTÉO ──
              if (_meteo.isNotEmpty) ...[
                _sectionHeader('🌤️ Météo', 'Mbour'),
                const SizedBox(height: 10),
                _meteoCard(),
                const SizedBox(height: 20),
              ],

              // ── DONNÉES RÉCENTES ──
              if (_donnees.isNotEmpty) ...[
                _sectionHeader('📊 Données récentes',
                    '${_donnees.length}'),
                const SizedBox(height: 10),
                ..._donnees.reversed.take(3).map(
                        (d) => _donneeCard(d, r)),
              ],
            ])),
          ),
        ]),
      ),
    );
  }

  // ── SCORE CARD ──
  Widget _scoreCard() {
    final score = _scorePerformance;
    final color = _scoreColor;
    final label = score >= 80 ? 'Excellent 🎉'
        : score >= 60 ? 'Bon 👍' : 'À améliorer ⚠️';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10)]),
      child: Row(children: [
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const Text('Score de performance',
              style: TextStyle(color: Colors.grey,
                  fontSize: 12)),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.end,
              children: [
            Text('$score', style: TextStyle(
                color: color, fontSize: 36,
                fontWeight: FontWeight.w900)),
            Text('/100', style: TextStyle(
                color: color.withOpacity(0.6),
                fontSize: 14)),
          ]),
          Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(label, style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11))),
          const SizedBox(height: 10),
          Row(children: [
            _scoreIndicateur('Mortalité',
                _tauxMortalite <= 5),
            _scoreIndicateur('Temp.',
                _avgTemp <= 33),
            _scoreIndicateur('Stocks',
                _stocksEnAlerte == 0),
            _scoreIndicateur('Alertes',
                _alertesCritiques == 0),
          ]),
        ])),
        const SizedBox(width: 16),
        SizedBox(width: 80, height: 80,
            child: Stack(alignment: Alignment.center,
                children: [
              CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(color)),
              Text('$score%', style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 13)),
            ])),
      ]),
    );
  }

  Widget _scoreIndicateur(String label, bool ok) =>
      Expanded(child: Column(children: [
        Icon(ok ? Icons.check_circle_rounded
            : Icons.cancel_rounded,
            color: ok ? kGreen : kRed, size: 14),
        Text(label, style: TextStyle(
            color: ok ? kGreen : kRed, fontSize: 8)),
      ]));

  Widget _kpiCard(IconData icon, String value,
      String label, Color color, Responsive r) =>
      Expanded(child: Container(
        padding: EdgeInsets.all(r.cardPadding),
        decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(r.borderRadius),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Icon(icon, color: color, size: r.iconSm),
          SizedBox(height: r.isSmallPhone ? 4 : 6),
          Text(value, style: TextStyle(
              color: Colors.white, fontSize: r.fontLg,
              fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(
              color: Colors.white60, fontSize: r.fontXS)),
        ]),
      ));

  Widget _statCard(String title, String value,
      Color color, IconData icon) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(
                color: color, width: 3)),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8)]),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(title, style: const TextStyle(
                color: Colors.grey, fontSize: 10)),
            Text(value, style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13, color: color)),
          ])),
        ]),
      ));

  Widget _quickAction(IconData icon, String label,
      Color color, VoidCallback onTap) =>
      Expanded(child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8)]),
          child: Column(children: [
            Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
                color: color, fontSize: 9,
                fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
          ]),
        ),
      ));

  Widget _sectionHeader(String title, String subtitle) =>
      Row(mainAxisAlignment:
          MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B))),
        if (subtitle.isNotEmpty) Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: kBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(subtitle, style: const TextStyle(
                color: kBlue, fontSize: 10,
                fontWeight: FontWeight.w600))),
      ]);

  Widget _cycleCard(Map c, Responsive r) {
    final statut = c['statut'] ?? '';
    final isActif = statut == 'actif' || statut == 'en_cours';
    final color = isActif ? kGreen : Colors.grey;
    return Container(
      width: r.isMobile ? 130 : 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8)]),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(mainAxisAlignment:
            MainAxisAlignment.spaceBetween, children: [
          Icon(isActif ? Icons.pets_rounded
              : Icons.check_circle_rounded,
              color: color, size: 20),
          Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(statut, style: TextStyle(
                  color: color, fontSize: 8,
                  fontWeight: FontWeight.w700))),
        ]),
        const Spacer(),
        Text(c['nom'] ?? 'Cycle',
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 12,
                color: Color(0xFF1E293B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        Text('${c['nombre_sujets'] ?? 0} sujets',
            style: const TextStyle(
                color: Colors.grey, fontSize: 10)),
      ]),
    );
  }

  Widget _stockAlerteCard(Map s) {
    final qte = ((s['quantite'] ?? 0) as num).toDouble();
    final seuil = ((s['seuil_alerte'] ?? 0) as num).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kRed.withOpacity(0.25)),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6)]),
      child: Row(children: [
        const Icon(Icons.inventory_rounded, color: kRed, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(s['produit'] ?? '',
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13))),
        Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: kRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text(
                '$qte/${seuil.toInt()} ${s['unite'] ?? ''}',
                style: const TextStyle(color: kRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget _meteoCard() {
    final humidity = _meteo['main']?['humidity'] ?? 0;
    final windSpeed = (_meteo['wind']?['speed'] ?? 0)
        .toStringAsFixed(1);
    final temp = (_meteo['main']?['temp'] ?? 0)
        .toStringAsFixed(1);
    final tempVal = double.tryParse(temp) ?? 0;
    final color = tempVal > 35 ? kRed
        : tempVal > 30 ? kOrange : kGreen;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle),
            child: Icon(Icons.wb_sunny_rounded,
                color: color, size: 32)),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text('$temp°C', style: TextStyle(
              color: color, fontSize: 28,
              fontWeight: FontWeight.w900)),
          Text(_meteo['weather']?[0]?['description'] ?? '',
              style: const TextStyle(
                  color: Colors.grey, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end,
            children: [
          _meteoChip(Icons.water_drop_rounded,
              '$humidity%', kBlue),
          const SizedBox(height: 4),
          _meteoChip(Icons.air_rounded,
              '${windSpeed}m/s', kTeal),
        ]),
      ]),
    );
  }

  Widget _meteoChip(IconData icon, String value,
      Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 3),
          Text(value, style: TextStyle(
              color: color, fontSize: 11,
              fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _donneeCard(Map d, Responsive r) {
    final mortalite = ((d['mortalite'] ?? 0) as num).toInt();
    final production = ((d['production'] ?? 0) as num).toInt();
    final temp = ((d['temperature'] ?? 0) as num).toDouble();
    final color = mortalite > 10 ? kRed
        : mortalite > 5 ? kOrange : kGreen;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(
              color: color, width: 3)),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6)]),
      child: Row(children: [
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(d['date_releve'] ?? '-',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color, fontSize: 11)),
          const SizedBox(height: 3),
          Row(children: [
            _chip(Icons.inventory_rounded,
                '$production', kPurple),
            const SizedBox(width: 4),
            _chip(Icons.thermostat_rounded,
                '${temp.toStringAsFixed(0)}°', kOrange),
          ]),
        ])),
        Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(Icons.warning_rounded, color: color, size: 14),
              const SizedBox(width: 3),
              Text('$mortalite', style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14, color: color)),
            ])),
      ]),
    );
  }

  Widget _chip(IconData icon, String text, Color color) =>
      Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 2),
            Text(text, style: TextStyle(
                color: color, fontSize: 10,
                fontWeight: FontWeight.w600)),
          ]));

  Widget _alerteCard(Map a) {
    final type = a['type'] ?? 'info';
    final color = type == 'danger' ? kRed
        : type == 'warning' ? kOrange : kBlue;
    final icon = type == 'danger'
        ? Icons.dangerous_rounded
        : type == 'warning' ? Icons.warning_rounded
        : Icons.info_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 16)),
        const SizedBox(width: 10),
        Expanded(child: Text(
            a['titre'] ?? a['message'] ?? '',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12, color: color))),
        Icon(Icons.arrow_forward_ios_rounded,
            color: color.withOpacity(0.5), size: 12),
      ]),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (_fabOpen) ...[
        _fabItem(Icons.add_circle_rounded,
            'Nouveau Cycle', kBlue, () async {
          setState(() => _fabOpen = false);
          final result = await Navigator.push(context,
              AppTransitions.slideFade(const AddCycleScreen()));
          if (result == true) _load();
        }),
        const SizedBox(height: 8),
        _fabItem(Icons.assignment_add, 'Saisir Données',
            kGreen, () {
          setState(() => _fabOpen = false);
          if (_cycles.isEmpty) return;
          Navigator.push(context, AppTransitions.slideFade(
              OperationsScreen(ferme: {}, cycles: _cycles)));
        }),
        const SizedBox(height: 8),
        _fabItem(Icons.add_box_rounded, 'Ajouter Stock',
            kOrange, () async {
          setState(() => _fabOpen = false);
          final result = await Navigator.push(context,
              AppTransitions.slideFade(const AddStockScreen()));
          if (result == true) _load();
        }),
        const SizedBox(height: 8),
      ],
      FloatingActionButton(
        onPressed: () => setState(() => _fabOpen = !_fabOpen),
        backgroundColor: kBlue,
        child: AnimatedRotation(
          turns: _fabOpen ? 0.125 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.add_rounded,
              color: Colors.white, size: 28),
        ),
      ),
    ]);
  }

  Widget _fabItem(IconData icon, String label,
      Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8)]),
            child: Text(label, style: TextStyle(
                color: color, fontWeight: FontWeight.w700,
                fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Container(width: 40, height: 40,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8)]),
              child: Icon(icon, color: Colors.white, size: 20)),
        ]),
      );
}