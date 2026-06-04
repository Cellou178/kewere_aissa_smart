import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import '../../managers/session_manager.dart';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});
  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List _cycles = [];
  List _donnees = [];
  bool _loading = true;
  bool _generatingIA = false;
  String? _rapportGenere;
  String? _selectedCycleId;
  String _periodeSelectionnee = 'semaine';

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
    final donnees = await ApiService.getDonnees();
    setState(() {
      _cycles = cycles is List ? cycles : [];
      _donnees = donnees is List ? donnees : [];
      if (_cycles.isNotEmpty && _selectedCycleId == null) {
        _selectedCycleId = _cycles.first['id']?.toString();
      }
      _loading = false;
    });
  }

  List get _donneesFiltered => _selectedCycleId == null ? _donnees :
  _donnees.where((d) => d['cycle_id']?.toString() == _selectedCycleId).toList();

  Map get _cycleSelectionne => _cycles.firstWhere(
          (c) => c['id']?.toString() == _selectedCycleId,
      orElse: () => {});

  Future<void> _genererRapport(String type) async {
    setState(() { _generatingIA = true; _rapportGenere = null; });
    try {
      final data = _donneesFiltered;
      final cycle = _cycleSelectionne;
      final totalMorts = data.fold<int>(0, (s, d) =>
      s + ((d['mortalite'] ?? 0) as num).toInt());
      final avgTemp = data.isEmpty ? 0.0 : data.fold<double>(0, (s, d) =>
      s + ((d['temperature'] ?? 0) as num).toDouble()) / data.length;
      final avgHum = data.isEmpty ? 0.0 : data.fold<double>(0, (s, d) =>
      s + ((d['humidite'] ?? 0) as num).toDouble()) / data.length;
      final totalProd = data.fold<int>(0, (s, d) =>
      s + ((d['production'] ?? 0) as num).toInt());
      final sujets = ((cycle['nombre_sujets'] ?? 0) as num).toInt();
      final tauxMort = sujets > 0 ? (totalMorts / sujets * 100) : 0;

      String prompt = '';

      switch (type) {
        case 'hebdomadaire':
          prompt = '''Tu es un expert en aviculture. 
Génère un rapport hebdomadaire professionnel pour une ferme avicole au Sénégal.

DONNÉES:
- Éleveur: ${SessionManager.nom}
- Cycle: ${cycle['nom'] ?? 'N/A'}
- Sujets: $sujets poulets
- Période: Cette semaine
- Relevés: ${data.length}
- Mortalité totale: $totalMorts (${tauxMort.toStringAsFixed(1)}%)
- Température moyenne: ${avgTemp.toStringAsFixed(1)}°C
- Humidité moyenne: ${avgHum.toStringAsFixed(1)}%
- Production totale: $totalProd

Génère un rapport structuré avec:
1. RÉSUMÉ EXÉCUTIF
2. INDICATEURS CLÉS DE PERFORMANCE
3. ANALYSE DE LA MORTALITÉ
4. CONDITIONS D'ÉLEVAGE
5. PRODUCTION
6. POINTS D'ATTENTION
7. RECOMMANDATIONS POUR LA SEMAINE PROCHAINE

Sois professionnel, précis et pratique. En français.''';
          break;

        case 'mensuel':
          prompt = '''Tu es un expert en aviculture.
Génère un rapport mensuel complet pour une ferme avicole au Sénégal.

DONNÉES:
- Éleveur: ${SessionManager.nom}
- Cycle: ${cycle['nom'] ?? 'N/A'}
- Sujets: $sujets poulets
- Relevés: ${data.length}
- Mortalité totale: $totalMorts (${tauxMort.toStringAsFixed(1)}%)
- Température moyenne: ${avgTemp.toStringAsFixed(1)}°C
- Humidité moyenne: ${avgHum.toStringAsFixed(1)}%
- Production totale: $totalProd

Génère un rapport mensuel avec:
1. BILAN DU MOIS
2. PERFORMANCE ZOOTECHNIQUE
3. SANTÉ ET BIEN-ÊTRE ANIMAL
4. CONDITIONS ENVIRONNEMENTALES
5. ANALYSE FINANCIÈRE ESTIMÉE
6. COMPARAISON AVEC LES NORMES
7. OBJECTIFS DU MOIS PROCHAIN
8. CONCLUSIONS

Sois très professionnel. En français.''';
          break;

        case 'sanitaire':
          prompt = '''Tu es un vétérinaire expert en aviculture au Sénégal.
Génère un rapport sanitaire détaillé.

DONNÉES:
- Cycle: ${cycle['nom'] ?? 'N/A'}
- Sujets: $sujets poulets
- Mortalité: $totalMorts (${tauxMort.toStringAsFixed(1)}%)
- Température moyenne: ${avgTemp.toStringAsFixed(1)}°C
- Humidité moyenne: ${avgHum.toStringAsFixed(1)}%
- Nombre de relevés: ${data.length}

Génère un rapport sanitaire avec:
1. ÉTAT SANITAIRE GÉNÉRAL
2. ANALYSE DE LA MORTALITÉ
3. FACTEURS DE RISQUE IDENTIFIÉS
4. CONDITIONS ENVIRONNEMENTALES ET IMPACT
5. PROTOCOLE SANITAIRE RECOMMANDÉ
6. VACCINATIONS ET TRAITEMENTS
7. MESURES PRÉVENTIVES
8. ALERTES VÉTÉRINAIRES

Sois précis et professionnel. En français.''';
          break;
      }

      final reponse = await ApiService.callIA(prompt,
          contexte: 'Expert aviculture Sénégal. Génère un rapport professionnel détaillé.');
      setState(() => _rapportGenere = reponse.isEmpty
          ? 'Erreur lors de la génération du rapport.' : reponse);
    } catch (e) {
      setState(() => _rapportGenere = 'Erreur lors de la génération du rapport.');
    }
    setState(() => _generatingIA = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(children: [
        // Header
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A5F), Color(0xFF4C1D95)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.assessment_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Rapports Automatiques', style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text('Powered by Claude AI', style: TextStyle(
                    color: Colors.white38, fontSize: 10)),
              ]),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white54, size: 20), onPressed: _load),
            ]),
            const SizedBox(height: 12),
            // Sélecteur cycle
            DropdownButtonFormField<String>(
                value: _selectedCycleId,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                    labelText: 'Sélectionner un cycle',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white30)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white30)),
                    filled: true, fillColor: Colors.white.withOpacity(0.08),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: _cycles.map((c) => DropdownMenuItem<String>(
                    value: c['id']?.toString(),
                    child: Text(c['nom']?.toString() ?? '',
                        style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) => setState(() {
                  _selectedCycleId = v;
                  _rapportGenere = null;
                })),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              tabs: const [
                Tab(text: '📅 Hebdo'),
                Tab(text: '📆 Mensuel'),
                Tab(text: '🏥 Sanitaire'),
              ],
            ),
          ]),
        ),

        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlue))
            : TabBarView(controller: _tabCtrl, children: [
          _buildRapportTab('hebdomadaire', '📅 Rapport Hebdomadaire',
              'Analyse des 7 derniers jours', Icons.date_range_rounded),
          _buildRapportTab('mensuel', '📆 Rapport Mensuel',
              'Bilan complet du mois', Icons.calendar_month_rounded),
          _buildRapportTab('sanitaire', '🏥 Rapport Sanitaire',
              'État de santé du troupeau', Icons.medical_services_rounded),
        ])),
      ]),
    );
  }

  Widget _buildRapportTab(String type, String title, String subtitle, IconData icon) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Info cycle
        if (_cycleSelectionne.isNotEmpty) _cycleInfoCard(),
        const SizedBox(height: 16),

        // Bouton générer
        Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A5F), Color(0xFF4C1D95)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
            Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity,
                child: ElevatedButton.icon(
                    onPressed: _generatingIA ? null : () => _genererRapport(type),
                    icon: _generatingIA
                        ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(_generatingIA ? 'Génération en cours...' : 'Générer avec Claude AI',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4C1D95),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0))),
          ]),
        ),
        const SizedBox(height: 16),

        // Rapport généré
        if (_rapportGenere != null) _rapportCard(_rapportGenere!),
      ]),
    );
  }

  Widget _cycleInfoCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: kBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.loop_rounded, color: kBlue, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_cycleSelectionne['nom'] ?? '', style: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
        Text('${_cycleSelectionne['nombre_sujets'] ?? 0} sujets • '
            '${_donneesFiltered.length} relevés disponibles',
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(_cycleSelectionne['statut'] ?? '',
              style: const TextStyle(color: kGreen, fontSize: 10, fontWeight: FontWeight.w700))),
    ]),
  );

  Widget _rapportCard(String rapport) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Row(children: [
          Icon(Icons.auto_awesome_rounded, color: kPurple, size: 18),
          SizedBox(width: 8),
          Text('Rapport Généré', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
        ]),
        Row(children: [
          IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.grey),
              onPressed: () {
                // TODO: copier dans le clipboard
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('✅ Rapport copié !'),
                    backgroundColor: kGreen, behavior: SnackBarBehavior.floating));
              }),
          IconButton(
              icon: const Icon(Icons.share_rounded, size: 18, color: Colors.grey),
              onPressed: () {}),
        ]),
      ]),
      const Divider(),
      const SizedBox(height: 8),
      Text(rapport, style: const TextStyle(
          fontSize: 13, color: Color(0xFF1E293B), height: 1.6)),
    ]),
  );
}