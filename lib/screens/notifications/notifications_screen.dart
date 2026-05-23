import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../../services/notification_service.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = false;
  final _telCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _sendingWA = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _verifierAlertes();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _telCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifierAlertes() async {
    setState(() => _loading = true);
    final donnees = await ApiService.getDonnees();
    final stocks = await ApiService.getStocks();
    final cycles = await ApiService.getCycles();
    NotificationService.verifierAlertes(
      donnees: donnees is List ? donnees : [],
      stocks: stocks is List ? stocks : [],
      cycles: cycles is List ? cycles : [],
    );
    setState(() => _loading = false);
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'danger': return kRed;
      case 'warning': return kOrange;
      case 'success': return kGreen;
      default: return kBlue;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'danger': return Icons.dangerous_rounded;
      case 'warning': return Icons.warning_rounded;
      case 'success': return Icons.check_circle_rounded;
      default: return Icons.info_rounded;
    }
  }

  List get _nonLues => NotificationService.notifications
      .where((n) => !n['lu']).toList();
  List get _critiques => NotificationService.notifications
      .where((n) => n['type'] == 'danger').toList();

  @override
  Widget build(BuildContext context) {
    final nbNonLues = NotificationService.nonLues;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(children: [
        // Header
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: nbNonLues > 0
                  ? [const Color(0xFF7F1D1D), const Color(0xFF1E3A5F)]
                  : [const Color(0xFF0F172A), const Color(0xFF1E3A5F)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            Row(children: [
              Icon(nbNonLues > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Notifications', style: TextStyle(
                    color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w900)),
                Text('${NotificationService.notifications.length} au total • $nbNonLues non lues',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              ])),
              if (nbNonLues > 0) TextButton(
                  onPressed: () {
                    NotificationService.marquerToutLu();
                    setState(() {});
                  },
                  child: const Text('Tout lire',
                      style: TextStyle(color: Colors.white70, fontSize: 12))),
              IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.white54, size: 20),
                  onPressed: _verifierAlertes),
            ]),
            const SizedBox(height: 12),

            // Stats
            Row(children: [
              _headerStat('${NotificationService.notifications.length}',
                  'Total', Colors.white),
              _headerStat('$nbNonLues', 'Non lues',
                  nbNonLues > 0 ? Colors.redAccent : Colors.greenAccent),
              _headerStat('${_critiques.length}', 'Critiques',
                  _critiques.isNotEmpty ? Colors.redAccent : Colors.greenAccent),
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
                Tab(text: 'Toutes (${NotificationService.notifications.length})'),
                Tab(text: '🔴 Non lues ($nbNonLues)'),
                Tab(text: '📱 WhatsApp'),
              ],
            ),
          ]),
        ),

        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlue))
            : TabBarView(controller: _tabCtrl, children: [
          _buildToutes(),
          _buildNonLues(),
          _buildWhatsApp(),
        ])),
      ]),
    );
  }

  // ── TOUTES ──
  Widget _buildToutes() {
    final notifs = NotificationService.notifications;
    if (notifs.isEmpty) return _empty();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Actions
        Row(children: [
          Expanded(child: OutlinedButton.icon(
              onPressed: () {
                NotificationService.marquerToutLu();
                setState(() {});
              },
              icon: const Icon(Icons.done_all_rounded, size: 16),
              label: const Text('Tout lire', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                  foregroundColor: kBlue,
                  side: const BorderSide(color: kBlue),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(
              onPressed: () {
                NotificationService.supprimerTout();
                setState(() {});
              },
              icon: const Icon(Icons.delete_sweep_rounded, size: 16),
              label: const Text('Tout supprimer',
                  style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                  foregroundColor: kRed,
                  side: const BorderSide(color: kRed),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))))),
        ]),
        const SizedBox(height: 12),
        ...notifs.map((n) => _notifCard(n)),
      ],
    );
  }

  // ── NON LUES ──
  Widget _buildNonLues() {
    if (_nonLues.isEmpty) return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.notifications_none_rounded,
          size: 56, color: Colors.grey),
      const SizedBox(height: 12),
      const Text('Tout est lu !', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700)),
      const Text('Aucune notification non lue',
          style: TextStyle(color: Colors.grey)),
    ]));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _nonLues.map((n) => _notifCard(n)).toList(),
    );
  }

  // ── WHATSAPP ──
  Widget _buildWhatsApp() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      // Info
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF075E54), Color(0xFF128C7E)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16)),
        child: const Row(children: [
          Text('💬', style: TextStyle(fontSize: 32)),
          SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WhatsApp Notifications', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                Text('Envoyez des alertes directement sur WhatsApp',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ])),
        ]),
      ),
      const SizedBox(height: 16),

      // Envoyer message
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📤 Envoyer un message', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14,
            color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        TextField(
            controller: _telCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
                labelText: 'Numéro WhatsApp (ex: 771234567)',
                prefixIcon: const Icon(Icons.phone_rounded,
                    color: kBlueLight, size: 18),
                prefixText: '+221 ',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: const Color(0xFFF8FAFC))),
        const SizedBox(height: 12),
        TextField(
            controller: _msgCtrl,
            maxLines: 4,
            decoration: InputDecoration(
                labelText: 'Message',
                hintText: 'Saisissez votre message...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: const Color(0xFFF8FAFC))),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
                onPressed: _sendingWA ? null : () async {
                  if (_telCtrl.text.isEmpty || _msgCtrl.text.isEmpty) return;
                  setState(() => _sendingWA = true);
                  final ok = await NotificationService.envoyerWhatsApp(
                      telephone: _telCtrl.text, message: _msgCtrl.text);
                  setState(() => _sendingWA = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok
                          ? '✅ Message envoyé !'
                          : '❌ Erreur d\'envoi'),
                      backgroundColor: ok ? kGreen : kRed,
                      behavior: SnackBarBehavior.floating));
                },
                icon: _sendingWA
                    ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_sendingWA ? 'Envoi...' : 'Envoyer sur WhatsApp',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0))),
      ])),
      const SizedBox(height: 16),

      // Messages prédéfinis
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📋 Messages Prédéfinis', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14,
            color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        _messagePredef('🚨 Alerte mortalité', 'Envoyer une alerte critique', () {
          _msgCtrl.text = NotificationService.genererMessageAlerte(
              type: 'mortalite_critique', cycle: null, donnee: null);
          _tabCtrl.animateTo(2);
        }),
        _messagePredef('🌡️ Alerte température', 'Notifier une température élevée', () {
          _msgCtrl.text = NotificationService.genererMessageAlerte(
              type: 'temperature', cycle: null, donnee: null);
        }),
        _messagePredef('📊 Rapport hebdomadaire', 'Envoyer le résumé de la semaine', () {
          _msgCtrl.text = NotificationService.genererMessageAlerte(
              type: 'rapport_hebdo', cycle: null, donnee: null);
        }),
        _messagePredef('📱 Notification générale', 'Message personnalisé', () {
          _msgCtrl.text = NotificationService.genererMessageAlerte(
              type: 'general', cycle: null, donnee: null);
        }),
      ])),
      const SizedBox(height: 16),

      // Paramètres WhatsApp
      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('⚙️ Paramètres', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 14,
            color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        _paramWA('Alertes automatiques mortalité', true),
        _paramWA('Alertes stock bas', true),
        _paramWA('Rapport hebdomadaire auto', false),
        _paramWA('Alertes température', true),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: kOrange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kOrange.withOpacity(0.2))),
          child: const Row(children: [
            Icon(Icons.info_rounded, color: kOrange, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text(
                'Pour activer les envois automatiques, configurez votre clé API CallMeBot',
                style: TextStyle(color: kOrange, fontSize: 11))),
          ]),
        ),
      ])),
    ]),
  );

  Widget _notifCard(Map n) {
    final type = n['type'] ?? 'info';
    final lu = n['lu'] as bool;
    final color = _typeColor(type);
    final date = n['date'] as String? ?? '';
    DateTime? dt;
    try { dt = DateTime.parse(date); } catch (_) {}

    return Dismissible(
      key: Key(n['id'] as String? ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
              color: kRed, borderRadius: BorderRadius.circular(12)),
          child: const Align(alignment: Alignment.centerRight,
              child: Padding(padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.delete_rounded,
                      color: Colors.white, size: 20)))),
      onDismissed: (_) {
        NotificationService.supprimer(n['id'] as String? ?? '');
        setState(() {});
      },
      child: GestureDetector(
        onTap: () {
          NotificationService.marquerLu(n['id'] as String? ?? '');
          setState(() {});
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: lu ? Colors.white : color.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: lu ? Colors.grey.shade200 : color.withOpacity(0.25),
                  width: lu ? 1 : 1.5),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(lu ? 0.08 : 0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(_typeIcon(type), color: color, size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(n['titre'] ?? '', style: TextStyle(
                    fontWeight: lu ? FontWeight.w600 : FontWeight.w800,
                    fontSize: 13, color: const Color(0xFF1E293B)))),
                if (!lu) Container(width: 8, height: 8,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle)),
              ]),
              const SizedBox(height: 2),
              Text(n['message'] ?? '', style: const TextStyle(
                  color: Colors.grey, fontSize: 11)),
              if (dt != null) ...[
                const SizedBox(height: 3),
                Text('${dt.day}/${dt.month} à ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 10)),
              ],
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _messagePredef(String titre, String desc, VoidCallback onTap) =>
      ListTile(
        dense: true,
        onTap: onTap,
        leading: Container(padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.message_rounded,
                color: Color(0xFF25D366), size: 16)),
        title: Text(titre, style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.grey, size: 12),
      );

  Widget _paramWA(String label, bool value) => StatefulBuilder(
      builder: (_, setLocal) => SwitchListTile(
          dense: true,
          title: Text(label, style: const TextStyle(fontSize: 12)),
          value: value,
          activeColor: const Color(0xFF25D366),
          onChanged: (v) => setLocal(() {})));

  Widget _empty() => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.notifications_none_rounded, size: 56, color: Colors.grey),
    const SizedBox(height: 12),
    const Text('Aucune notification', style: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w700)),
    const Text('Tout va bien !', style: TextStyle(color: Colors.grey)),
    const SizedBox(height: 16),
    ElevatedButton.icon(
        onPressed: _verifierAlertes,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('Vérifier les alertes'),
        style: ElevatedButton.styleFrom(
            backgroundColor: kBlue, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)))),
  ]));

  Widget _headerStat(String value, String label, Color color) =>
      Expanded(child: Column(children: [
        Text(value, style: TextStyle(
            color: color, fontSize: 16, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(
            color: Colors.white38, fontSize: 9)),
      ]));

  Widget _card({required Widget child}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8)]),
      child: child);
}