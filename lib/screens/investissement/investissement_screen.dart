import 'package:flutter/material.dart';
import 'dart:math';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import '../../managers/session_manager.dart';

class InvestissementScreen extends StatefulWidget {
  const InvestissementScreen({super.key});
  @override
  State<InvestissementScreen> createState() => _InvestissementScreenState();
}

class _InvestissementScreenState extends State<InvestissementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List _cycles = [];
  List _donnees = [];
  bool _loading = true;
  bool _loadingIA = false;
  String? _analyseIA;

  // Paramètres investissement
  double _capitalInitial = 500000;
  double _coutPoussin = 700;
  double _nombrePoussinsPrevus = 1000;
  double _prixVentePoulet = 3500;
  double _coutAlimentParPoussin = 8000;
  double _coutVeterinaireParPoussin = 500;
  double _coutMainOeuvre = 150000;
  double _coutLoyer = 50000;
  double _dureeJours = 45;
  double _tauxMortalitePrevue = 3.0;

  final List<Map<String, dynamic>> _simulations = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _load();
    _ajouterSimulation();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cycles = await ApiService.getCycles();
    final donnees = await ApiService.getDonnees();
    setState(() {
      _cycles = cycles is List ? cycles : [];
      _donnees = donnees is List ? donnees : [];
      _loading = false;
    });
  }

  // ── Calculs financiers ──
  double get _coutAchatPoussins => _nombrePoussinsPrevus * _coutPoussin;
  double get _coutAliment => _nombrePoussinsPrevus * _coutAlimentParPoussin;
  double get _coutVeterinaire => _nombrePoussinsPrevus * _coutVeterinaireParPoussin;
  double get _totalCharges => _coutAchatPoussins + _coutAliment +
      _coutVeterinaire + _coutMainOeuvre + _coutLoyer;
  double get _pouletsSurvivants => _nombrePoussinsPrevus *
      (1 - _tauxMortalitePrevue / 100);
  double get _revenuBrut => _pouletsSurvivants * _prixVentePoulet;
  double get _beneficeNet => _revenuBrut - _totalCharges;
  double get _roi => _totalCharges > 0
      ? (_beneficeNet / _totalCharges * 100) : 0;
  double get _seuilRentabilite => _totalCharges / _pouletsSurvivants;
  int get _nbCyclesParAn => (365 / _dureeJours).floor();
  double get _beneficeAnnuel => _beneficeNet * _nbCyclesParAn;
  double get _retourInvestissement => _capitalInitial > 0
      ? (_capitalInitial / _beneficeNet) : 0;

  void _ajouterSimulation() {
    setState(() => _simulations.add({
      'nom': 'Simulation ${_simulations.length + 1}',
      'date': DateTime.now().toString().split(' ')[0],
      'poussins': _nombrePoussinsPrevus,
      'prixVente': _prixVentePoulet,
      'charges': _totalCharges,
      'revenu': _revenuBrut,
      'benefice': _beneficeNet,
      'roi': _roi,
    }));
  }

  Future<void> _analyserInvestissement() async {
    setState(() { _loadingIA = true; _analyseIA = null; });
    try {
      final prompt = '''Tu es un expert en finance agricole et aviculture au Sénégal.
Analyse cet investissement avicole et donne des recommandations stratégiques.

PARAMÈTRES:
- Capital initial: ${_capitalInitial.toStringAsFixed(0)} FCFA
- Nombre de poussins: ${_nombrePoussinsPrevus.toInt()}
- Prix achat poussin: ${_coutPoussin.toStringAsFixed(0)} FCFA
- Prix vente poulet: ${_prixVentePoulet.toStringAsFixed(0)} FCFA
- Coût aliment/poussin: ${_coutAlimentParPoussin.toStringAsFixed(0)} FCFA
- Main d'œuvre/mois: ${_coutMainOeuvre.toStringAsFixed(0)} FCFA
- Durée cycle: ${_dureeJours.toInt()} jours
- Taux mortalité prévu: ${_tauxMortalitePrevue.toStringAsFixed(1)}%

RÉSULTATS CALCULÉS:
- Total charges: ${_totalCharges.toStringAsFixed(0)} FCFA
- Revenu brut: ${_revenuBrut.toStringAsFixed(0)} FCFA
- Bénéfice net: ${_beneficeNet.toStringAsFixed(0)} FCFA
- ROI: ${_roi.toStringAsFixed(1)}%
- Cycles/an: $_nbCyclesParAn
- Bénéfice annuel: ${_beneficeAnnuel.toStringAsFixed(0)} FCFA

Donne une analyse incluant:
1. Évaluation de la rentabilité
2. Risques principaux
3. Optimisations possibles
4. Comparaison avec les normes du marché sénégalais
5. Recommandations concrètes

En français, pratique et chiffré.''';

      final reponse = await ApiService.callIA(prompt,
          contexte: 'Expert rentabilité avicole Sénégal. Analyse chiffrée et recommandations.');
      setState(() => _analyseIA = reponse.isEmpty ? 'Analyse indisponible.' : reponse);
    } catch (e) {
      setState(() => _analyseIA = 'Analyse indisponible.');
    }
    setState(() => _loadingIA = false);
  }

  String _formatFcfa(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M FCFA';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(0)}K FCFA';
    return '${v.toStringAsFixed(0)} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final isRentable = _beneficeNet > 0;
    final roiColor = _roi >= 20 ? kGreen : _roi >= 10 ? kOrange : kRed;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(children: [
        // Header
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isRentable
                  ? [const Color(0xFF0F172A), const Color(0xFF166534)]
                  : [const Color(0xFF0F172A), const Color(0xFF7F1D1D)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            Row(children: [
              const Text('📈', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Investissement', style: TextStyle(
                    color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w900)),
                Text('Simulateur & Analyse financière',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
              ])),
              IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.white54, size: 20),
                  onPressed: _load),
            ]),
            const SizedBox(height: 12),

            // KPIs rapides
            Row(children: [
              _headerStat(_formatFcfa(_beneficeNet), 'Bénéfice\nnet',
                  isRentable ? Colors.greenAccent : Colors.redAccent),
              _headerStat('${_roi.toStringAsFixed(1)}%', 'ROI',
                  _roi >= 20 ? Colors.greenAccent
                      : _roi >= 10 ? Colors.amber : Colors.redAccent),
              _headerStat('$_nbCyclesParAn', 'Cycles\n/an', Colors.white),
              _headerStat(_formatFcfa(_beneficeAnnuel), 'Bénéfice\nannuel',
                  Colors.amber),
            ]),
            const SizedBox(height: 12),

            TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              isScrollable: true,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 11),
              tabs: const [
                Tab(text: '🧮 Simulateur'),
                Tab(text: '📊 Résultats'),
                Tab(text: '📋 Historique'),
                Tab(text: '🤖 Analyse IA'),
              ],
            ),
          ]),
        ),

        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlue))
            : TabBarView(controller: _tabCtrl, children: [
          _buildSimulateur(),
          _buildResultats(),
          _buildHistorique(),
          _buildAnalyseIA(),
        ])),
      ]),
    );
  }

  // ── SIMULATEUR ──
  Widget _buildSimulateur() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🐥 Paramètres de base', style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14,
                color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            _slider('Capital initial (FCFA)',
                _capitalInitial, 100000, 5000000, (v) =>
                    setState(() => _capitalInitial = v)),
            _slider('Nombre de poussins',
                _nombrePoussinsPrevus, 100, 5000, (v) =>
                    setState(() => _nombrePoussinsPrevus = v)),
            _slider('Durée cycle (jours)',
                _dureeJours, 30, 60, (v) =>
                    setState(() => _dureeJours = v)),
            _slider('Taux mortalité prévu (%)',
                _tauxMortalitePrevue, 0, 15, (v) =>
                    setState(() => _tauxMortalitePrevue = v)),
          ])),
      const SizedBox(height: 12),

      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💰 Prix', style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14,
                color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            _slider('Prix poussin (FCFA)',
                _coutPoussin, 300, 1500, (v) =>
                    setState(() => _coutPoussin = v)),
            _slider('Prix vente poulet (FCFA)',
                _prixVentePoulet, 1500, 6000, (v) =>
                    setState(() => _prixVentePoulet = v)),
          ])),
      const SizedBox(height: 12),

      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💸 Charges', style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14,
                color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            _slider('Aliment/poussin (FCFA)',
                _coutAlimentParPoussin, 3000, 15000, (v) =>
                    setState(() => _coutAlimentParPoussin = v)),
            _slider('Vétérinaire/poussin (FCFA)',
                _coutVeterinaireParPoussin, 100, 2000, (v) =>
                    setState(() => _coutVeterinaireParPoussin = v)),
            _slider('Main d\'œuvre/mois (FCFA)',
                _coutMainOeuvre, 50000, 500000, (v) =>
                    setState(() => _coutMainOeuvre = v)),
            _slider('Loyer/mois (FCFA)',
                _coutLoyer, 0, 200000, (v) =>
                    setState(() => _coutLoyer = v)),
          ])),
      const SizedBox(height: 16),

      Row(children: [
        Expanded(child: ElevatedButton.icon(
            onPressed: () {
              _ajouterSimulation();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('✅ Simulation sauvegardée !'),
                      backgroundColor: kGreen,
                      behavior: SnackBarBehavior.floating));
              _tabCtrl.animateTo(1);
            },
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Sauvegarder',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
                backgroundColor: kBlue, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0))),
        const SizedBox(width: 8),
        Expanded(child: ElevatedButton.icon(
            onPressed: () {
              _analyserInvestissement();
              _tabCtrl.animateTo(3);
            },
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('Analyser IA',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
                backgroundColor: kGreen, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0))),
      ]),
    ],
  );

  // ── RÉSULTATS ──
  Widget _buildResultats() {
    final isRentable = _beneficeNet > 0;
    final roiColor = _roi >= 20 ? kGreen : _roi >= 10 ? kOrange : kRed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Verdict
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: isRentable
                      ? [kGreen.withOpacity(0.8), kGreen]
                      : [kRed.withOpacity(0.8), kRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                  color: (isRentable ? kGreen : kRed).withOpacity(0.3),
                  blurRadius: 16, offset: const Offset(0, 6))]),
          child: Row(children: [
            Text(isRentable ? '🎉' : '❌',
                style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isRentable ? 'Investissement Rentable !'
                  : 'Investissement Déficitaire',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w900, fontSize: 16)),
              Text(isRentable
                  ? 'ROI: ${_roi.toStringAsFixed(1)}% — Excellent !'
                  : 'Revoir les paramètres',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),

        // Détail charges
        _card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('💸 Détail des Charges', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14,
              color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          _chargeRow('🐥 Achat poussins',
              _coutAchatPoussins, _totalCharges),
          _chargeRow('🌾 Alimentation', _coutAliment, _totalCharges),
          _chargeRow('💊 Vétérinaire', _coutVeterinaire, _totalCharges),
          _chargeRow('👥 Main d\'œuvre', _coutMainOeuvre, _totalCharges),
          _chargeRow('🏠 Loyer', _coutLoyer, _totalCharges),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL CHARGES', style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13)),
                Text(_formatFcfa(_totalCharges), style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 14,
                    color: kRed)),
              ]),
        ])),
        const SizedBox(height: 12),

        // Résultats financiers
        _card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('📊 Résultats Financiers', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14,
              color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          _resultRow('Poulets survivants',
              '${_pouletsSurvivants.toInt()} têtes', kBlue),
          _resultRow('Revenu brut',
              _formatFcfa(_revenuBrut), kGreen),
          _resultRow('Total charges',
              _formatFcfa(_totalCharges), kRed),
          const Divider(),
          _resultRow('Bénéfice net',
              _formatFcfa(_beneficeNet),
              isRentable ? kGreen : kRed, isBold: true),
          _resultRow('ROI', '${_roi.toStringAsFixed(1)}%', roiColor,
              isBold: true),
          _resultRow('Seuil rentabilité',
              '${_formatFcfa(_seuilRentabilite)}/tête', kOrange),
        ])),
        const SizedBox(height: 12),

        // Projections annuelles
        _card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('📅 Projections Annuelles', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14,
              color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          _resultRow('Cycles par an', '$_nbCyclesParAn cycles', kBlue),
          _resultRow('Bénéfice annuel',
              _formatFcfa(_beneficeAnnuel), kGreen, isBold: true),
          _resultRow('Retour sur capital',
              '${_retourInvestissement.toStringAsFixed(1)} cycles',
              kPurple),
          const SizedBox(height: 12),

          // Barre progression ROI
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Rentabilité', style: TextStyle(
                      fontSize: 12, color: Colors.grey)),
                  Text('${_roi.toStringAsFixed(1)}%', style: TextStyle(
                      color: roiColor, fontWeight: FontWeight.w700,
                      fontSize: 12)),
                ]),
            const SizedBox(height: 4),
            ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                    value: (_roi.clamp(0, 50) / 50),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(roiColor),
                    minHeight: 8)),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('0%', style: TextStyle(
                      color: Colors.grey, fontSize: 9)),
                  const Text('Objectif: 20%', style: TextStyle(
                      color: Colors.grey, fontSize: 9)),
                  const Text('50%', style: TextStyle(
                      color: Colors.grey, fontSize: 9)),
                ]),
          ]),
        ])),
      ]),
    );
  }

  // ── HISTORIQUE ──
  Widget _buildHistorique() {
    if (_simulations.isEmpty) return const Center(
        child: Text('Aucune simulation sauvegardée'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${_simulations.length} simulation(s)',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),
        ..._simulations.reversed.map((s) => _simulationCard(s)),
      ],
    );
  }

  Widget _simulationCard(Map s) {
    final benefice = (s['benefice'] as double);
    final roi = (s['roi'] as double);
    final isRentable = benefice > 0;
    final color = isRentable ? kGreen : kRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: color, width: 3)),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text(s['nom'] as String, style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14,
              color: Color(0xFF1E293B)))),
          Text(s['date'] as String, style: const TextStyle(
              color: Colors.grey, fontSize: 11)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _miniKpi('🐥', '${(s['poussins'] as double).toInt()}',
              'Poussins', kBlue),
          const SizedBox(width: 6),
          _miniKpi('💰', _formatFcfa(s['revenu'] as double),
              'Revenu', kGreen),
          const SizedBox(width: 6),
          _miniKpi('📊', '${roi.toStringAsFixed(1)}%',
              'ROI', color),
          const SizedBox(width: 6),
          _miniKpi(isRentable ? '✅' : '❌',
              _formatFcfa(benefice), 'Bénéfice', color),
        ]),
      ]),
    );
  }

  // ── ANALYSE IA ──
  Widget _buildAnalyseIA() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF166534)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          const Text('📈', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text('Analyse Investissement IA', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900,
              fontSize: 16)),
          const Text('Recommandations financières par Claude AI',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                  onPressed: _loadingIA ? null : _analyserInvestissement,
                  icon: _loadingIA
                      ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: kGreen, strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(_loadingIA
                      ? 'Analyse en cours...' : 'Analyser l\'investissement',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: kGreen,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0))),
        ]),
      ),
      const SizedBox(height: 16),

      if (_analyseIA != null) _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.auto_awesome_rounded, color: kGreen, size: 18),
          SizedBox(width: 8),
          Text('Analyse Financière', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14,
              color: Color(0xFF1E293B))),
        ]),
        const Divider(),
        const SizedBox(height: 8),
        Text(_analyseIA!, style: const TextStyle(
            fontSize: 13, color: Color(0xFF1E293B), height: 1.6)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: _analyserInvestissement,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Relancer'),
            style: OutlinedButton.styleFrom(
                foregroundColor: kGreen,
                side: const BorderSide(color: kGreen),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)))),
      ])),
      const SizedBox(height: 16),

      // Conseils rapides
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💡 Conseils Financiers', style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14,
                color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            _conseilFinancier('📉 Réduire la mortalité',
                'Chaque point de mortalité en moins = +${_formatFcfa(_prixVentePoulet * _nombrePoussinsPrevus / 100)} de revenu',
                kGreen),
            _conseilFinancier('🌾 Optimiser l\'alimentation',
                'L\'alimentation représente ${(_coutAliment / _totalCharges * 100).toStringAsFixed(0)}% des charges',
                kOrange),
            _conseilFinancier('📈 Augmenter le volume',
                'Doubler le nombre de poussins multiplierait le bénéfice par ~2',
                kBlue),
            _conseilFinancier('🔄 Multiplier les cycles',
                '$_nbCyclesParAn cycles/an = ${_formatFcfa(_beneficeAnnuel)} de bénéfice annuel',
                kPurple),
          ])),
    ]),
  );

  // ── HELPERS ──
  Widget _slider(String label, double value, double min, double max,
      Function(double) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(
            fontSize: 12, color: Colors.grey)),
        Text(value >= 1000
            ? _formatFcfa(value)
            : value.toStringAsFixed(value < 10 ? 1 : 0),
            style: const TextStyle(fontWeight: FontWeight.w800,
                fontSize: 12, color: kBlue)),
      ]),
      Slider(
          value: value.clamp(min, max),
          min: min, max: max,
          activeColor: kBlue,
          inactiveColor: Colors.grey.shade200,
          onChanged: onChanged),
      const SizedBox(height: 4),
    ]);
  }

  Widget _chargeRow(String label, double montant, double total) {
    final pct = total > 0 ? montant / total : 0.0;
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 12)),
                Text(_formatFcfa(montant), style: const TextStyle(
                    color: kRed, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
          const SizedBox(height: 3),
          Row(children: [
            Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                    value: pct, backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(kRed),
                    minHeight: 4))),
            const SizedBox(width: 6),
            Text('${(pct * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 10)),
          ]),
        ]));
  }

  Widget _resultRow(String label, String value, Color color,
      {bool isBold = false}) =>
      Padding(padding: const EdgeInsets.only(bottom: 8),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: TextStyle(
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                fontSize: isBold ? 13 : 12)),
            Text(value, style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: isBold ? 14 : 12, color: color)),
          ]));

  Widget _miniKpi(String emoji, String value, String label, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          Text(value, style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 10, color: color),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: const TextStyle(
              color: Colors.grey, fontSize: 8)),
        ]),
      ));

  Widget _conseilFinancier(String titre, String desc, Color color) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Row(children: [
          Container(width: 4, height: 40,
              decoration: BoxDecoration(color: color,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titre, style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 12, color: color)),
            Text(desc, style: const TextStyle(
                color: Colors.grey, fontSize: 11)),
          ])),
        ]),
      );

  Widget _headerStat(String value, String label, Color color) =>
      Expanded(child: Column(children: [
        Text(value, style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center),
        Text(label, style: const TextStyle(
            color: Colors.white38, fontSize: 8),
            textAlign: TextAlign.center),
      ]));

  Widget _card({required Widget child}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: child);
}