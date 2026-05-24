import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';

class MeteoScreen extends StatefulWidget {
  const MeteoScreen({super.key});
  @override
  State<MeteoScreen> createState() => _MeteoScreenState();
}

class _MeteoScreenState extends State<MeteoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final List<String> _villes = [
    'Mbour', 'Dakar', 'Thies', 'Rufisque',
    'Kaolack', 'Saint-Louis', 'Ziguinchor',
    'Tambacounda', 'Touba', 'Diourbel'
  ];

  Map<String, Map> _meteos = {};
  bool _loading = true;
  bool _loadingIA = false;
  String? _conseilIA;
  String _villeSelectionnee = 'Mbour';
  Map _meteoDetail = {};

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
    Map<String, Map> result = {};
    for (final ville in _villes) {
      final m = await ApiService.getMeteo(ville);
      if (m.isNotEmpty) result[ville] = m;
    }
    setState(() {
      _meteos = result;
      if (result.containsKey(_villeSelectionnee)) {
        _meteoDetail = result[_villeSelectionnee]!;
      }
      _loading = false;
    });
    _genererConseil();
  }

  Future<void> _genererConseil() async {
    if (_meteoDetail.isEmpty) return;
    setState(() { _loadingIA = true; _conseilIA = null; });
    try {
      final temp = (_meteoDetail['main']?['temp'] ?? 0).toStringAsFixed(1);
      final humidity = _meteoDetail['main']?['humidity'] ?? 0;
      final windSpeed = (_meteoDetail['wind']?['speed'] ?? 0).toStringAsFixed(1);
      final desc = _meteoDetail['weather']?[0]?['description'] ?? '';

      final prompt = '''Tu es un expert en aviculture au Sénégal.
Analyse ces conditions météo et donne des conseils d'élevage.

MÉTÉO À $_villeSelectionnee:
- Température: $temp°C
- Humidité: $humidity%
- Vent: ${windSpeed}m/s
- Conditions: $desc

Donne 3-4 conseils pratiques pour:
1. Adapter la ventilation des bâtiments
2. Gérer l'alimentation et l'hydratation
3. Prévenir les risques sanitaires
4. Optimiser le bien-être des poulets

Sois concis et pratique. En français.''';

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
        setState(() => _conseilIA = data['content'][0]['text'] ?? '');
      }
    } catch (e) {
      setState(() => _conseilIA = 'Conseil indisponible.');
    }
    setState(() => _loadingIA = false);
  }

  Color _tempColor(double temp) =>
      temp > 35 ? kRed : temp > 32 ? kOrange : temp > 28 ? const Color(0xFFF59E0B) : kGreen;

  String _tempIcon(double temp, int humidity) {
    if (temp > 35) return '🌡️';
    if (humidity > 80) return '🌧️';
    if (temp > 30) return '☀️';
    return '⛅';
  }

  String _alerteMeteo(double temp, int humidity) {
    if (temp > 37) return '🚨 Chaleur extrême — stress thermique critique !';
    if (temp > 33) return '⚠️ Températures élevées — renforcer la ventilation';
    if (humidity > 80) return '⚠️ Humidité excessive — risque maladies respiratoires';
    if (temp < 18) return '⚠️ Températures fraîches — surveiller le chauffage';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    // Ville la plus chaude
    String? villePlusChaude;
    double maxTemp = 0;
    _meteos.forEach((ville, data) {
      final t = ((data['main']?['temp'] ?? 0) as num).toDouble();
      if (t > maxTemp) { maxTemp = t; villePlusChaude = ville; }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(children: [
        // Header
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: maxTemp > 33
                  ? [const Color(0xFF7F1D1D), const Color(0xFF1E3A5F)]
                  : [const Color(0xFF0F172A), const Color(0xFF0891B2)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.cloud_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Météo Sénégal', style: TextStyle(
                    color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w900)),
                Text('Conditions en temps réel',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
              ])),
              IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.white54, size: 20),
                  onPressed: _load),
            ]),
            const SizedBox(height: 12),

            // Météo principale sélectionnée
            if (_meteoDetail.isNotEmpty) _headerMeteo(),
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
                Tab(text: '🗺️ Carte Météo'),
                Tab(text: '📊 Détails'),
                Tab(text: '🤖 Conseils IA'),
              ],
            ),
          ]),
        ),

        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlue))
            : TabBarView(controller: _tabCtrl, children: [
          _buildCarteMeteo(),
          _buildDetails(),
          _buildConseils(),
        ])),
      ]),
    );
  }

  Widget _headerMeteo() {
    final temp = ((_meteoDetail['main']?['temp'] ?? 0) as num).toDouble();
    final humidity = (_meteoDetail['main']?['humidity'] ?? 0) as int;
    final desc = _meteoDetail['weather']?[0]?['description'] ?? '';
    final color = _tempColor(temp);
    final alerte = _alerteMeteo(temp, humidity);

    return Column(children: [
      // Alerte
      if (alerte.isNotEmpty) Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const SizedBox(width: 4),
          Expanded(child: Text(alerte, style: const TextStyle(
              color: Colors.white, fontSize: 11,
              fontWeight: FontWeight.w600))),
        ]),
      ),

      // Sélecteur ville
      DropdownButtonFormField<String>(
          value: _villeSelectionnee,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
              labelText: 'Ville',
              labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
              prefixIcon: const Icon(Icons.location_on_rounded,
                  color: Colors.white54, size: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white30)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white30)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8)),
          items: _villes.map((v) => DropdownMenuItem(
              value: v,
              child: Text(v, style: const TextStyle(
                  color: Colors.white)))).toList(),
          onChanged: (v) {
            setState(() {
              _villeSelectionnee = v!;
              _meteoDetail = _meteos[v] ?? {};
            });
            _genererConseil();
          }),
    ]);
  }

  // ── CARTE MÉTÉO ──
  Widget _buildCarteMeteo() => RefreshIndicator(
    onRefresh: _load, color: kBlue,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Résumé
        Row(children: [
          _miniStat('${_meteos.length}', 'Villes', kBlue),
          const SizedBox(width: 8),
          _miniStat(
              '${_meteos.values.map((m) => ((m['main']?['temp'] ?? 0) as num).toDouble()).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}°',
              'Max', kRed),
          const SizedBox(width: 8),
          _miniStat(
              '${_meteos.values.map((m) => ((m['main']?['temp'] ?? 0) as num).toDouble()).reduce((a, b) => a < b ? a : b).toStringAsFixed(0)}°',
              'Min', kGreen),
        ]),
        const SizedBox(height: 16),

        // Liste villes
        ..._meteos.entries.map((e) => _meteoCard(e.key, e.value)),
      ],
    ),
  );

  Widget _meteoCard(String ville, Map data) {
    final temp = ((data['main']?['temp'] ?? 0) as num).toDouble();
    final humidity = (data['main']?['humidity'] ?? 0) as int;
    final desc = data['weather']?[0]?['description'] ?? '';
    final windSpeed = ((data['wind']?['speed'] ?? 0) as num).toStringAsFixed(1);
    final tempMax = ((data['main']?['temp_max'] ?? 0) as num).toStringAsFixed(0);
    final tempMin = ((data['main']?['temp_min'] ?? 0) as num).toStringAsFixed(0);
    final color = _tempColor(temp);
    final icon = _tempIcon(temp, humidity);
    final isSelected = ville == _villeSelectionnee;

    return GestureDetector(
      onTap: () {
        setState(() {
          _villeSelectionnee = ville;
          _meteoDetail = data;
        });
        _genererConseil();
        _tabCtrl.animateTo(1);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: isSelected ? Border.all(color: color, width: 2) : null,
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
        child: Row(children: [
          Container(width: 48, height: 48,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(icon,
                  style: const TextStyle(fontSize: 26)))),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(ville, style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14,
                  color: Color(0xFF1E293B))),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text('Sélectionnée', style: TextStyle(
                        color: color, fontSize: 8,
                        fontWeight: FontWeight.w700))),
              ],
            ]),
            Text(desc, style: TextStyle(
                color: Colors.grey.shade600, fontSize: 11)),
            const SizedBox(height: 4),
            Row(children: [
              _chip('💧 $humidity%', Colors.blue),
              const SizedBox(width: 4),
              _chip('💨 ${windSpeed}m/s', Colors.grey),
              const SizedBox(width: 4),
              _chip('↕ $tempMin-$tempMax°', kOrange),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${temp.toStringAsFixed(1)}°C', style: TextStyle(
                fontWeight: FontWeight.w900, fontSize: 20, color: color)),
            _alerteBadge(temp, humidity),
          ]),
        ]),
      ),
    );
  }

  Widget _alerteBadge(double temp, int humidity) {
    if (temp > 33 || humidity > 80) {
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
              color: kRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6)),
          child: const Text('⚠️ Alerte', style: TextStyle(
              color: kRed, fontSize: 8, fontWeight: FontWeight.w700)));
    }
    return const SizedBox();
  }

  // ── DÉTAILS ──
  Widget _buildDetails() {
    if (_meteoDetail.isEmpty) return const Center(
        child: Text('Sélectionnez une ville'));

    final temp = ((_meteoDetail['main']?['temp'] ?? 0) as num).toDouble();
    final feelsLike = ((_meteoDetail['main']?['feels_like'] ?? 0) as num).toDouble();
    final humidity = (_meteoDetail['main']?['humidity'] ?? 0) as int;
    final windSpeed = ((_meteoDetail['wind']?['speed'] ?? 0) as num).toDouble();
    final windDeg = (_meteoDetail['wind']?['deg'] ?? 0) as int;
    final pressure = (_meteoDetail['main']?['pressure'] ?? 0) as int;
    final visibility = ((_meteoDetail['visibility'] ?? 0) as num).toInt();
    final tempMax = ((_meteoDetail['main']?['temp_max'] ?? 0) as num).toDouble();
    final tempMin = ((_meteoDetail['main']?['temp_min'] ?? 0) as num).toDouble();
    final desc = _meteoDetail['weather']?[0]?['description'] ?? '';
    final color = _tempColor(temp);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Hero météo
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3),
                  blurRadius: 16, offset: const Offset(0, 6))]),
          child: Row(children: [
            Text(_tempIcon(temp, humidity),
                style: const TextStyle(fontSize: 56)),
            const SizedBox(width: 16),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_villeSelectionnee, style: const TextStyle(
                  color: Colors.white70, fontSize: 13)),
              Text('${temp.toStringAsFixed(1)}°C', style: const TextStyle(
                  color: Colors.white, fontSize: 36,
                  fontWeight: FontWeight.w900)),
              Text(desc, style: const TextStyle(
                  color: Colors.white70, fontSize: 13)),
              Text('Ressenti: ${feelsLike.toStringAsFixed(1)}°C',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),

        // Grille détails
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            _detailCard(Icons.water_drop_rounded, 'Humidité',
                '$humidity%', Colors.blue,
                humidity > 75 ? '⚠️ Élevée' : '✅ Normale'),
            _detailCard(Icons.air_rounded, 'Vent',
                '${windSpeed.toStringAsFixed(1)} m/s', Colors.grey,
                'Direction: $windDeg°'),
            _detailCard(Icons.compress_rounded, 'Pression',
                '$pressure hPa', kPurple, 'Normal: 1013 hPa'),
            _detailCard(Icons.visibility_rounded, 'Visibilité',
                '${(visibility / 1000).toStringAsFixed(1)} km', kBlue,
                visibility > 5000 ? '✅ Bonne' : '⚠️ Réduite'),
            _detailCard(Icons.thermostat_rounded, 'Temp. Max',
                '${tempMax.toStringAsFixed(1)}°C', kRed,
                tempMax > 35 ? '🔥 Critique' : 'Normal'),
            _detailCard(Icons.thermostat_outlined, 'Temp. Min',
                '${tempMin.toStringAsFixed(1)}°C', kGreen, 'Nuit'),
          ],
        ),
        const SizedBox(height: 16),

        // Impact sur l'élevage
        _card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🐔 Impact sur l\'Élevage', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14,
              color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          _impactRow('Ventilation',
              temp > 33 ? '🔴 Maximale requise' : '🟢 Normale',
              temp > 33 ? kRed : kGreen),
          _impactRow('Hydratation',
              temp > 30 ? '🟠 Augmenter eau +20%' : '🟢 Normale',
              temp > 30 ? kOrange : kGreen),
          _impactRow('Alimentation',
              temp > 33 ? '🟠 Nourrir tôt le matin' : '🟢 Normale',
              temp > 33 ? kOrange : kGreen),
          _impactRow('Densité',
              humidity > 75 ? '🔴 Réduire si possible' : '🟢 OK',
              humidity > 75 ? kRed : kGreen),
          _impactRow('Risque maladie',
              (temp > 33 || humidity > 75) ? '🔴 Élevé' : '🟢 Faible',
              (temp > 33 || humidity > 75) ? kRed : kGreen),
        ])),
      ]),
    );
  }

  // ── CONSEILS IA ──
  Widget _buildConseils() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      // Bouton
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF0891B2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          const Text('🌤️', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text('Conseils Météo pour $_villeSelectionnee',
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, fontSize: 15)),
          const Text('Recommandations IA basées sur les conditions actuelles',
              style: TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                  onPressed: _loadingIA ? null : _genererConseil,
                  icon: _loadingIA
                      ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: const Color(0xFF0891B2),
                          strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(_loadingIA
                      ? 'Génération...' : 'Actualiser les conseils',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0891B2),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0))),
        ]),
      ),
      const SizedBox(height: 16),

      if (_loadingIA) const Center(child: Column(children: [
        SizedBox(height: 20),
        CircularProgressIndicator(color: Color(0xFF0891B2)),
        SizedBox(height: 12),
        Text('Analyse des conditions météo...',
            style: TextStyle(color: Colors.grey)),
      ])),

      if (_conseilIA != null && !_loadingIA) _card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: Color(0xFF0891B2), size: 18),
                  SizedBox(width: 8),
                  Text('Conseils d\'Élevage', style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14,
                      color: Color(0xFF1E293B))),
                ]),
                const Divider(),
                const SizedBox(height: 8),
                Text(_conseilIA!, style: const TextStyle(
                    fontSize: 13, color: Color(0xFF1E293B), height: 1.6)),
              ])),
      const SizedBox(height: 16),

      // Alertes toutes villes
      _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🚨 Alertes Météo', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14,
            color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        ..._meteos.entries.map((e) {
          final temp = ((e.value['main']?['temp'] ?? 0) as num).toDouble();
          final humidity = (e.value['main']?['humidity'] ?? 0) as int;
          final alerte = _alerteMeteo(temp, humidity);
          if (alerte.isEmpty) return const SizedBox();
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: kRed.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kRed.withOpacity(0.2))),
            child: Row(children: [
              const Icon(Icons.warning_rounded, color: kRed, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.key, style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12)),
                Text(alerte, style: const TextStyle(
                    color: kRed, fontSize: 11)),
              ])),
            ]),
          );
        }),
        if (_meteos.values.every((m) {
          final t = ((m['main']?['temp'] ?? 0) as num).toDouble();
          final h = (m['main']?['humidity'] ?? 0) as int;
          return _alerteMeteo(t, h).isEmpty;
        })) const Row(children: [
          Icon(Icons.check_circle_rounded, color: kGreen, size: 18),
          SizedBox(width: 8),
          Text('Aucune alerte météo au Sénégal',
              style: TextStyle(color: kGreen, fontSize: 12)),
        ]),
      ])),
    ]),
  );

  // ── HELPERS ──
  Widget _detailCard(IconData icon, String label, String value,
      Color color, String sub) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16)),
          const SizedBox(width: 8),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(
                color: Colors.grey, fontSize: 9)),
            Text(value, style: TextStyle(
                fontWeight: FontWeight.w900, fontSize: 13, color: color)),
            Text(sub, style: const TextStyle(
                color: Colors.grey, fontSize: 9)),
          ])),
        ]),
      );

  Widget _impactRow(String label, String value, Color color) =>
      Padding(padding: const EdgeInsets.only(bottom: 8),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(
                color: Colors.grey, fontSize: 12)),
            Text(value, style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          ]));

  Widget _miniStat(String value, String label, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(children: [
          Text(value, style: TextStyle(
              fontWeight: FontWeight.w900, fontSize: 18, color: color)),
          Text(label, style: TextStyle(
              color: color.withOpacity(0.7), fontSize: 10)),
        ]),
      ));

  Widget _chip(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(
          color: color, fontSize: 9, fontWeight: FontWeight.w600)));

  Widget _card({required Widget child}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: child);
}