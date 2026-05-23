import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../../services/api_service.dart';

class VitrineScreen extends StatefulWidget {
  const VitrineScreen({super.key});
  @override
  State<VitrineScreen> createState() => _VitrineScreenState();
}

class _VitrineScreenState extends State<VitrineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List _cycles = [];
  List _stocks = [];
  bool _loading = true;
  bool _loadingIA = false;
  String? _descriptionIA;

  // Catalogue produits à vendre
  final List<Map<String, dynamic>> _produits = [
    {
      'nom': 'Poulets de chair vivants',
      'categorie': 'Volaille',
      'prix': 3500,
      'unite': 'par tête',
      'disponible': true,
      'quantite': 850,
      'icon': '🐔',
      'color': kOrange,
      'description': 'Poulets Cobb 500, 6 semaines, poids moyen 2.2kg',
    },
    {
      'nom': 'Poulets abattus',
      'categorie': 'Volaille',
      'prix': 4500,
      'unite': 'par kg',
      'disponible': true,
      'quantite': 200,
      'icon': '🍗',
      'color': kRed,
      'description': 'Poulets nettoyés et préparés, livraison possible',
    },
    {
      'nom': 'Œufs frais',
      'categorie': 'Œufs',
      'prix': 150,
      'unite': 'par unité',
      'disponible': false,
      'quantite': 0,
      'icon': '🥚',
      'color': kYellow,
      'description': 'Œufs de poules pondeuses, calibre A',
    },
    {
      'nom': 'Fumier de volaille',
      'categorie': 'Engrais',
      'prix': 5000,
      'unite': 'par sac 50kg',
      'disponible': true,
      'quantite': 30,
      'icon': '🌱',
      'color': kGreen,
      'description': 'Engrais organique naturel, idéal pour maraîchage',
    },
    {
      'nom': 'Poussins d\'un jour',
      'categorie': 'Poussins',
      'prix': 700,
      'unite': 'par poussin',
      'disponible': false,
      'quantite': 0,
      'icon': '🐥',
      'color': kYellow,
      'description': 'Poussins Ross 308, vaccinés et sexés',
    },
  ];

  // Commandes reçues (simulées)
  final List<Map<String, dynamic>> _commandes = [
    {
      'client': 'Modou Diallo',
      'telephone': '77 123 45 67',
      'produit': 'Poulets de chair vivants',
      'quantite': 50,
      'montant': 175000,
      'statut': 'confirme',
      'date': '23/05/2026',
    },
    {
      'client': 'Fatou Sow',
      'telephone': '70 987 65 43',
      'produit': 'Poulets abattus',
      'quantite': 20,
      'montant': 90000,
      'statut': 'en_attente',
      'date': '22/05/2026',
    },
    {
      'client': 'Ibrahima Ndiaye',
      'telephone': '76 456 78 90',
      'produit': 'Fumier de volaille',
      'quantite': 5,
      'montant': 25000,
      'statut': 'livre',
      'date': '20/05/2026',
    },
  ];

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
    final cycles = await ApiService.getCycles();
    final stocks = await ApiService.getStocks();
    setState(() {
      _cycles = cycles is List ? cycles : [];
      _stocks = stocks is List ? stocks : [];
      _loading = false;
    });
  }

  Future<void> _genererDescription(Map produit) async {
    setState(() => _loadingIA = true);
    try {
      final prompt = '''Tu es un expert en marketing avicole au Sénégal.
Génère une description commerciale attractive pour ce produit avicole.

PRODUIT: ${produit['nom']}
CATÉGORIE: ${produit['categorie']}
PRIX: ${produit['prix']} FCFA ${produit['unite']}
QUANTITÉ: ${produit['quantite']}
DESCRIPTION: ${produit['description']}

Génère:
1. Un titre accrocheur (1 ligne)
2. Description courte attractive (2-3 phrases)
3. Points forts (3 bullets)
4. Appel à l'action

En français, style commercial professionnel, adapté au marché sénégalais.''';

      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 400,
          'messages': [{'role': 'user', 'content': prompt}],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _descriptionIA = data['content'][0]['text'] ?? '');
      }
    } catch (e) {
      setState(() => _descriptionIA = 'Génération indisponible.');
    }
    setState(() => _loadingIA = false);
  }

  double get _chiffreAffaires => _commandes.fold<double>(0,
          (s, c) => s + ((c['montant'] as num).toDouble()));
  int get _commandesEnAttente => _commandes
      .where((c) => c['statut'] == 'en_attente').length;
  int get _produitsDisponibles => _produits
      .where((p) => p['disponible'] == true).length;

  String _formatFcfa(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M FCFA';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K FCFA';
    return '$v FCFA';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAjouterProduit(),
          backgroundColor: kGreen,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Ajouter produit',
              style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700))),
      body: Column(children: [
        // Header
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A5F),
                Color(0xFF166534)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            Row(children: [
              const Text('🏪', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ma Vitrine', style: TextStyle(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w900)),
                    Text('Catalogue & Commandes',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ])),
              IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.white54, size: 20),
                  onPressed: _load),
            ]),
            const SizedBox(height: 12),

            // Stats
            Row(children: [
              _headerStat('$_produitsDisponibles', 'Produits\ndispo',
                  Colors.greenAccent),
              _headerStat('${_commandes.length}', 'Commandes\ntotales',
                  Colors.white),
              _headerStat('$_commandesEnAttente', 'En\nattente',
                  _commandesEnAttente > 0
                      ? Colors.amber : Colors.greenAccent),
              _headerStat(_formatFcfa(_chiffreAffaires.toInt()),
                  'CA\ntotal', Colors.amber),
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
              tabs: [
                Tab(text: '🛍️ Catalogue ($_produitsDisponibles)'),
                Tab(text: '📦 Commandes (${_commandes.length})'),
                Tab(text: '🤖 IA Marketing'),
              ],
            ),
          ]),
        ),

        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlue))
            : TabBarView(controller: _tabCtrl, children: [
          _buildCatalogue(),
          _buildCommandes(),
          _buildMarketing(),
        ])),
      ]),
    );
  }

  // ── CATALOGUE ──
  Widget _buildCatalogue() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
    children: [
      // Info stock lié
      if (_stocks.isNotEmpty) Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: kBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBlue.withOpacity(0.2))),
        child: Row(children: [
          const Icon(Icons.link_rounded, color: kBlue, size: 16),
          const SizedBox(width: 8),
          Text('${_stocks.length} produit(s) en stock disponibles',
              style: const TextStyle(color: kBlue, fontSize: 12)),
        ]),
      ),
      if (_stocks.isNotEmpty) const SizedBox(height: 12),

      // Produits disponibles
      const Text('✅ Disponibles', style: TextStyle(
          fontWeight: FontWeight.w800, fontSize: 14,
          color: Color(0xFF1E293B))),
      const SizedBox(height: 8),
      ..._produits.where((p) => p['disponible'] == true)
          .map((p) => _produitCard(p)),
      const SizedBox(height: 16),

      // Produits indisponibles
      const Text('⏳ Bientôt disponibles', style: TextStyle(
          fontWeight: FontWeight.w800, fontSize: 14,
          color: Colors.grey)),
      const SizedBox(height: 8),
      ..._produits.where((p) => p['disponible'] == false)
          .map((p) => _produitCard(p)),
    ],
  );

  Widget _produitCard(Map p) {
    final disponible = p['disponible'] as bool;
    final color = disponible ? (p['color'] as Color) : Colors.grey;

    return GestureDetector(
      onTap: () => _showDetailProduit(p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: !disponible
                ? Border.all(color: Colors.grey.shade200) : null,
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8)]),
        child: Column(children: [
          // Header produit
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16))),
            child: Row(children: [
              Container(width: 50, height: 50,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text(p['icon'] as String,
                      style: const TextStyle(fontSize: 26)))),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['nom'] as String, style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14,
                        color: disponible ? const Color(0xFF1E293B)
                            : Colors.grey)),
                    Text(p['categorie'] as String, style: TextStyle(
                        color: color, fontSize: 11,
                        fontWeight: FontWeight.w600)),
                  ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatFcfa(p['prix'] as int), style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 15,
                        color: color)),
                    Text(p['unite'] as String, style: const TextStyle(
                        color: Colors.grey, fontSize: 10)),
                  ]),
            ]),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            child: Row(children: [
              if (disponible) ...[
                _chip(Icons.inventory_rounded,
                    '${p['quantite']} unités', color),
                const SizedBox(width: 8),
              ],
              Container(padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: disponible
                          ? kGreen.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                      disponible ? '✅ Disponible' : '⏳ Indisponible',
                      style: TextStyle(
                          color: disponible ? kGreen : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w700))),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade300, size: 12),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── COMMANDES ──
  Widget _buildCommandes() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // Résumé financier
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [kGreen, Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: kGreen.withOpacity(0.3),
                blurRadius: 12, offset: const Offset(0, 4))]),
        child: Row(children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chiffre d\'Affaires', style: TextStyle(
                    color: Colors.white70, fontSize: 12)),
                SizedBox(height: 4),
              ]),
          const SizedBox(width: 8),
          Expanded(child: Text(
              _formatFcfa(_chiffreAffaires.toInt()),
              style: const TextStyle(color: Colors.white,
                  fontSize: 24, fontWeight: FontWeight.w900))),
          Column(children: [
            _miniStat('${_commandes.length}', 'Total'),
            _miniStat('$_commandesEnAttente', 'En attente'),
          ]),
        ]),
      ),
      const SizedBox(height: 16),

      // Liste commandes
      ..._commandes.map((c) => _commandeCard(c)),

      const SizedBox(height: 16),
      // Ajouter commande
      GestureDetector(
        onTap: () => _showAjouterCommande(),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBlue.withOpacity(0.3)),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_rounded, color: kBlue, size: 20),
                const SizedBox(width: 8),
                const Text('Nouvelle commande', style: TextStyle(
                    color: kBlue, fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
        ),
      ),
    ],
  );

  Widget _commandeCard(Map c) {
    final statut = c['statut'] as String;
    final color = statut == 'confirme' ? kBlue
        : statut == 'livre' ? kGreen : kOrange;
    final statusLabel = statut == 'confirme' ? '✅ Confirmé'
        : statut == 'livre' ? '🚚 Livré' : '⏳ En attente';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: color, width: 3)),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.1),
                  radius: 20,
                  child: Text(
                      (c['client'] as String).substring(0, 1).toUpperCase(),
                      style: TextStyle(color: color,
                          fontWeight: FontWeight.w900))),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c['client'] as String, style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13,
                    color: Color(0xFF1E293B))),
                Text(c['telephone'] as String, style: const TextStyle(
                    color: Colors.grey, fontSize: 11)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(_formatFcfa(c['montant'] as int), style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 14,
                    color: color)),
                Text(c['date'] as String, style: const TextStyle(
                    color: Colors.grey, fontSize: 10)),
              ]),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _chip(Icons.shopping_bag_rounded,
                  '${c['quantite']} × ${c['produit']}', kBlue),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(statusLabel, style: TextStyle(
                      color: color, fontSize: 10,
                      fontWeight: FontWeight.w700))),
            ]),
          ]),
    );
  }

  // ── MARKETING IA ──
  Widget _buildMarketing() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF166534)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          const Text('🤖', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          const Text('Marketing IA', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900,
              fontSize: 16)),
          const Text(
              'Générez des descriptions attractives pour vos produits',
              style: TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center),
        ]),
      ),
      const SizedBox(height: 16),

      // Sélection produit
      _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Choisir un produit', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14,
            color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        ..._produits.map((p) => GestureDetector(
          onTap: () => _genererDescription(p),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
            child: Row(children: [
              Text(p['icon'] as String,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text(p['nom'] as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13))),
              Container(padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: kGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('Générer',
                      style: TextStyle(color: kGreen, fontSize: 10,
                          fontWeight: FontWeight.w700))),
            ]),
          ),
        )),
      ])),
      const SizedBox(height: 16),

      // Résultat IA
      if (_loadingIA) const Center(child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(children: [
          CircularProgressIndicator(color: kGreen),
          SizedBox(height: 12),
          Text('Génération en cours...',
              style: TextStyle(color: Colors.grey)),
        ]),
      )),

      if (_descriptionIA != null && !_loadingIA) Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.auto_awesome_rounded, color: kGreen, size: 18),
                SizedBox(width: 8),
                Text('Description Générée', style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14,
                    color: Color(0xFF1E293B))),
              ]),
              const Divider(),
              const SizedBox(height: 8),
              Text(_descriptionIA!, style: const TextStyle(
                  fontSize: 13, color: Color(0xFF1E293B), height: 1.6)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('✅ Copié dans le presse-papier !'),
                              backgroundColor: kGreen,
                              behavior: SnackBarBehavior.floating));
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copier'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: kGreen,
                        side: const BorderSide(color: kGreen),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: const Text('Partager'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: kBlue,
                        side: const BorderSide(color: kBlue),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))))),
              ]),
            ]),
      ),
    ]),
  );

  // ── MODALS ──
  void _showDetailProduit(Map p) {
    final disponible = p['disponible'] as bool;
    final color = disponible ? (p['color'] as Color) : Colors.grey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(24))),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Header produit
              Container(padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [color.withOpacity(0.8), color],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    Text(p['icon'] as String,
                        style: const TextStyle(fontSize: 40)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['nom'] as String, style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900, fontSize: 18)),
                          Text(p['categorie'] as String,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 8),
                          Text(_formatFcfa(p['prix'] as int),
                              style: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w900, fontSize: 22)),
                          Text(p['unite'] as String,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                        ])),
                  ])),
              const SizedBox(height: 16),

              // Description
              _card(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📋 Description', style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14,
                        color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    Text(p['description'] as String,
                        style: const TextStyle(color: Colors.grey,
                            fontSize: 13, height: 1.5)),
                    if (disponible) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        _chip(Icons.inventory_rounded,
                            '${p['quantite']} disponibles', color),
                      ]),
                    ],
                  ])),
              const SizedBox(height: 12),

              // Contact
              _card(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📞 Pour commander', style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14,
                        color: Color(0xFF1E293B))),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.person_rounded,
                          color: kBlue, size: 16),
                      const SizedBox(width: 8),
                      Text(SessionManager.nom.isNotEmpty
                          ? SessionManager.nom : 'Kewere Aissa Smart',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                  ])),
              const SizedBox(height: 16),

              if (disponible) SizedBox(width: double.infinity,
                  child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAjouterCommande();
                      },
                      icon: const Icon(Icons.shopping_cart_rounded,
                          size: 18),
                      label: const Text('Passer une commande',
                          style: TextStyle(
                              fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0))),
            ]),
          )),
        ]),
      ),
    );
  }

  void _showAjouterProduit() {
    final nomCtrl = TextEditingController();
    final prixCtrl = TextEditingController();
    final qteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20, right: 20, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Nouveau Produit', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          _field(nomCtrl, 'Nom du produit', Icons.shopping_bag_rounded),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _field(prixCtrl, 'Prix (FCFA)',
                Icons.attach_money_rounded, isNumber: true)),
            const SizedBox(width: 10),
            Expanded(child: _field(qteCtrl, 'Quantité',
                Icons.inventory_rounded, isNumber: true)),
          ]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton(
                  onPressed: () {
                    if (nomCtrl.text.isNotEmpty) {
                      setState(() => _produits.add({
                        'nom': nomCtrl.text,
                        'categorie': 'Autre',
                        'prix': int.tryParse(prixCtrl.text) ?? 0,
                        'unite': 'unité',
                        'disponible': true,
                        'quantite': int.tryParse(qteCtrl.text) ?? 0,
                        'icon': '📦',
                        'color': kBlue,
                        'description': '',
                      }));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('✅ Produit ajouté !'),
                              backgroundColor: kGreen,
                              behavior: SnackBarBehavior.floating));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0),
                  child: const Text('Ajouter',
                      style: TextStyle(fontWeight: FontWeight.w700)))),
        ]),
      ),
    );
  }

  void _showAjouterCommande() {
    final clientCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final qteCtrl = TextEditingController();
    String produitSelected = _produits.first['nom'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModal) => Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20, right: 20, top: 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Nouvelle Commande', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B))),
              const SizedBox(height: 16),
              _field(clientCtrl, 'Nom du client',
                  Icons.person_rounded),
              const SizedBox(height: 10),
              _field(telCtrl, 'Téléphone', Icons.phone_rounded,
                  isPhone: true),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                  value: produitSelected,
                  decoration: InputDecoration(
                      labelText: 'Produit',
                      prefixIcon: const Icon(
                          Icons.shopping_bag_rounded,
                          color: kBlueLight, size: 18),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC)),
                  items: _produits.map((p) => DropdownMenuItem(
                      value: p['nom'] as String,
                      child: Text(p['nom'] as String))).toList(),
                  onChanged: (v) =>
                      setModal(() => produitSelected = v!)),
              const SizedBox(height: 10),
              _field(qteCtrl, 'Quantité',
                  Icons.numbers_rounded, isNumber: true),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 48,
                  child: ElevatedButton(
                      onPressed: () {
                        if (clientCtrl.text.isNotEmpty) {
                          final produit = _produits.firstWhere(
                                  (p) => p['nom'] == produitSelected);
                          final qte = int.tryParse(qteCtrl.text) ?? 1;
                          final montant = (produit['prix'] as int) * qte;
                          setState(() => _commandes.add({
                            'client': clientCtrl.text,
                            'telephone': telCtrl.text,
                            'produit': produitSelected,
                            'quantite': qte,
                            'montant': montant,
                            'statut': 'en_attente',
                            'date': '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                          }));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('✅ Commande ajoutée !'),
                                  backgroundColor: kGreen,
                                  behavior: SnackBarBehavior.floating));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0),
                      child: const Text('Enregistrer la commande',
                          style: TextStyle(
                              fontWeight: FontWeight.w700)))),
            ]),
          )),
    );
  }

  Widget _miniStat(String value, String label) => Column(children: [
    Text(value, style: const TextStyle(
        color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
    Text(label, style: const TextStyle(
        color: Colors.white70, fontSize: 9)),
  ]);

  Widget _headerStat(String value, String label, Color color) =>
      Expanded(child: Column(children: [
        Text(value, style: TextStyle(
            color: color, fontSize: 13,
            fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(
            color: Colors.white38, fontSize: 8),
            textAlign: TextAlign.center),
      ]));

  Widget _chip(IconData icon, String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(
            color: color, fontSize: 10,
            fontWeight: FontWeight.w600)),
      ]));

  Widget _card({required Widget child}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: child);

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false, bool isPhone = false}) =>
      TextField(controller: ctrl,
          keyboardType: isNumber ? TextInputType.number
              : isPhone ? TextInputType.phone : TextInputType.text,
          decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: kBlueLight, size: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC)));
}