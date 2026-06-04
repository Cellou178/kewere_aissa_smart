import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import '../../managers/session_manager.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List _cycles = [];
  List _donnees = [];
  List _fermes = [];
  List _employes = [];
  List _stocks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getCycles(),
      ApiService.getDonnees(),
      ApiService.getFermes(),
      ApiService.getEmployes(),
      ApiService.getStocks(),
    ]);
    setState(() {
      _cycles = results[0] is List ? results[0] as List : [];
      _donnees = results[1] is List ? results[1] as List : [];
      _fermes = results[2] is List ? results[2] as List : [];
      _employes = results[3] is List ? results[3] as List : [];
      _stocks = results[4] is List ? results[4] as List : [];
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
  double get _masseSalariale => _employes.fold<double>(0, (s, e) =>
  s + ((e['salaire'] ?? 0) as num).toDouble());

  int get _scoreGlobal {
    int score = 100;
    if (_tauxMortalite > 5) score -= 20;
    if (_tauxMortalite > 10) score -= 20;
    if (_avgTemp > 33) score -= 15;
    if (_avgHum > 75) score -= 10;
    if (_stocksEnAlerte > 0) score -= 10;
    if (_cyclesActifs == 0) score -= 15;
    return score.clamp(0, 100);
  }

  Color get _scoreColor => _scoreGlobal >= 80 ? kGreen
      : _scoreGlobal >= 60 ? kOrange : kRed;

  String _formatFcfa(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        // Header
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A5F),
                Color(0xFF2563EB)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            Row(children: [
              if (Navigator.canPop(context)) IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
              const Icon(Icons.bar_chart_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Statistiques Globales', style: TextStyle(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w900)),
                    Text(SessionManager.prenomNom,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ])),
              IconButton(icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white54, size: 20), onPressed: _load),
            ]),
            const SizedBox(height: 12),

            // Stats rapides
            Row(children: [
              _headerStat('${_fermes.length}', 'Fermes', Colors.white),
              _headerStat('$_cyclesActifs', 'Actifs',
                  Colors.greenAccent),
              _headerStat('$_totalPoulets', 'Poulets',
                  Colors.orangeAccent),
              _headerStat('${_scoreGlobal}%', 'Score',
                  _scoreGlobal >= 80 ? Colors.greenAccent
                      : Colors.redAccent),
            ]),
            const SizedBox(height: 12),

            TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 11),
              tabs: const [
                Tab(text: '📊 Général'),
                Tab(text: '🐔 Production'),
                Tab(text: '💰 Finance'),
              ],
            ),
          ]),
        ),

        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlue))
            : TabBarView(controller: _tabCtrl, children: [
          _buildGeneral(),
          _buildProduction(),
          _buildFinance(),
        ])),
      ]),
    );
  }

  Widget _buildGeneral() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      // Score
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [_scoreColor.withOpacity(0.8), _scoreColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
                color: _scoreColor.withOpacity(0.3), blurRadius: 16)]),
        child: Row(children: [
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Score Global', style: TextStyle(
                color: Colors.white70, fontSize: 12)),
            Text('${_scoreGlobal}/100', style: const TextStyle(
                color: Colors.white, fontSize: 32,
                fontWeight: FontWeight.w900)),
            Text(_scoreGlobal >= 80 ? 'Excellent 🎉'
                : _scoreGlobal >= 60 ? 'Bon 👍' : 'À améliorer ⚠️',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12)),
          ])),
          SizedBox(width: 70, height: 70,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                    value: _scoreGlobal / 100, strokeWidth: 7,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white)),
                Text('${_scoreGlobal}%', style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900,
                    fontSize: 12)),
              ])),
        ]),
      ),
      const SizedBox(height: 16),

      // KPIs
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10, crossAxisSpacing: 10,
        childAspectRatio: 1.8,
        children: [
          _kpiCard('🏡 Fermes', '${_fermes.length}', kBlue),
          _kpiCard('🔄 Cycles', '$_totalCycles', kGreen),
          _kpiCard('🐔 Poulets', '$_totalPoulets', kOrange),
          _kpiCard('💀 Mortalité',
              '${_tauxMortalite.toStringAsFixed(1)}%',
              _tauxMortalite > 5 ? kRed : kGreen),
          _kpiCard('🌡️ Temp. moy.',
              '${_avgTemp.toStringAsFixed(1)}°C', kOrange),
          _kpiCard('👥 Employés',
              '${_employes.length}', kPurple),
        ],
      ),
    ]),
  );

  int get _totalCycles => _cycles.length;

  Widget _buildProduction() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      Row(children: [
        _statCard('📦 Production', '$_totalProd', kGreen),
        const SizedBox(width: 10),
        _statCard('💀 Morts', '$_totalMorts', kRed),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _statCard('📊 Relevés', '${_donnees.length}', kBlue),
        const SizedBox(width: 10),
        _statCard('📦 Stocks alerte',
            '$_stocksEnAlerte', kOrange),
      ]),
      const SizedBox(height: 16),

      _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🏆 Top Cycles', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14,
            color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        ...(_cycles.toList()
          ..sort((a, b) => ((b['nombre_sujets'] ?? 0) as num)
              .compareTo((a['nombre_sujets'] ?? 0) as num)))
            .take(5).map((c) {
          final sujets = ((c['nombre_sujets'] ?? 0) as num).toInt();
          final isActif = c['statut'] == 'actif' ||
              c['statut'] == 'en_cours';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Text(isActif ? '🐔' : '✅',
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(child: Text(c['nom'] ?? '',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600))),
              Text('$sujets sujets',
                  style: const TextStyle(
                      color: kBlue, fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ]),
          );
        }),
      ])),
    ]),
  );

  Widget _buildFinance() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('💰 Résumé Financier', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14,
            color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        _finRow('Poulets totaux', '$_totalPoulets têtes', kBlue),
        _finRow('Survivants',
            '${_totalPoulets - _totalMorts} têtes', kGreen),
        _finRow('Taux mortalité',
            '${_tauxMortalite.toStringAsFixed(1)}%',
            _tauxMortalite > 5 ? kRed : kGreen),
        _finRow('Masse salariale',
            '${_formatFcfa(_masseSalariale)} FCFA/mois', kPurple),
        _finRow('Employés', '${_employes.length}', kBlue),
        _finRow('Stocks en alerte', '$_stocksEnAlerte', kOrange),
      ])),
      const SizedBox(height: 16),

      _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🏡 Par Ferme', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14,
            color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        ..._fermes.map((f) {
          final id = f['id']?.toString();
          final cyclesFerme = _cycles.where((c) =>
          c['ferme_id']?.toString() == id).length;
          final poultsFerme = _cycles
              .where((c) => c['ferme_id']?.toString() == id &&
              (c['statut'] == 'actif' ||
                  c['statut'] == 'en_cours'))
              .fold<int>(0, (s, c) =>
          s + ((c['nombre_sujets'] ?? 0) as num).toInt());
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              const Text('🏡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(child: Text(f['nom'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13))),
              Column(crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$cyclesFerme cycles',
                        style: const TextStyle(
                            color: kBlue, fontSize: 11,
                            fontWeight: FontWeight.w700)),
                    Text('$poultsFerme poulets',
                        style: const TextStyle(
                            color: kOrange, fontSize: 10)),
                  ]),
            ]),
          );
        }),
      ])),
    ]),
  );

  Widget _kpiCard(String title, String value, Color color) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                  color: Colors.grey, fontSize: 10)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 18, color: color)),
            ]),
      );

  Widget _statCard(String title, String value, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                  color: Colors.grey, fontSize: 10)),
              Text(value, style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 16, color: color)),
            ]),
      ));

  Widget _finRow(String label, String value, Color color) =>
      Padding(padding: const EdgeInsets.only(bottom: 8),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
                Text(value, style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12,
                    color: color)),
              ]));

  Widget _headerStat(String value, String label, Color color) =>
      Expanded(child: Column(children: [
        Text(value, style: TextStyle(
            color: color, fontSize: 14, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(
            color: Colors.white38, fontSize: 9)),
      ]));

  Widget _card({required Widget child}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: child);
}