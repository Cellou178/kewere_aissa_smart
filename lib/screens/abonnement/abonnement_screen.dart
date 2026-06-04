import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import '../../managers/session_manager.dart';

class AbonnementScreen extends StatefulWidget {
  const AbonnementScreen({super.key});
  @override
  State<AbonnementScreen> createState() => _AbonnementScreenState();
}

class _AbonnementScreenState extends State<AbonnementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = true;
  bool _annuel = false;

  List _plans = [];
  Map<String, dynamic> _monAbonnement = {};
  List _historique = [];

  String _planSelectionne = 'pro';
  String _methodeSelectionnee = 'wave';

  final List<Map<String, dynamic>> _methodes = [
    {'id': 'wave',         'nom': 'Wave',          'icon': '💙', 'color': const Color(0xFF0066CC)},
    {'id': 'orange_money', 'nom': 'Orange Money',  'icon': '🟠', 'color': const Color(0xFFFF6600)},
    {'id': 'free_money',   'nom': 'Free Money',    'icon': '🟢', 'color': const Color(0xFF00AA44)},
    {'id': 'carte',        'nom': 'Carte bancaire', 'icon': '💳', 'color': kPurple},
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
    final results = await Future.wait([
      ApiService.getAbonnementPlans(),
      ApiService.getMonAbonnement(),
      ApiService.getHistoriqueAbonnement(),
    ]);
    final plans = results[0] as List;
    final monAbo = results[1] as Map<String, dynamic>;
    setState(() {
      _plans = plans;
      _monAbonnement = monAbo;
      _historique = results[2] as List;
      _planSelectionne = monAbo['plan'] as String? ?? 'pro';
      _loading = false;
    });
  }

  String _formatFcfa(num v) {
    if (v == 0) return 'Gratuit';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K FCFA';
    return '$v FCFA';
  }

  num _prix(Map plan) {
    final pm = (plan['prix_mensuel'] as num? ?? 0);
    final pa = (plan['prix_annuel'] as num? ?? 0);
    return _annuel && pa > 0 ? pa : pm;
  }

  Color _planColor(String nom) {
    switch (nom) {
      case 'enterprise': return kGreen;
      case 'pro': return kBlue;
      default: return kGrey;
    }
  }

  String _planIcon(String nom) {
    switch (nom) { case 'enterprise': return '🏆'; case 'pro': return '🐔'; default: return '🐣'; }
  }

  @override
  Widget build(BuildContext context) {
    final planActuel = _monAbonnement['plan'] as String? ?? '—';
    final statutAbo = _monAbonnement['statut'] as String? ?? 'actif';

    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A5F), Color(0xFF166534)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(4, 16, 16, 0),
          child: Column(children: [
            Row(children: [
              // Bouton retour
              if (Navigator.canPop(context))
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              const Text('💎', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Abonnement', style: TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text('Plan actuel : ${planActuel.toUpperCase()} — $statutAbo',
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ])),
              // Toggle Mensuel/Annuel
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _toggleBtn('Mensuel', !_annuel),
                  _toggleBtn('Annuel', _annuel),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabCtrl,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              tabs: const [
                Tab(text: '📋 Plans'),
                Tab(text: '💳 Paiement'),
                Tab(text: '📊 Mon Plan'),
              ],
            ),
          ]),
        ),

        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kGreen))
            : TabBarView(controller: _tabCtrl, children: [
          _buildPlans(),
          _buildPaiement(),
          _buildMonPlan(),
        ])),
      ]),
    );
  }

  // ── ONGLET PLANS ──────────────────────────────────────────────
  Widget _buildPlans() {
    if (_plans.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Chargement des plans...', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
          ]));
    }
    return ListView(padding: const EdgeInsets.all(16), children: [
      ..._plans.map((p) => _planCard(p)),
      const SizedBox(height: 16),
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📊 Comparaison', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        _compareRow('Fermes', _plans.map((p) {
          final max = (p['limites'] as Map?)?['fermes'] ?? 1;
          return (max as num) >= 999 ? '∞' : '$max';
        }).toList()),
        _compareRow('Cycles', _plans.map((p) {
          final max = (p['limites'] as Map?)?['cycles'] ?? 2;
          return (max as num) >= 999 ? '∞' : '$max';
        }).toList()),
        _compareRow('Utilisateurs', _plans.map((p) {
          final max = (p['limites'] as Map?)?['utilisateurs'] ?? 1;
          return (max as num) >= 999 ? '∞' : '$max';
        }).toList()),
        _compareRow('IA Claude',
            _plans.map((p) => p['nom'] == 'gratuit' ? '❌' : '✅').toList()),
        _compareRow('Rapports PDF',
            _plans.map((p) => p['nom'] == 'gratuit' ? '❌' : '✅').toList()),
      ])),
    ]);
  }

  Widget _planCard(Map plan) {
    final nom = plan['nom'] as String? ?? '';
    final isSelected = _planSelectionne == nom;
    final color = _planColor(nom);
    final prix = _prix(plan);
    final isActuel = _monAbonnement['plan'] == nom;
    final limites = plan['limites'] as Map? ?? {};

    return GestureDetector(
      onTap: () => setState(() => _planSelectionne = nom),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSelected ? color : Colors.grey.shade200,
                width: isSelected ? 2 : 1),
            boxShadow: [BoxShadow(
                color: isSelected
                    ? color.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: isSelected ? 16 : 8)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(_planIcon(nom), style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(nom.toUpperCase(), style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 15,
                    color: isSelected ? color : const Color(0xFF1E293B))),
                if (isActuel) ...[
                  const SizedBox(width: 6),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color,
                          borderRadius: BorderRadius.circular(20)),
                      child: const Text('✅ Actuel', style: TextStyle(
                          color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700))),
                ],
              ]),
              Text(plan['description'] as String? ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_formatFcfa(prix), style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 16, color: color)),
              if (prix > 0) Text(_annuel ? '/an' : '/mois',
                  style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ]),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 4, children: [
            _chip('${limites['fermes'] ?? 1} fermes', color),
            _chip('${limites['cycles'] ?? 2} cycles', color),
            _chip('${limites['utilisateurs'] ?? 1} users', color),
            if (nom != 'gratuit') _chip('✅ IA Claude', color),
            if (nom != 'gratuit') _chip('✅ PDF/Excel', color),
          ]),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity,
              child: ElevatedButton(
                  onPressed: () => _tabCtrl.animateTo(1),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? color : Colors.grey.shade100,
                      foregroundColor: isSelected ? Colors.white : Colors.grey,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: Text(isSelected ? 'Choisir ce plan' : 'Sélectionner',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)))),
        ]),
      ),
    );
  }

  // ── ONGLET PAIEMENT ───────────────────────────────────────────
  Widget _buildPaiement() {
    final plan = _plans.firstWhere(
            (p) => p['nom'] == _planSelectionne,
        orElse: () => <String, dynamic>{});
    if (plan.isEmpty) return const Center(child: Text('Sélectionnez un plan'));
    final prix = _prix(plan);
    final color = _planColor(_planSelectionne);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Récap plan
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.8), color],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Text(_planIcon(_planSelectionne),
                style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Plan ${_planSelectionne.toUpperCase()}',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w900, fontSize: 15)),
              Text(_annuel ? 'Facturation annuelle' : 'Facturation mensuelle',
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_formatFcfa(prix), style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
              if (prix > 0) Text(_annuel ? '/an' : '/mois',
                  style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // Méthodes de paiement
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('💳 Méthode de paiement', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          ..._methodes.map((m) => GestureDetector(
            onTap: () => setState(() => _methodeSelectionnee = m['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                  color: _methodeSelectionnee == m['id']
                      ? (m['color'] as Color).withValues(alpha: 0.05)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _methodeSelectionnee == m['id']
                          ? m['color'] as Color : Colors.grey.shade200,
                      width: _methodeSelectionnee == m['id'] ? 2 : 1)),
              child: Row(children: [
                Text(m['icon'] as String, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(child: Text(m['nom'] as String, style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13))),
                if (_methodeSelectionnee == m['id'])
                  Icon(Icons.check_circle_rounded,
                      color: m['color'] as Color, size: 20),
              ]),
            ),
          )),
        ])),
        const SizedBox(height: 16),

        // Instructions
        if (_methodeSelectionnee != 'carte') _card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('📱 Instructions', style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14,
                  color: Color(0xFF1E293B))),
              const SizedBox(height: 12),
              _step('1', 'Ouvrez votre application ${_methodes.firstWhere((m) => m['id'] == _methodeSelectionnee)['nom']}'),
              _step('2', 'Envoyez ${_formatFcfa(prix)} au numéro KAS'),
              _step('3', 'Référence: KAS-${SessionManager.entrepriseId.hashCode.abs().toString().substring(0, 6).toUpperCase()}'),
              _step('4', 'Envoyez le reçu à support@kewere.sn'),
            ])),
        const SizedBox(height: 16),

        if (prix > 0) SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton.icon(
                onPressed: () => _confirmerPaiement(plan),
                icon: const Icon(Icons.payment_rounded, size: 18),
                label: Text('Payer ${_formatFcfa(prix)}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: color, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0))),

        if (prix == 0) SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton.icon(
                onPressed: () => _activerGratuit(),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Activer le plan Gratuit',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: kGrey, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0))),
      ]),
    );
  }

  // ── ONGLET MON PLAN ───────────────────────────────────────────
  Widget _buildMonPlan() {
    if (_monAbonnement.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Impossible de charger votre abonnement',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
          ]));
    }

    final plan = _monAbonnement['plan'] as String? ?? 'gratuit';
    final statut = _monAbonnement['statut'] as String? ?? 'actif';
    final dateFin = _monAbonnement['date_fin'] as String?;
    final color = _planColor(plan);
    final limites = _monAbonnement['limites'] as Map? ?? {};
    final nbFermes = (_monAbonnement['nb_fermes'] as num? ?? 0).toInt();
    final nbCycles = (_monAbonnement['nb_cycles'] as num? ?? 0).toInt();
    final nbUsers  = (_monAbonnement['nb_utilisateurs'] as num? ?? 0).toInt();
    final maxFermes = (limites['fermes'] as num? ?? 1).toInt();
    final maxCycles = (limites['cycles'] as num? ?? 2).toInt();
    final maxUsers  = (limites['utilisateurs'] as num? ?? 1).toInt();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        // Carte plan actuel
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [const Color(0xFF0F172A), const Color(0xFF1E3A5F)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(_planIcon(plan), style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Plan ${plan.toUpperCase()}', style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                Text(dateFin != null
                    ? 'Actif jusqu\'au ${dateFin.substring(0, 10)}'
                    : 'Sans expiration',
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ])),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: statut == 'actif'
                          ? kGreen.withValues(alpha: 0.2)
                          : kRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(statut == 'actif' ? '✅ Actif' : '⚠️ $statut',
                      style: TextStyle(
                          color: statut == 'actif'
                              ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 11, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 16),
            _usageBar('Fermes utilisées', nbFermes, maxFermes, kBlue),
            const SizedBox(height: 8),
            _usageBar('Cycles actifs', nbCycles, maxCycles >= 999 ? nbCycles + 5 : maxCycles, kGreen),
            const SizedBox(height: 8),
            _usageBar('Utilisateurs', nbUsers, maxUsers >= 999 ? nbUsers + 5 : maxUsers, kPurple),
          ]),
        ),
        const SizedBox(height: 16),

        // Bouton upgrade
        if (plan != 'enterprise') SizedBox(width: double.infinity, height: 46,
            child: ElevatedButton.icon(
                onPressed: () => _tabCtrl.animateTo(0),
                icon: const Icon(Icons.upgrade_rounded, size: 18),
                label: const Text('Passer à un plan supérieur',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: color, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0))),
        if (plan != 'enterprise') const SizedBox(height: 16),

        // Historique depuis l'API
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('📋 Historique paiements', style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14,
                color: Color(0xFF1E293B))),
            IconButton(icon: const Icon(Icons.refresh_rounded,
                size: 16, color: Colors.grey), onPressed: _load),
          ]),
          const SizedBox(height: 8),
          if (_historique.isEmpty) const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('Aucun historique',
                style: TextStyle(color: Colors.grey))),
          ),
          ..._historique.map((h) {
            final hPlan = h['plan'] as String? ?? '—';
            final hStatut = h['statut'] as String? ?? '—';
            final hPrix = (h['prix'] as num? ?? 0);
            final hDate = h['date_debut'] as String? ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        color: kGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(7)),
                    child: Icon(hStatut == 'actif' || hStatut == 'expire'
                        ? Icons.check_rounded : Icons.close_rounded,
                        color: hStatut == 'actif' ? kGreen : Colors.grey,
                        size: 12)),
                const SizedBox(width: 8),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Plan ${hPlan.toUpperCase()}', style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12)),
                  Text(hDate.length >= 10 ? hDate.substring(0, 10) : hDate,
                      style: const TextStyle(color: Colors.grey, fontSize: 10)),
                ])),
                Text(_formatFcfa(hPrix), style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12,
                    color: hPrix > 0 ? kGreen : Colors.grey)),
              ]),
            );
          }),
        ])),
        const SizedBox(height: 16),

        // Support
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🆘 Support', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14,
              color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          _supportRow(Icons.email_rounded,    'Email',    'support@kewere.sn'),
          _supportRow(Icons.phone_rounded,    'WhatsApp', '+221 77 XXX XX XX'),
          _supportRow(Icons.language_rounded, 'Site web', 'www.kewere.sn'),
        ])),
      ]),
    );
  }

  // ── ACTIONS ───────────────────────────────────────────────────
  Future<void> _activerGratuit() async {
    final res = await ApiService.renouvelerAbonnement(
        SessionManager.entrepriseId, 'gratuit', 0);
    if ((res['status'] as int? ?? 500) < 300) {
      _load();
      if (mounted) {
        _tabCtrl.animateTo(2);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Plan Gratuit activé'),
            backgroundColor: kGreen,
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  void _confirmerPaiement(Map plan) {
    final prix = _prix(plan);
    final methode = _methodes.firstWhere((m) => m['id'] == _methodeSelectionnee);
    final duree = _annuel ? 12 : 1;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Confirmer le paiement', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          _confirmRow('Plan', plan['nom'].toString().toUpperCase()),
          _confirmRow('Durée', _annuel ? '12 mois' : '1 mois'),
          _confirmRow('Montant', _formatFcfa(prix)),
          _confirmRow('Méthode', methode['nom'] as String),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: kOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kOrange.withValues(alpha: 0.2))),
            child: const Row(children: [
              Icon(Icons.info_rounded, color: kOrange, size: 14),
              SizedBox(width: 8),
              Expanded(child: Text(
                  'L\'abonnement sera activé après confirmation du paiement par l\'admin.',
                  style: TextStyle(color: kOrange, fontSize: 11))),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 46,
              child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Enregistrement de la demande via API
                    final res = await ApiService.renouvelerAbonnement(
                        SessionManager.entrepriseId,
                        plan['nom'].toString(), duree);
                    if (mounted) {
                      final ok = (res['status'] as int? ?? 500) < 300;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok
                              ? '✅ Demande envoyée ! Activé sous 24h.'
                              : '❌ Erreur: ${res['body']?['detail'] ?? 'Réessayez'}'),
                          backgroundColor: ok ? kGreen : kRed,
                          behavior: SnackBarBehavior.floating));
                      if (ok) _load();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0),
                  child: const Text('Confirmer',
                      style: TextStyle(fontWeight: FontWeight.w700)))),
        ]),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────
  Widget _toggleBtn(String label, bool active) => GestureDetector(
      onTap: () => setState(() => _annuel = label == 'Annuel'),
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(16)),
          child: Text(label, style: TextStyle(
              color: active ? kBlue : Colors.white60,
              fontSize: 10, fontWeight: FontWeight.w700))));

  Widget _compareRow(String label, List<String> vals) {
    final colors = [Colors.grey, kBlue, kGreen, kPurple];
    return Padding(padding: const EdgeInsets.only(bottom: 7),
        child: Row(children: [
          Expanded(flex: 2, child: Text(label,
              style: const TextStyle(fontSize: 11))),
          ...vals.asMap().entries.map((e) => Expanded(
              child: Text(e.value,
                  style: TextStyle(fontSize: 10,
                      color: colors[e.key % colors.length],
                      fontWeight: e.key == 0
                          ? FontWeight.normal : FontWeight.w700),
                  textAlign: TextAlign.center))),
        ]));
  }

  Widget _chip(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(
          fontSize: 9, color: color, fontWeight: FontWeight.w600)));

  Widget _step(String num, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(width: 22, height: 22,
            decoration: BoxDecoration(
                color: kBlue, borderRadius: BorderRadius.circular(11)),
            child: Center(child: Text(num, style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(
            fontSize: 12, color: Color(0xFF1E293B)))),
      ]));

  Widget _usageBar(String label, int used, int total, Color color) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          Text('$used / ${total >= 999 ? "∞" : total}',
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
        ]),
        const SizedBox(height: 3),
        ClipRRect(borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
                value: total <= 0 ? 0 : (used / total).clamp(0.0, 1.0),
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 4)),
      ]);

  Widget _supportRow(IconData icon, String label, String value) =>
      Padding(padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: kBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: kBlue, size: 14)),
            const SizedBox(width: 8),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              Text(value, style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12)),
            ])),
          ]));

  Widget _confirmRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 12,
            color: Color(0xFF1E293B))),
      ]));

  Widget _card({required Widget child}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
      child: child);
}
