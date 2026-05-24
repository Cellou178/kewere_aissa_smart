import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Notifications
  bool _alerteStock = true;
  bool _alerteMortalite = true;
  bool _rapportHebdo = false;
  bool _rapportMensuel = false;
  bool _alerteTemperature = true;
  bool _alerteHumidite = false;

  // Apparence
  bool _darkMode = false;
  bool _compactMode = false;
  String _langue = 'Français';
  String _devise = 'FCFA';
  String _ville = 'Mbour';

  // Finance
  double _prixVente = FinanceParams.prixVentePoulet;
  double _prixPoussin = FinanceParams.prixPoussin;
  double _salairesMois = FinanceParams.salairesMois;
  double _loyerMois = FinanceParams.loyerMois;

  final _villeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _villeCtrl.text = _ville;
  }

  @override
  void dispose() { _tabCtrl.dispose(); _villeCtrl.dispose(); super.dispose(); }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(children: [
        // Header
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            const Row(children: [
              Icon(Icons.settings_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text('Paramètres', style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
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
                Tab(text: '👤 Compte'),
                Tab(text: '🔔 Alertes'),
                Tab(text: '💰 Finance'),
                Tab(text: '⚙️ App'),
              ],
            ),
          ]),
        ),

        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _buildCompte(),
          _buildAlertes(),
          _buildFinance(),
          _buildApp(),
        ])),
      ]),
    );
  }

  // ── COMPTE ──
  Widget _buildCompte() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // Avatar
      Center(child: Stack(children: [
        Container(
          width: 88, height: 88,
          decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kBlue, kBlueLight]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: kBlue.withOpacity(0.3),
                  blurRadius: 16, offset: const Offset(0, 6))]),
          child: Center(child: Text(
              SessionManager.nom.isNotEmpty
                  ? SessionManager.nom.substring(0, 1).toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white,
                  fontSize: 36, fontWeight: FontWeight.w900))),
        ),
        Positioned(bottom: 0, right: 0, child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: kGreen, shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2)),
          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
        )),
      ])),
      const SizedBox(height: 16),

      // Infos compte
      _section('Informations Personnelles', [
        _infoTile(Icons.person_rounded, 'Nom complet',
            SessionManager.nom.isNotEmpty ? SessionManager.nom : '-', kBlue),
        _infoTile(Icons.email_rounded, 'Email',
            SessionManager.email.isNotEmpty ? SessionManager.email : '-', kPurple),
        _infoTile(Icons.badge_rounded, 'Rôle',
            SessionManager.role.isNotEmpty ? SessionManager.role : '-', kGreen),
      ]),
      const SizedBox(height: 16),

      // Sécurité
      _section('Sécurité', [
        _actionTile(Icons.lock_rounded, 'Changer le mot de passe',
            'Mettre à jour', kBlue, () => _snack('Fonctionnalité bientôt disponible', kOrange)),
        _actionTile(Icons.shield_rounded, 'Authentification 2FA',
            'Désactivée', kOrange, () => _snack('Bientôt disponible', kOrange)),
        _actionTile(Icons.history_rounded, 'Historique des connexions',
            'Voir', kPurple, () => _snack('Bientôt disponible', kOrange)),
      ]),
      const SizedBox(height: 16),

      // Sessions
      _section('Session', [
        _infoTile(Icons.timer_rounded, 'Expiration session',
            '30 minutes d\'inactivité', kBlue),
        _infoTile(Icons.devices_rounded, 'Appareil',
            'Flutter Web', Colors.grey),
      ]),
      const SizedBox(height: 24),

      // Déconnexion
      SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Déconnexion'),
                      content: const Text('Voulez-vous vous déconnecter ?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler')),
                        TextButton(onPressed: () => Navigator.pop(context, true),
                            child: const Text('Déconnexion',
                                style: TextStyle(color: Colors.red))),
                      ],
                    ));
                if (confirm == true) {
                  await SessionManager.clear();
                  Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                          (route) => false);
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Se déconnecter',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  side: BorderSide(color: Colors.red.shade200)))),
    ],
  );

  // ── ALERTES ──
  Widget _buildAlertes() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // Info
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: kBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBlue.withOpacity(0.2))),
        child: const Row(children: [
          Icon(Icons.info_rounded, color: kBlue, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text('Configurez les alertes pour être notifié en temps réel',
              style: TextStyle(color: kBlue, fontSize: 12))),
        ]),
      ),
      const SizedBox(height: 16),

      _section('Alertes Sanitaires', [
        _switchTile('🐔 Mortalité élevée', _alerteMortalite,
            'Alerte si > 5 morts/jour', (v) => setState(() => _alerteMortalite = v)),
        _switchTile('🌡️ Température critique', _alerteTemperature,
            'Alerte si > 33°C ou < 25°C', (v) => setState(() => _alerteTemperature = v)),
        _switchTile('💧 Humidité anormale', _alerteHumidite,
            'Alerte si > 75% ou < 40%', (v) => setState(() => _alerteHumidite = v)),
      ]),
      const SizedBox(height: 16),

      _section('Alertes Stock', [
        _switchTile('📦 Stock bas', _alerteStock,
            'Alerte si quantité ≤ seuil', (v) => setState(() => _alerteStock = v)),
      ]),
      const SizedBox(height: 16),

      _section('Rapports Automatiques', [
        _switchTile('📅 Rapport hebdomadaire', _rapportHebdo,
            'Envoyé chaque lundi', (v) => setState(() => _rapportHebdo = v)),
        _switchTile('📆 Rapport mensuel', _rapportMensuel,
            'Envoyé le 1er du mois', (v) => setState(() => _rapportMensuel = v)),
      ]),
      const SizedBox(height: 16),

      // Sauvegarder
      SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
              onPressed: () => _snack('✅ Paramètres d\'alertes sauvegardés !', kGreen),
              icon: const Icon(Icons.save_rounded),
              label: const Text('Sauvegarder',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)), elevation: 0))),
    ],
  );

  // ── FINANCE ──
  Widget _buildFinance() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: kGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kGreen.withOpacity(0.2))),
        child: const Row(children: [
          Icon(Icons.attach_money_rounded, color: kGreen, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text('Ces paramètres affectent tous les calculs financiers',
              style: TextStyle(color: kGreen, fontSize: 12))),
        ]),
      ),
      const SizedBox(height: 16),

      _section('Prix de Vente', [
        _paramField('🐔 Prix vente poulet (FCFA)', _prixVente,
                (v) => setState(() { _prixVente = v; FinanceParams.prixVentePoulet = v; })),
        _paramField('🐥 Prix poussin (FCFA)', _prixPoussin,
                (v) => setState(() { _prixPoussin = v; FinanceParams.prixPoussin = v; })),
      ]),
      const SizedBox(height: 16),

      _section('Charges Fixes', [
        _paramField('👥 Salaires/mois (FCFA)', _salairesMois,
                (v) => setState(() { _salairesMois = v; FinanceParams.salairesMois = v; })),
        _paramField('🏠 Loyer/mois (FCFA)', _loyerMois,
                (v) => setState(() { _loyerMois = v; FinanceParams.loyerMois = v; })),
      ]),
      const SizedBox(height: 16),

      // Devise
      _section('Devise', [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<String>(
                value: _devise,
                decoration: InputDecoration(
                    labelText: 'Devise',
                    prefixIcon: const Icon(Icons.currency_exchange_rounded,
                        color: kBlueLight, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: const Color(0xFFF8FAFC)),
                items: ['FCFA', 'EUR', 'USD', 'GBP'].map((d) =>
                    DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => setState(() => _devise = v!))),
      ]),
      const SizedBox(height: 16),

      SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
              onPressed: () => _snack('✅ Paramètres financiers sauvegardés !', kGreen),
              icon: const Icon(Icons.save_rounded),
              label: const Text('Sauvegarder',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)), elevation: 0))),
    ],
  );

  // ── APP ──
  Widget _buildApp() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _section('Localisation', [
        Padding(padding: const EdgeInsets.all(12),
            child: TextField(
                controller: _villeCtrl,
                decoration: InputDecoration(
                    labelText: 'Ville météo',
                    prefixIcon: const Icon(Icons.location_on_rounded,
                        color: kBlueLight, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: const Color(0xFFF8FAFC)),
                onSubmitted: (v) => setState(() => _ville = v))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
                value: _langue,
                decoration: InputDecoration(
                    labelText: 'Langue',
                    prefixIcon: const Icon(Icons.language_rounded,
                        color: kBlueLight, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8)),
                items: ['Français', 'English', 'Wolof'].map((l) =>
                    DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (v) => setState(() => _langue = v!))),
        const SizedBox(height: 8),
      ]),
      const SizedBox(height: 16),

      _section('Affichage', [
        _switchTile('🌙 Mode sombre', _darkMode,
            'Interface sombre (bientôt)', (v) {
              setState(() => _darkMode = v);
              _snack('Mode sombre bientôt disponible', kOrange);
            }),
        _switchTile('📱 Mode compact', _compactMode,
            'Interface plus condensée', (v) => setState(() => _compactMode = v)),
      ]),
      const SizedBox(height: 16),

      _section('À propos', [
        _infoTile(Icons.api_rounded, 'Backend',
            'kewere-aissa-smart.onrender.com', kGreen),
        _infoTile(Icons.phone_android_rounded, 'Version', '1.0.0', kBlue),
        _infoTile(Icons.code_rounded, 'Technologie',
            'Flutter + FastAPI', kPurple),
        _infoTile(Icons.psychology_rounded, 'IA',
            'Claude claude-sonnet-4-20250514', kOrange),
        _infoTile(Icons.storage_rounded, 'Base de données',
            'PostgreSQL (Render)', Colors.teal),
      ]),
      const SizedBox(height: 16),

      _section('Données', [
        _actionTile(Icons.delete_outline_rounded, 'Vider le cache',
            'Libérer de l\'espace', kOrange,
                () => _snack('✅ Cache vidé !', kGreen)),
        _actionTile(Icons.backup_rounded, 'Sauvegarder les données',
            'Export complet', kBlue,
                () => _snack('Bientôt disponible', kOrange)),
        _actionTile(Icons.restore_rounded, 'Restaurer',
            'Importer une sauvegarde', Colors.grey,
                () => _snack('Bientôt disponible', kOrange)),
      ]),
      const SizedBox(height: 16),

      SizedBox(width: double.infinity,
          child: ElevatedButton.icon(
              onPressed: () => _snack('✅ Paramètres sauvegardés !', kGreen),
              icon: const Icon(Icons.save_rounded),
              label: const Text('Sauvegarder',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)), elevation: 0))),
    ],
  );

  // ── HELPERS ──
  Widget _section(String title, List<Widget> children) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title.toUpperCase(), style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: Colors.grey, letterSpacing: 1))),
        Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                    blurRadius: 8)]),
            child: Column(children: children)),
      ]);

  Widget _infoTile(IconData icon, String title, String value, Color color) =>
      ListTile(dense: true,
          leading: Container(padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: color, size: 16)),
          title: Text(title, style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13)),
          subtitle: Text(value, style: TextStyle(
              color: Colors.grey.shade500, fontSize: 11)),
          trailing: Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.grey.shade300, size: 12));

  Widget _actionTile(IconData icon, String title, String subtitle,
      Color color, VoidCallback onTap) =>
      ListTile(dense: true,
          onTap: onTap,
          leading: Container(padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: color, size: 16)),
          title: Text(title, style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13)),
          subtitle: Text(subtitle, style: TextStyle(
              color: Colors.grey.shade500, fontSize: 11)),
          trailing: Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.grey.shade300, size: 12));

  Widget _switchTile(String title, bool value, String subtitle,
      Function(bool) onChanged) =>
      SwitchListTile(
          dense: true,
          title: Text(title, style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13)),
          subtitle: Text(subtitle, style: TextStyle(
              color: Colors.grey.shade500, fontSize: 11)),
          value: value,
          activeColor: kBlue,
          onChanged: onChanged);

  Widget _paramField(String label, double value, Function(double) onChanged) {
    final ctrl = TextEditingController(text: value.toStringAsFixed(0));
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 12,
              color: Color(0xFF1E293B)))),
          const SizedBox(width: 10),
          SizedBox(width: 110, child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800,
                  color: kBlue, fontSize: 12),
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  filled: true, fillColor: const Color(0xFFF8FAFC)),
              onSubmitted: (v) => onChanged(double.tryParse(v) ?? value))),
        ]));
  }
}
