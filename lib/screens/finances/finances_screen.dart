import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});
  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List _cycles = [];
  List _donnees = [];
  bool _loading = true;
  String? _selectedCycleId;

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
    final c = await ApiService.getCycles();
    final d = await ApiService.getDonnees();
    setState(() {
      _cycles = c is List ? c : [];
      _donnees = d is List ? d : [];
      _loading = false;
    });
  }

  List get _cyclesFiltres => _selectedCycleId == null ? _cycles :
  _cycles.where((c) => c['id']?.toString() == _selectedCycleId).toList();

  List _donneesForCycle(String? cycleId) => cycleId == null ? _donnees :
  _donnees.where((d) => d['cycle_id']?.toString() == cycleId).toList();

  double _calculerRevenu(Map cycle) {
    final sujets = ((cycle['nombre_sujets'] ?? 0) as num).toDouble();
    final mortalite = _donneesForCycle(cycle['id']?.toString())
        .fold<int>(0, (s, d) => s + ((d['mortalite'] ?? 0) as num).toInt());
    return (sujets - mortalite) * FinanceParams.prixVentePoulet;
  }

  double _calculerDepenses(Map cycle) {
    final sujets = ((cycle['nombre_sujets'] ?? 0) as num).toDouble();
    return sujets * FinanceParams.prixPoussin +
        sujets * FinanceParams.coutMedicalParPoussin +
        FinanceParams.salairesMois * 1.5 +
        FinanceParams.loyerMois * 1.5;
  }

  String _formatFcfa(double v) {
    final abs = v.abs();
    String formatted;
    if (abs >= 1000000) {
      formatted = '${(abs / 1000000).toStringAsFixed(1)}M';
    } else if (abs >= 1000) {
      formatted = '${(abs / 1000).toStringAsFixed(0)}K';
    } else {
      formatted = abs.toStringAsFixed(0);
    }
    return '${v < 0 ? '-' : ''}$formatted FCFA';
  }

  String _formatFcfaFull(double v) =>
      '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(child: CircularProgressIndicator(color: kBlue)),
    );

    final totalRevenu = _cyclesFiltres.fold(0.0, (s, c) => s + _calculerRevenu(c));
    final totalDepenses = _cyclesFiltres.fold(0.0, (s, c) => s + _calculerDepenses(c));
    final totalMarge = totalRevenu - totalDepenses;
    final tauxMarge = totalRevenu > 0 ? (totalMarge / totalRevenu * 100) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(children: [
        // ── HEADER ──
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Text('💰', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('Tableau Financier', style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _headerKpi('💵', 'Revenus', _formatFcfa(totalRevenu), const Color(0xFF10B981)),
              const SizedBox(width: 8),
              _headerKpi('💸', 'Dépenses', _formatFcfa(totalDepenses), const Color(0xFFEF4444)),
              const SizedBox(width: 8),
              _headerKpi('📊', 'Marge', _formatFcfa(totalMarge),
                  totalMarge >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Taux de rentabilité', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(width: 12),
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                        value: (tauxMarge.clamp(0, 100) / 100),
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(
                            tauxMarge >= 0 ? Colors.greenAccent : Colors.redAccent),
                        minHeight: 6))),
                const SizedBox(width: 10),
                Text('${tauxMarge.toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: tauxMarge >= 0 ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.w800, fontSize: 13)),
              ]),
            ),
          ]),
        ),

        // ── TABS ──
        Container(
          color: Colors.white,
          child: TabBar(
              controller: _tabCtrl,
              labelColor: kBlue, unselectedLabelColor: Colors.grey,
              indicatorColor: kBlue, indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              tabs: const [
                Tab(text: '📊 Bilan'),
                Tab(text: '💵 Revenus'),
                Tab(text: '💸 Dépenses'),
                Tab(text: '⚙️ Paramètres'),
              ]),
        ),

        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _buildBilan(totalRevenu, totalDepenses, totalMarge),
          _buildRevenus(),
          _buildDepenses(),
          _buildParametres(),
        ])),
      ]),
    );
  }

  Widget _headerKpi(String emoji, String label, String value, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
        ]),
      ));

  // ── BILAN ──
  Widget _buildBilan(double totalRevenu, double totalDepenses, double totalMarge) {
    return RefreshIndicator(onRefresh: _load, color: kBlue,
      child: ListView(padding: const EdgeInsets.all(12), children: [
        _cycleSelector(),
        const SizedBox(height: 12),
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _cardTitle('📋 Résumé', '${_cyclesFiltres.length} cycle(s)'),
          const SizedBox(height: 12),
          _bilanRow('Revenus', totalRevenu, kGreen),
          const Divider(height: 16),
          _bilanRow('Dépenses', totalDepenses, kRed),
          const Divider(height: 16),
          _bilanRow('Bénéfice Net', totalMarge, totalMarge >= 0 ? kGreen : kRed, isBold: true),
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: (totalMarge >= 0 ? kGreen : kRed).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Text(totalMarge >= 0 ? '✅' : '❌', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(child: Text(
                    totalMarge >= 0
                        ? 'Rentable ! +${_formatFcfaFull(totalMarge)}'
                        : 'Déficit de ${_formatFcfaFull(totalMarge.abs())}',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12,
                        color: totalMarge >= 0 ? kGreen : kRed))),
              ])),
        ])),
        const SizedBox(height: 12),
        const Text('📈 Par Cycle',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        const SizedBox(height: 8),
        ..._cyclesFiltres.map((c) => _cycleBilanCard(c)),
      ]),
    );
  }

  Widget _cycleBilanCard(Map c) {
    final revenu = _calculerRevenu(c);
    final depenses = _calculerDepenses(c);
    final marge = revenu - depenses;
    final taux = revenu > 0 ? (marge / revenu * 100) : 0.0;
    final isPositif = marge >= 0;
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(c['nom'] ?? 'Cycle',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B)))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: (isPositif ? kGreen : kRed).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text('${taux.toStringAsFixed(1)}%',
                style: TextStyle(color: isPositif ? kGreen : kRed, fontWeight: FontWeight.w800, fontSize: 11))),
      ]),
      Text('${c['nombre_sujets'] ?? 0} sujets', style: const TextStyle(color: Colors.grey, fontSize: 11)),
      const SizedBox(height: 10),
      Row(children: [
        _miniKpi('💵', _formatFcfa(revenu), 'Revenus', kGreen),
        const SizedBox(width: 6),
        _miniKpi('💸', _formatFcfa(depenses), 'Dépenses', kRed),
        const SizedBox(width: 6),
        _miniKpi('📊', _formatFcfa(marge), 'Marge', isPositif ? kGreen : kRed),
      ]),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
          value: (taux.clamp(0, 100) / 100),
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation(isPositif ? kGreen : kRed),
          minHeight: 5)),
    ]));
  }

  // ── REVENUS ──
  Widget _buildRevenus() {
    return ListView(padding: const EdgeInsets.all(12), children: [
      _cycleSelector(),
      const SizedBox(height: 12),
      ..._cyclesFiltres.map((c) {
        final revenu = _calculerRevenu(c);
        final sujets = ((c['nombre_sujets'] ?? 0) as num).toDouble();
        final mortalite = _donneesForCycle(c['id']?.toString())
            .fold<int>(0, (s, d) => s + ((d['mortalite'] ?? 0) as num).toInt());
        final vendus = sujets - mortalite;
        return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _cardTitle('💵 ${c['nom'] ?? 'Cycle'}', _formatFcfa(revenu)),
          const SizedBox(height: 10),
          _detailRow('🐔 Poulets vendus', '${vendus.toInt()} sujets'),
          _detailRow('💰 Prix unitaire', _formatFcfaFull(FinanceParams.prixVentePoulet)),
          _detailRow('💀 Mortalité', '$mortalite sujets'),
          const Divider(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: kGreen)),
            Text(_formatFcfaFull(revenu),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kGreen)),
          ]),
        ]));
      }),
    ]);
  }

  // ── DÉPENSES ──
  Widget _buildDepenses() {
    return ListView(padding: const EdgeInsets.all(12), children: [
      _cycleSelector(),
      const SizedBox(height: 12),
      ..._cyclesFiltres.map((c) {
        final sujets = ((c['nombre_sujets'] ?? 0) as num).toDouble();
        final poussins = sujets * FinanceParams.prixPoussin;
        final medical = sujets * FinanceParams.coutMedicalParPoussin;
        final salaires = FinanceParams.salairesMois * 1.5;
        final loyer = FinanceParams.loyerMois * 1.5;
        final total = poussins + medical + salaires + loyer;
        final items = [
          {'label': '🐥 Poussins', 'montant': poussins, 'pct': poussins / total * 100},
          {'label': '💊 Médical', 'montant': medical, 'pct': medical / total * 100},
          {'label': '👥 Salaires', 'montant': salaires, 'pct': salaires / total * 100},
          {'label': '🏠 Loyer', 'montant': loyer, 'pct': loyer / total * 100},
        ];
        return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _cardTitle('💸 ${c['nom'] ?? 'Cycle'}', _formatFcfa(total)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(item['label'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                Text(_formatFcfa(item['montant'] as double),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: kRed, fontSize: 12)),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                        value: ((item['pct'] as double) / 100).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(kRed),
                        minHeight: 4))),
                const SizedBox(width: 6),
                Text('${(item['pct'] as double).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ]),
            ]),
          )),
          const Divider(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: kRed)),
            Text(_formatFcfaFull(total),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kRed)),
          ]),
        ]));
      }),
    ]);
  }

  // ── PARAMÈTRES ──
  Widget _buildParametres() {
    return ListView(padding: const EdgeInsets.all(12), children: [
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('⚙️', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text('Paramètres Financiers',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        ]),
        const SizedBox(height: 4),
        const Text('Ajustez selon votre situation',
            style: TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 16),
        _paramField('🌾 Prix sac aliment', FinanceParams.prixSacAliment,
                (v) => setState(() => FinanceParams.prixSacAliment = v)),
        _paramField('🐔 Prix vente poulet', FinanceParams.prixVentePoulet,
                (v) => setState(() => FinanceParams.prixVentePoulet = v)),
        _paramField('🐥 Prix poussin', FinanceParams.prixPoussin,
                (v) => setState(() => FinanceParams.prixPoussin = v)),
        _paramField('👥 Salaires/mois', FinanceParams.salairesMois,
                (v) => setState(() => FinanceParams.salairesMois = v)),
        _paramField('🏠 Loyer/mois', FinanceParams.loyerMois,
                (v) => setState(() => FinanceParams.loyerMois = v)),
        _paramField('💊 Coût médical/poussin', FinanceParams.coutMedicalParPoussin,
                (v) => setState(() => FinanceParams.coutMedicalParPoussin = v)),
      ])),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A5F), Color(0xFF1B3A6B)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('💡', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('Conseil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            ]),
            SizedBox(height: 8),
            Text('Réduire la mortalité en optimisant la ventilation peut augmenter votre marge de 15-20%.',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
          ])),
    ]);
  }

  // ── HELPERS ──
  Widget _cycleSelector() => DropdownButtonFormField<String>(
      value: _selectedCycleId,
      decoration: InputDecoration(
          labelText: 'Filtrer par cycle',
          prefixIcon: const Icon(Icons.filter_list_rounded, color: kBlue, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      items: [
        const DropdownMenuItem(value: null, child: Text('Tous les cycles')),
        ..._cycles.map((c) => DropdownMenuItem(
            value: c['id']?.toString(),
            child: Text(c['nom']?.toString() ?? '', style: const TextStyle(fontSize: 13)))),
      ],
      onChanged: (v) => setState(() => _selectedCycleId = v));

  Widget _card({required Widget child}) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
      child: child);

  Widget _cardTitle(String title, String subtitle) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B)))),
        Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: kBlue)),
      ]);

  Widget _bilanRow(String label, double value, Color color, {bool isBold = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            fontSize: isBold ? 13 : 12, color: const Color(0xFF1E293B))),
        Text(_formatFcfaFull(value), style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: isBold ? 14 : 12, color: color)),
      ]);

  Widget _miniKpi(String emoji, String value, String label, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: color)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 8)),
        ]),
      ));

  Widget _detailRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1E293B))),
      ]));

  Widget _paramField(String label, double value, Function(double) onChanged) {
    final ctrl = TextEditingController(text: value.toStringAsFixed(0));
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1E293B)))),
          const SizedBox(width: 10),
          SizedBox(width: 110, child: TextField(
              controller: ctrl, keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800, color: kBlue, fontSize: 12),
              decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  filled: true, fillColor: const Color(0xFFF8FAFC)),
              onSubmitted: (v) => onChanged(double.tryParse(v) ?? value))),
        ]));
  }
}