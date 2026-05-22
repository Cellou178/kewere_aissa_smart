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
      if (_cycles.isNotEmpty && _selectedCycleId == null) {
        _selectedCycleId = _cycles.first['id']?.toString();
      }
      _loading = false;
    });
  }

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

  double _calculerMarge(Map cycle) => _calculerRevenu(cycle) - _calculerDepenses(cycle);

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

    double totalRevenu = _cycles.fold(0.0, (s, c) => s + _calculerRevenu(c));
    double totalDepenses = _cycles.fold(0.0, (s, c) => s + _calculerDepenses(c));
    double totalMarge = totalRevenu - totalDepenses;
    double tauxMarge = totalRevenu > 0 ? (totalMarge / totalRevenu * 100) : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(children: [
        // ── HEADER SOMBRE ──
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Text('💰', style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Text('Tableau Financier', style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 16),
            // KPI Row
            Row(children: [
              _headerKpi('💵', 'Revenus', _formatFcfa(totalRevenu), const Color(0xFF10B981)),
              const SizedBox(width: 10),
              _headerKpi('💸', 'Dépenses', _formatFcfa(totalDepenses), const Color(0xFFEF4444)),
              const SizedBox(width: 10),
              _headerKpi('📊', 'Marge', _formatFcfa(totalMarge),
                  totalMarge >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
            ]),
            const SizedBox(height: 12),
            // Barre de progression
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Taux de rentabilité', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('${tauxMarge.toStringAsFixed(1)}%',
                      style: TextStyle(
                          color: tauxMarge >= 0 ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.w800, fontSize: 14)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                    value: (tauxMarge.clamp(0, 100) / 100),
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(tauxMarge >= 0 ? Colors.greenAccent : Colors.redAccent),
                    minHeight: 8)),
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
          _buildBilan(totalRevenu, totalDepenses, totalMarge, tauxMarge),
          _buildRevenus(),
          _buildDepenses(),
          _buildParametres(),
        ])),
      ]),
    );
  }

  Widget _headerKpi(String emoji, String label, String value, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ]),
      ));

  // ── BILAN ──
  Widget _buildBilan(double totalRevenu, double totalDepenses, double totalMarge, double tauxMarge) {
    return RefreshIndicator(onRefresh: _load, color: kBlue,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        // Sélecteur cycle
        _cycleSelector(),
        const SizedBox(height: 16),

        // Résumé global
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _cardTitle('📋 Résumé Global', '${_cycles.length} cycles'),
          const SizedBox(height: 16),
          _bilanRow('Total Revenus', totalRevenu, kGreen),
          const Divider(height: 20),
          _bilanRow('Total Dépenses', totalDepenses, kRed),
          const Divider(height: 20),
          _bilanRow('Bénéfice Net', totalMarge, totalMarge >= 0 ? kGreen : kRed, isBold: true),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: (totalMarge >= 0 ? kGreen : kRed).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Text(totalMarge >= 0 ? '✅' : '❌', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(child: Text(
                    totalMarge >= 0
                        ? 'Rentable ! Bénéfice de ${_formatFcfaFull(totalMarge)}'
                        : 'Déficitaire de ${_formatFcfaFull(totalMarge.abs())}',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                        color: totalMarge >= 0 ? kGreen : kRed))),
              ])),
        ])),
        const SizedBox(height: 16),

        // Par cycle
        const Text('📈 Comparaison par Cycle',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        ..._cycles.map((c) => _cycleBilanCard(c)),
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
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: (isPositif ? kGreen : kRed).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text('${taux.toStringAsFixed(1)}%',
                style: TextStyle(color: isPositif ? kGreen : kRed, fontWeight: FontWeight.w800, fontSize: 12))),
      ]),
      Text('${c['nombre_sujets'] ?? 0} sujets',
          style: const TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 12),
      Row(children: [
        _miniKpi('💵', _formatFcfa(revenu), 'Revenus', kGreen),
        const SizedBox(width: 8),
        _miniKpi('💸', _formatFcfa(depenses), 'Dépenses', kRed),
        const SizedBox(width: 8),
        _miniKpi('📊', _formatFcfa(marge), 'Marge', isPositif ? kGreen : kRed),
      ]),
      const SizedBox(height: 10),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
          value: (taux.clamp(0, 100) / 100),
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation(isPositif ? kGreen : kRed),
          minHeight: 6)),
    ]));
  }

  // ── REVENUS ──
  Widget _buildRevenus() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _cycleSelector(),
      const SizedBox(height: 16),
      ..._cycles.map((c) {
        final revenu = _calculerRevenu(c);
        final sujets = ((c['nombre_sujets'] ?? 0) as num).toDouble();
        final mortalite = _donneesForCycle(c['id']?.toString())
            .fold<int>(0, (s, d) => s + ((d['mortalite'] ?? 0) as num).toInt());
        final vendus = sujets - mortalite;
        return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _cardTitle('💵 ${c['nom'] ?? 'Cycle'}', _formatFcfaFull(revenu)),
          const SizedBox(height: 14),
          _detailRow('🐔 Poulets vendus', '${vendus.toInt()} sujets'),
          _detailRow('💰 Prix unitaire', _formatFcfaFull(FinanceParams.prixVentePoulet)),
          _detailRow('💀 Mortalité déduite', '$mortalite sujets'),
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TOTAL REVENUS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kGreen)),
            Text(_formatFcfaFull(revenu), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kGreen)),
          ]),
        ]));
      }),
    ]);
  }

  // ── DÉPENSES ──
  Widget _buildDepenses() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _cycleSelector(),
      const SizedBox(height: 16),
      ..._cycles.map((c) {
        final sujets = ((c['nombre_sujets'] ?? 0) as num).toDouble();
        final poussins = sujets * FinanceParams.prixPoussin;
        final medical = sujets * FinanceParams.coutMedicalParPoussin;
        final salaires = FinanceParams.salairesMois * 1.5;
        final loyer = FinanceParams.loyerMois * 1.5;
        final total = poussins + medical + salaires + loyer;
        final items = [
          {'label': '🐥 Achat poussins', 'montant': poussins, 'pct': poussins / total * 100},
          {'label': '💊 Soins médicaux', 'montant': medical, 'pct': medical / total * 100},
          {'label': '👥 Salaires', 'montant': salaires, 'pct': salaires / total * 100},
          {'label': '🏠 Loyer/charges', 'montant': loyer, 'pct': loyer / total * 100},
        ];
        return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _cardTitle('💸 ${c['nom'] ?? 'Cycle'}', _formatFcfaFull(total)),
          const SizedBox(height: 14),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(item['label'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(_formatFcfaFull(item['montant'] as double),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: kRed, fontSize: 13)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                        value: ((item['pct'] as double) / 100).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(kRed),
                        minHeight: 5))),
                const SizedBox(width: 8),
                Text('${(item['pct'] as double).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ]),
            ]),
          )),
          const Divider(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TOTAL DÉPENSES', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kRed)),
            Text(_formatFcfaFull(total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kRed)),
          ]),
        ]));
      }),
    ]);
  }

  // ── PARAMÈTRES ──
  Widget _buildParametres() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('⚙️', style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Text('Paramètres Financiers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        ]),
        const SizedBox(height: 4),
        const Text('Ajustez selon votre situation réelle',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 20),
        _paramField('🌾 Prix sac aliment (FCFA)', FinanceParams.prixSacAliment,
                (v) => setState(() => FinanceParams.prixSacAliment = v)),
        _paramField('🐔 Prix vente poulet (FCFA)', FinanceParams.prixVentePoulet,
                (v) => setState(() => FinanceParams.prixVentePoulet = v)),
        _paramField('🐥 Prix poussin (FCFA)', FinanceParams.prixPoussin,
                (v) => setState(() => FinanceParams.prixPoussin = v)),
        _paramField('👥 Salaires/mois (FCFA)', FinanceParams.salairesMois,
                (v) => setState(() => FinanceParams.salairesMois = v)),
        _paramField('🏠 Loyer/mois (FCFA)', FinanceParams.loyerMois,
                (v) => setState(() => FinanceParams.loyerMois = v)),
        _paramField('💊 Coût médical/poussin (FCFA)', FinanceParams.coutMedicalParPoussin,
                (v) => setState(() => FinanceParams.coutMedicalParPoussin = v)),
      ])),
      const SizedBox(height: 16),
      // Conseil IA
      Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A5F), Color(0xFF1B3A6B)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Text('💡', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('Conseil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
            ]),
            const SizedBox(height: 8),
            const Text('Pour améliorer la rentabilité, réduisez la mortalité en optimisant la ventilation et la densité du bâtiment. Un taux de mortalité < 3% peut augmenter votre marge de 15-20%.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
          ])),
    ]);
  }

  // ── WIDGETS HELPER ──
  Widget _cycleSelector() => DropdownButtonFormField<String>(
      value: _selectedCycleId,
      decoration: InputDecoration(
          labelText: 'Filtrer par cycle',
          prefixIcon: const Icon(Icons.filter_list_rounded, color: kBlue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      items: [
        const DropdownMenuItem(value: null, child: Text('Tous les cycles')),
        ..._cycles.map((c) => DropdownMenuItem(
            value: c['id']?.toString(),
            child: Text(c['nom']?.toString() ?? ''))),
      ],
      onChanged: (v) => setState(() => _selectedCycleId = v));

  Widget _card({required Widget child}) => Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
      child: child);

  Widget _cardTitle(String title, String subtitle) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)))),
        Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kBlue)),
      ]);

  Widget _bilanRow(String label, double value, Color color, {bool isBold = false}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            fontSize: isBold ? 14 : 13, color: const Color(0xFF1E293B))),
        Text(_formatFcfaFull(value), style: TextStyle(fontWeight: FontWeight.w800,
            fontSize: isBold ? 15 : 13, color: color)),
      ]);

  Widget _miniKpi(String emoji, String value, String label, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: color)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9)),
        ]),
      ));

  Widget _detailRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
      ]));

  Widget _paramField(String label, double value, Function(double) onChanged) {
    final ctrl = TextEditingController(text: value.toStringAsFixed(0));
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)))),
          const SizedBox(width: 12),
          SizedBox(width: 130, child: TextField(
              controller: ctrl, keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800, color: kBlue, fontSize: 13),
              decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true, fillColor: const Color(0xFFF8FAFC)),
              onSubmitted: (v) => onChanged(double.tryParse(v) ?? value))),
        ]));
  }
}