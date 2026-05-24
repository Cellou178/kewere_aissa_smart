import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';

class AbonnementScreen extends StatefulWidget {
  const AbonnementScreen({super.key});
  @override
  State<AbonnementScreen> createState() => _AbonnementScreenState();
}

class _AbonnementScreenState extends State<AbonnementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _planSelectionne = 'pro';
  bool _annuel = false;

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'gratuit',
      'nom': 'Gratuit',
      'prix_mensuel': 0,
      'prix_annuel': 0,
      'icon': '🐣',
      'color': kGrey,
      'description': 'Pour démarrer',
      'fonctionnalites': [
        '1 ferme', '2 cycles actifs', 'Dashboard basique',
        'Alertes simples', '❌ IA Claude', '❌ Rapports PDF',
        '❌ Multi-utilisateurs',
      ],
    },
    {
      'id': 'pro',
      'nom': 'Pro',
      'prix_mensuel': 15000,
      'prix_annuel': 144000,
      'icon': '🐔',
      'color': kBlue,
      'description': 'Pour les éleveurs actifs',
      'badge': '⭐ Populaire',
      'fonctionnalites': [
        '5 fermes', 'Cycles illimités', 'Dashboard avancé',
        'Alertes intelligentes', '✅ IA Claude',
        '✅ Rapports PDF/Excel', '3 utilisateurs',
        '✅ Prédictions IA', '✅ Météo avancée',
      ],
    },
    {
      'id': 'enterprise',
      'nom': 'Enterprise',
      'prix_mensuel': 35000,
      'prix_annuel': 336000,
      'icon': '🏆',
      'color': kGreen,
      'description': 'Pour les grandes exploitations',
      'fonctionnalites': [
        'Fermes illimitées', 'Cycles illimités',
        'Toutes les fonctionnalités', '✅ IA Claude avancée',
        '✅ API access', 'Utilisateurs illimités',
        '✅ Support prioritaire', '✅ Formation incluse',
      ],
    },
  ];

  final List<Map<String, dynamic>> _methodesPaiement = [
    {
      'id': 'wave', 'nom': 'Wave', 'icon': '💙',
      'description': 'Paiement mobile Wave',
      'numero': '+221 77 XXX XX XX',
      'color': const Color(0xFF0066CC),
    },
    {
      'id': 'orange_money', 'nom': 'Orange Money', 'icon': '🟠',
      'description': 'Paiement Orange Money',
      'numero': '+221 77 XXX XX XX',
      'color': const Color(0xFFFF6600),
    },
    {
      'id': 'free_money', 'nom': 'Free Money', 'icon': '🟢',
      'description': 'Paiement Free Money',
      'numero': '+221 76 XXX XX XX',
      'color': const Color(0xFF00AA44),
    },
    {
      'id': 'carte', 'nom': 'Carte bancaire', 'icon': '💳',
      'description': 'Visa / Mastercard',
      'numero': '', 'color': kPurple,
    },
  ];

  String _methodeSelectionnee = 'wave';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  String _formatFcfa(int v) {
    if (v == 0) return 'Gratuit';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K FCFA';
    return '$v FCFA';
  }

  int _prixActuel(Map plan) => _annuel
      ? (plan['prix_annuel'] as int)
      : (plan['prix_mensuel'] as int);

  int get _economieAnnuelle {
    final plan = _plans.firstWhere((p) => p['id'] == _planSelectionne);
    return (plan['prix_mensuel'] as int) * 12 -
        (plan['prix_annuel'] as int);
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
                Color(0xFF166534)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            Row(children: [
              const Text('💎', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Abonnement', style: TextStyle(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w900)),
                    Text('Choisissez votre plan', style: TextStyle(
                        color: Colors.white54, fontSize: 11)),
                  ])),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  _toggleBtn('Mensuel', !_annuel),
                  _toggleBtn('Annuel', _annuel),
                ]),
              ),
            ]),
            if (_annuel && _economieAnnuelle > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                    '🎉 Économisez ${_formatFcfa(_economieAnnuelle)}/an',
                    style: const TextStyle(
                        color: Colors.greenAccent, fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
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
                Tab(text: '📋 Plans'),
                Tab(text: '💳 Paiement'),
                Tab(text: '📊 Mon Plan'),
              ],
            ),
          ]),
        ),

        Expanded(child: TabBarView(controller: _tabCtrl, children: [
          _buildPlans(),
          _buildPaiement(),
          _buildMonPlan(),
        ])),
      ]),
    );
  }

  // ── PLANS ──
  Widget _buildPlans() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      ..._plans.map((p) => _planCard(p)),
      const SizedBox(height: 16),
      _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📊 Comparaison', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14,
            color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        _compareRow('Fermes', '1', '5', '∞'),
        _compareRow('Cycles', '2', '∞', '∞'),
        _compareRow('IA Claude', '❌', '✅', '✅'),
        _compareRow('Rapports PDF', '❌', '✅', '✅'),
        _compareRow('Utilisateurs', '1', '3', '∞'),
        _compareRow('Support', 'Email', 'Chat', 'Priorité'),
      ])),
    ],
  );

  Widget _planCard(Map plan) {
    final isSelected = _planSelectionne == plan['id'];
    final color = plan['color'] as Color;
    final prix = _prixActuel(plan);
    final hasBadge = plan.containsKey('badge');

    return GestureDetector(
      onTap: () => setState(() => _planSelectionne = plan['id']),
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
                    ? color.withOpacity(0.15)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isSelected ? 16 : 8)]),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(plan['icon'] as String,
                style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(plan['nom'] as String, style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 15,
                        color: isSelected ? color
                            : const Color(0xFF1E293B))),
                    if (hasBadge) ...[
                      const SizedBox(width: 6),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(plan['badge'] as String,
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700))),
                    ],
                  ]),
                  Text(plan['description'] as String,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11)),
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatFcfa(prix), style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16,
                      color: color)),
                  if (prix > 0) Text(_annuel ? '/an' : '/mois',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 10)),
                ]),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 5, runSpacing: 5,
              children: (plan['fonctionnalites'] as List).map((f) =>
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: (f as String).startsWith('❌')
                            ? Colors.grey.withOpacity(0.08)
                            : color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(f, style: TextStyle(
                        fontSize: 9,
                        color: f.startsWith('❌') ? Colors.grey : color,
                        fontWeight: FontWeight.w500)),
                  )).toList()),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity,
              child: ElevatedButton(
                  onPressed: () => _tabCtrl.animateTo(1),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? color : Colors.grey.shade100,
                      foregroundColor: isSelected
                          ? Colors.white : Colors.grey,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: Text(isSelected
                      ? 'Choisir ce plan' : 'Sélectionner',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13)))),
        ]),
      ),
    );
  }

  // ── PAIEMENT ──
  Widget _buildPaiement() {
    final plan = _plans.firstWhere(
            (p) => p['id'] == _planSelectionne);
    final prix = _prixActuel(plan);
    final color = plan['color'] as Color;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Text(plan['icon'] as String,
                style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plan ${plan['nom']}', style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900,
                      fontSize: 15)),
                  Text(_annuel ? 'Facturation annuelle'
                      : 'Facturation mensuelle',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11)),
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatFcfa(prix), style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900,
                      fontSize: 18)),
                  Text(_annuel ? '/an' : '/mois', style: const TextStyle(
                      color: Colors.white70, fontSize: 10)),
                ]),
          ]),
        ),
        const SizedBox(height: 16),

        _card(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('💳 Méthode de paiement', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14,
              color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          ..._methodesPaiement.map((m) => GestureDetector(
            onTap: () => setState(
                    () => _methodeSelectionnee = m['id']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                  color: _methodeSelectionnee == m['id']
                      ? (m['color'] as Color).withOpacity(0.05)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _methodeSelectionnee == m['id']
                          ? m['color'] as Color
                          : Colors.grey.shade200,
                      width: _methodeSelectionnee == m['id'] ? 2 : 1)),
              child: Row(children: [
                Text(m['icon'] as String,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['nom'] as String, style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(m['description'] as String,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                    ])),
                if (_methodeSelectionnee == m['id'])
                  Icon(Icons.check_circle_rounded,
                      color: m['color'] as Color, size: 20),
              ]),
            ),
          )),
        ])),
        const SizedBox(height: 16),

        if (_methodeSelectionnee != 'carte') _card(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📱 Instructions', style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14,
                      color: Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  _instructionStep('1',
                      'Ouvrez votre application $_methodeSelectionnee'),
                  _instructionStep('2',
                      'Envoyez ${_formatFcfa(prix)} au numéro ci-dessous'),
                  _instructionStep('3',
                      'Référence: KAS-${SessionManager.email.hashCode.abs().toString().substring(0, 6)}'),
                  _instructionStep('4', 'Envoyez le reçu à support@kewere.sn'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: kBlue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kBlue.withOpacity(0.2))),
                    child: Row(children: [
                      const Icon(Icons.phone_rounded, color: kBlue, size: 16),
                      const SizedBox(width: 8),
                      Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Numéro', style: TextStyle(
                                color: Colors.grey, fontSize: 10)),
                            Text(
                                _methodesPaiement.firstWhere(
                                        (m) => m['id'] == _methodeSelectionnee)
                                ['numero'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 15,
                                    color: kBlue)),
                          ]),
                    ]),
                  ),
                ])),
        const SizedBox(height: 16),

        if (prix > 0) SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton.icon(
                onPressed: () => _showConfirmation(),
                icon: const Icon(Icons.payment_rounded, size: 18),
                label: Text('Payer ${_formatFcfa(prix)}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0))),
      ]),
    );
  }

  // ── MON PLAN ──
  Widget _buildMonPlan() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('🐔', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Plan Pro', style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900,
                          fontSize: 16)),
                      const Text('Actif jusqu\'au 24/06/2026',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 11)),
                    ])),
                Container(padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: kGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('✅ Actif', style: TextStyle(
                        color: Colors.greenAccent, fontSize: 11,
                        fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 14),
              _usageBar('Fermes', 2, 5, kBlue),
              const SizedBox(height: 8),
              _usageBar('Cycles actifs', 3, 10, kGreen),
              const SizedBox(height: 8),
              _usageBar('Utilisateurs', 1, 3, kPurple),
            ]),
      ),
      const SizedBox(height: 16),

      _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📋 Historique', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14,
            color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        _paiementRow('24/05/2026', 'Plan Pro - Mai',
            '15 000 FCFA', true),
        _paiementRow('24/04/2026', 'Plan Pro - Avril',
            '15 000 FCFA', true),
        _paiementRow('24/03/2026', 'Plan Pro - Mars',
            '15 000 FCFA', true),
      ])),
      const SizedBox(height: 16),

      _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🆘 Support', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14,
            color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        _supportRow(Icons.email_rounded, 'Email', 'support@kewere.sn'),
        _supportRow(Icons.phone_rounded, 'WhatsApp',
            '+221 77 XXX XX XX'),
        _supportRow(Icons.language_rounded, 'Site web', 'www.kewere.sn'),
      ])),
    ]),
  );

  // ── MODAL ──
  void _showConfirmation() {
    final plan = _plans.firstWhere((p) => p['id'] == _planSelectionne);
    final prix = _prixActuel(plan);
    final methode = _methodesPaiement.firstWhere(
            (m) => m['id'] == _methodeSelectionnee);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Confirmer le paiement', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          _confirmRow('Plan', 'Plan ${plan['nom']}'),
          _confirmRow('Montant', _formatFcfa(prix)),
          _confirmRow('Méthode', methode['nom'] as String),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: kOrange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kOrange.withOpacity(0.2))),
            child: const Row(children: [
              Icon(Icons.info_rounded, color: kOrange, size: 14),
              SizedBox(width: 8),
              Expanded(child: Text(
                  'Activé après confirmation du paiement',
                  style: TextStyle(color: kOrange, fontSize: 11))),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 46,
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                '✅ Demande envoyée ! Nous vous contacterons sous 24h'),
                            backgroundColor: kGreen,
                            behavior: SnackBarBehavior.floating));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0),
                  child: const Text('Confirmer',
                      style: TextStyle(fontWeight: FontWeight.w700)))),
        ]),
      ),
    );
  }

  // ── HELPERS ──
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

  Widget _compareRow(String f, String g, String p, String e) =>
      Padding(padding: const EdgeInsets.only(bottom: 7),
          child: Row(children: [
            Expanded(flex: 2, child: Text(f,
                style: const TextStyle(fontSize: 11))),
            Expanded(child: Text(g, style: const TextStyle(
                fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center)),
            Expanded(child: Text(p, style: TextStyle(
                fontSize: 10, color: kBlue,
                fontWeight: FontWeight.w700),
                textAlign: TextAlign.center)),
            Expanded(child: Text(e, style: TextStyle(
                fontSize: 10, color: kGreen,
                fontWeight: FontWeight.w700),
                textAlign: TextAlign.center)),
          ]));

  Widget _instructionStep(String num, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(width: 22, height: 22,
            decoration: BoxDecoration(
                color: kBlue, borderRadius: BorderRadius.circular(11)),
            child: Center(child: Text(num, style: const TextStyle(
                color: Colors.white, fontSize: 10,
                fontWeight: FontWeight.w800)))),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(
            fontSize: 12, color: Color(0xFF1E293B)))),
      ]));

  Widget _usageBar(String label, int used, int total, Color color) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(
              color: Colors.white70, fontSize: 11)),
          Text('$used/$total', style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 11)),
        ]),
        const SizedBox(height: 3),
        ClipRRect(borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
                value: used / total,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 4)),
      ]);

  Widget _paiementRow(String date, String desc,
      String montant, bool ok) =>
      Padding(padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7)),
                child: Icon(ok ? Icons.check_rounded
                    : Icons.close_rounded,
                    color: ok ? kGreen : kRed, size: 12)),
            const SizedBox(width: 8),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(desc, style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12)),
                  Text(date, style: const TextStyle(
                      color: Colors.grey, fontSize: 10)),
                ])),
            Text(montant, style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 12,
                color: kGreen)),
          ]));

  Widget _supportRow(IconData icon, String label, String value) =>
      Padding(padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: kBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: kBlue, size: 14)),
            const SizedBox(width: 8),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(
                      color: Colors.grey, fontSize: 10)),
                  Text(value, style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12)),
                ])),
          ]));

  Widget _confirmRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(
                color: Colors.grey, fontSize: 12)),
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
              color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: child);
}