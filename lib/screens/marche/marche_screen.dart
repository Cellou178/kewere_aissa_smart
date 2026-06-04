import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';

class MarcheScreen extends StatefulWidget {
  const MarcheScreen({super.key});
  @override
  State<MarcheScreen> createState() => _MarcheScreenState();
}

class _MarcheScreenState extends State<MarcheScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = false;
  bool _loadingIA = false;
  String? _analyseIA;
  List _cycles = [];

  List<Map<String, dynamic>> _prixPoulet = [];
  List<Map<String, dynamic>> _prixAliment = [];
  List<Map<String, dynamic>> _prixMedicaments = [];
  List<Map<String, dynamic>> _actualites = [];

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
    final results = await Future.wait([
      ApiService.getCycles(),
      ApiService.getActualitesMarche(),
      ApiService.getPrixMarche(categorie: 'poulet'),
      ApiService.getPrixMarche(categorie: 'aliment'),
      ApiService.getPrixMarche(categorie: 'medicament'),
    ]);
    setState(() {
      _cycles = results[0];
      _actualites = results[1].map((e) => Map<String, dynamic>.from(e)).toList();
      _prixPoulet = results[2].map((e) => Map<String, dynamic>.from(e)).toList();
      _prixAliment = results[3].map((e) => Map<String, dynamic>.from(e)).toList();
      _prixMedicaments = results[4].map((e) => Map<String, dynamic>.from(e)).toList();
      _loading = false;
    });
  }

  Future<void> _analyserMarche() async {
    setState(() { _loadingIA = true; _analyseIA = null; });
    try {
      final prixPouletSn = _prixPoulet
          .where((p) => p['pays']?.toString().contains('Sénégal') == true)
          .map((p) => (p['prix'] as num).toDouble())
          .toList();
      final prixMoyenSenegal = prixPouletSn.isEmpty ? 0.0
          : prixPouletSn.reduce((a, b) => a + b) / prixPouletSn.length;

      final prixResume = _prixPoulet.take(4)
          .map((p) => '${p['ville'] ?? p['pays']}: ${p['prix']} FCFA/kg (${p['tendance']})')
          .join(', ');
      final alimentResume = _prixAliment.take(3)
          .map((p) => '${p['produit']}: ${p['prix']} FCFA')
          .join(', ');
      final alertesUrgentes = _actualites
          .where((a) => a['urgent'] == true)
          .map((a) => a['titre'])
          .join('; ');

      final prompt = '''Tu es un expert en marchés avicoles en Afrique de l\'Ouest.
Analyse les tendances du marché avicole et donne des recommandations stratégiques.

DONNÉES DU MARCHÉ (temps réel):
- Prix moyen poulet Sénégal: ${prixMoyenSenegal.toStringAsFixed(0)} FCFA/kg
- Prix par ville: $prixResume
- Intrants: $alimentResume
- Alertes urgentes: ${alertesUrgentes.isEmpty ? 'Aucune' : alertesUrgentes}

Donne une analyse stratégique incluant:
1. Opportunités de vente actuelles
2. Risques à surveiller
3. Meilleur moment pour vendre
4. Recommandations d\'achat intrants
5. Perspectives 30 jours

En français, pratique et concis.''';

      final reponse = await ApiService.callIA(prompt,
          contexte: 'Expert marché avicole Sénégal. Analyse stratégique concise.');
      setState(() => _analyseIA = reponse.isEmpty ? 'Analyse indisponible.' : reponse);
    } catch (e) {
      setState(() => _analyseIA = 'Analyse indisponible.');
    }
    setState(() => _loadingIA = false);
  }

  String _formatFcfa(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    final urgentes = _actualites.where((a) => a['urgent'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(children: [
        // Header
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: urgentes > 0
                  ? [const Color(0xFF7F1D1D), const Color(0xFF1E3A5F)]
                  : [const Color(0xFF0F172A), const Color(0xFF1E3A5F)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            Row(children: [
              const Text('🌍', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Marché Avicole', style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text('Afrique de l\'Ouest • Temps réel', style: TextStyle(
                    color: Colors.white54, fontSize: 11)),
              ])),
              IconButton(icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white54, size: 20), onPressed: _load),
            ]),
            const SizedBox(height: 12),

            // Stats rapides
            Row(children: [
              _headerStat('8', 'Marchés', Colors.white),
              _headerStat('2800', 'Prix moy.\n(FCFA/kg)', Colors.greenAccent),
              _headerStat('$urgentes', 'Alertes\nurgentes',
                  urgentes > 0 ? Colors.redAccent : Colors.greenAccent),
              _headerStat('↑5.2%', 'Tendance\nDakar', Colors.amber),
            ]),
            const SizedBox(height: 12),

            TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              isScrollable: true,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              tabs: const [
                Tab(text: '🐔 Prix Poulet'),
                Tab(text: '🌾 Intrants'),
                Tab(text: '📰 Actualités'),
                Tab(text: '🤖 Analyse IA'),
              ],
            ),
          ]),
        ),

        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _buildPrixPoulet(),
          _buildIntrants(),
          _buildActualites(),
          _buildAnalyseIA(),
        ])),
      ]),
    );
  }

  // ── PRIX POULET ──
  Widget _buildPrixPoulet() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // Info mise à jour
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: kBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBlue.withOpacity(0.2))),
        child: const Row(children: [
          Icon(Icons.info_rounded, color: kBlue, size: 15),
          SizedBox(width: 6),
          Text('Dernière mise à jour: 23/05/2026 • Sources: marchés locaux',
              style: TextStyle(color: kBlue, fontSize: 10)),
        ]),
      ),
      const SizedBox(height: 12),

      // Meilleur prix
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [kGreen, Color(0xFF059669)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: kGreen.withOpacity(0.3),
                blurRadius: 12, offset: const Offset(0, 4))]),
        child: Row(children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🏆 Meilleur Prix', style: TextStyle(
                color: Colors.white70, fontSize: 12)),
            Text('Abidjan, CI', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
            Text('3 200 FCFA/kg', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          const Spacer(),
          Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: const Column(children: [
                Text('📊', style: TextStyle(fontSize: 24)),
                Text('Exportable', style: TextStyle(
                    color: Colors.white, fontSize: 9)),
              ])),
        ]),
      ),
      const SizedBox(height: 16),

      const Text('Prix par marché', style: TextStyle(
          fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
      const SizedBox(height: 8),
      ..._prixPoulet.map((p) => _prixCard(p, 'FCFA/kg')),
    ],
  );

  // ── INTRANTS ──
  Widget _buildIntrants() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // Alerte hausse
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: kOrange.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kOrange.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.trending_up_rounded, color: kOrange, size: 18),
          const SizedBox(width: 8),
          const Expanded(child: Text(
              '⚠️ Les prix des intrants sont en hausse — achetez maintenant si possible',
              style: TextStyle(color: kOrange, fontSize: 12, fontWeight: FontWeight.w600))),
        ]),
      ),
      const SizedBox(height: 16),

      const Text('🌾 Aliments & Matières premières', style: TextStyle(
          fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
      const SizedBox(height: 8),
      ..._prixAliment.map((p) => _intrantCard(p)),
      const SizedBox(height: 16),

      const Text('💊 Médicaments & Vaccins', style: TextStyle(
          fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
      const SizedBox(height: 8),
      ..._prixMedicaments.map((p) => _intrantCard(p)),
    ],
  );

  // ── ACTUALITÉS ──
  Widget _buildActualites() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // Urgentes d'abord
      ..._actualites.where((a) => a['urgent'] == true)
          .map((a) => _actuCard(a)),
      if (_actualites.any((a) => a['urgent'] == true)) ...[
        const Divider(height: 24),
        const Text('Autres actualités', style: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
      ],
      ..._actualites.where((a) => a['urgent'] == false)
          .map((a) => _actuCard(a)),
    ],
  );

  // ── ANALYSE IA ──
  Widget _buildAnalyseIA() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      // Bouton analyser
      Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A5F), Color(0xFF166534)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          const Text('🌍', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text('Analyse Marché IA', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          const Text('Recommandations achat/vente par Claude AI',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                  onPressed: _loadingIA ? null : _analyserMarche,
                  icon: _loadingIA
                      ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: kGreen, strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(_loadingIA
                      ? 'Analyse en cours...' : 'Analyser le marché',
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

      if (_analyseIA != null) Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                blurRadius: 10)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.auto_awesome_rounded, color: kGreen, size: 18),
            SizedBox(width: 8),
            Text('Analyse Stratégique', style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14,
                color: Color(0xFF1E293B))),
          ]),
          const Divider(),
          const SizedBox(height: 8),
          Text(_analyseIA!, style: const TextStyle(
              fontSize: 13, color: Color(0xFF1E293B), height: 1.6)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: _analyserMarche,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Actualiser l\'analyse'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: kGreen,
                  side: const BorderSide(color: kGreen),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)))),
        ]),
      ),
      const SizedBox(height: 16),

      // Conseils rapides
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('💡 Conseils Rapides', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        _conseilItem('🕐 Vendre maintenant',
            'Prix en hausse à Dakar et Banjul — bon moment pour vendre', kGreen),
        _conseilItem('🛒 Acheter aliment',
            'Profitez de la baisse du maïs pour faire des stocks', kBlue),
        _conseilItem('⚠️ Surveiller le Mali',
            'Foyer de grippe aviaire — renforcer la biosécurité', kRed),
        _conseilItem('📅 Tabaski 2026',
            'Forte demande prévue — augmenter la production', kOrange),
      ])),
    ]),
  );

  // ── WIDGETS ──
  Widget _prixCard(Map p, String unite) {
    final tendance = p['tendance'] as String;
    final variation = (p['variation'] as num).toDouble();
    final color = tendance == 'hausse' ? kGreen
        : tendance == 'baisse' ? kRed : Colors.grey;
    final icon = tendance == 'hausse' ? Icons.trending_up_rounded
        : tendance == 'baisse' ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
      child: Row(children: [
        Container(width: 44, height: 44,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p['pays'] as String, style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
          Text(p['ville'] as String, style: const TextStyle(
              color: Colors.grey, fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${_formatFcfa(p['prix'] as int)} FCFA',
              style: const TextStyle(fontWeight: FontWeight.w900,
                  fontSize: 14, color: Color(0xFF1E293B))),
          Row(children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 2),
            Text('${variation > 0 ? '+' : ''}${variation.toStringAsFixed(1)}%',
                style: TextStyle(color: color, fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ]),
        ]),
      ]),
    );
  }

  Widget _intrantCard(Map p) {
    final tendance = p['tendance'] as String;
    final variation = (p['variation'] as num).toDouble();
    final color = tendance == 'hausse' ? kRed
        : tendance == 'baisse' ? kGreen : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 6)]),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p['produit'] as String, style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12,
                  color: Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text('${(p['prix'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA',
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text('${variation > 0 ? '+' : ''}${variation.toStringAsFixed(1)}%',
                style: TextStyle(color: color, fontSize: 11,
                    fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget _actuCard(Map a) {
    final urgent = a['urgent'] as bool;
    final color = urgent ? kRed : kBlue;
    final categorie = a['categorie'] as String;
    final catColor = categorie == 'Santé' ? kRed
        : categorie == 'Prix' ? kGreen
        : categorie == 'Événement' ? kPurple : kBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: urgent ? Border.all(color: kRed.withOpacity(0.3)) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(a['icon'] as String, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Text(a['titre'] as String, style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 13,
              color: urgent ? kRed : const Color(0xFF1E293B)))),
          if (urgent) Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: kRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('URGENT', style: TextStyle(
                  color: kRed, fontSize: 8, fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 8),
        Text(a['description'] as String, style: const TextStyle(
            color: Colors.grey, fontSize: 12, height: 1.4)),
        const SizedBox(height: 8),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: catColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(categorie, style: TextStyle(
                  color: catColor, fontSize: 10, fontWeight: FontWeight.w700))),
          const Spacer(),
          Text(a['date'] as String, style: const TextStyle(
              color: Colors.grey, fontSize: 10)),
        ]),
      ]),
    );
  }

  Widget _conseilItem(String titre, String desc, Color color) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Container(width: 4, height: 40,
            decoration: BoxDecoration(color: color,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre, style: TextStyle(fontWeight: FontWeight.w700,
                  fontSize: 12, color: color)),
              Text(desc, style: const TextStyle(
                  color: Colors.grey, fontSize: 11)),
            ])),
      ]));

  Widget _headerStat(String value, String label, Color color) =>
      Expanded(child: Column(children: [
        Text(value, style: TextStyle(
            color: color, fontSize: 14, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(
            color: Colors.white38, fontSize: 8), textAlign: TextAlign.center),
      ]));

  Widget _card({required Widget child}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8)]),
      child: child);
}