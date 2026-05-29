import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../../services/api_service.dart';

class AccesScreen extends StatefulWidget {
  const AccesScreen({super.key});
  @override
  State<AccesScreen> createState() => _AccesScreenState();
}

class _AccesScreenState extends State<AccesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List _employes = [];
  bool _loading = true;
  String _recherche = '';

  Map<String, List<Map<String, dynamic>>> _permissions = {};
  bool _permissionsLoaded = false;

  final List<Map<String, dynamic>> _roles = [
    {
      'role': 'admin',
      'label': 'Administrateur',
      'icon': Icons.admin_panel_settings_rounded,
      'color': kRed,
      'desc': 'Accès complet à toutes les fonctionnalités',
      'badge': '👑',
    },
    {
      'role': 'proprietaire',
      'label': 'Propriétaire',
      'icon': Icons.business_rounded,
      'color': kBlue,
      'desc': 'Gestion complète sauf suppression données',
      'badge': '🏆',
    },
    {
      'role': 'manager',
      'label': 'Manager',
      'icon': Icons.manage_accounts_rounded,
      'color': kPurple,
      'desc': 'Supervision opérationnelle sans accès finance',
      'badge': '⭐',
    },
    {
      'role': 'employe',
      'label': 'Employé',
      'icon': Icons.person_rounded,
      'color': kGreen,
      'desc': 'Saisie données et consultation limitée',
      'badge': '👷',
    },
  ];

  String _roleSelectionne = 'admin';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  static IconData _moduleIcon(String module) {
    switch (module) {
      case 'Dashboard': return Icons.dashboard_rounded;
      case 'Fermes': return Icons.agriculture_rounded;
      case 'Cycles': return Icons.loop_rounded;
      case 'Finance': return Icons.attach_money_rounded;
      case 'Employés': return Icons.people_rounded;
      case 'Stocks': return Icons.inventory_rounded;
      case 'Rapports': return Icons.assessment_rounded;
      case 'Paramètres': return Icons.settings_rounded;
      default: return Icons.circle_rounded;
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getEmployes(),
      ApiService.getPermissions(),
    ]);
    final e = results[0] as List;
    final permsRaw = results[1] as Map<String, dynamic>;
    final perms = <String, List<Map<String, dynamic>>>{};
    permsRaw.forEach((role, modules) {
      perms[role] = (modules as List).map((m) {
        final map = Map<String, dynamic>.from(m as Map);
        map['icon'] = _moduleIcon(map['module'] as String);
        return map;
      }).toList();
    });
    setState(() {
      _employes = e;
      _permissions = perms;
      _permissionsLoaded = true;
      _loading = false;
    });
  }

  Future<void> _togglePermission(String role, String module, String type, bool value) async {
    final perms = _permissions[role] ?? [];
    final idx = perms.indexWhere((p) => p['module'] == module);
    if (idx == -1) return;
    final p = Map<String, dynamic>.from(perms[idx]);
    p[type] = value;
    setState(() => perms[idx] = p);
    await ApiService.updatePermission({
      'role': role,
      'module': module,
      'lecture': p['lecture'],
      'ecriture': p['ecriture'],
      'suppression': p['suppression'],
    });
  }

  List get _employesFiltres => _employes.where((e) =>
  (e['nom'] ?? '').toLowerCase().contains(_recherche.toLowerCase()) ||
      (e['poste'] ?? '').toLowerCase().contains(_recherche.toLowerCase())).toList();

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return kRed;
      case 'proprietaire': return kBlue;
      case 'manager': return kPurple;
      default: return kGreen;
    }
  }

  String _roleBadge(String role) {
    switch (role) {
      case 'admin': return '👑';
      case 'proprietaire': return '🏆';
      case 'manager': return '⭐';
      default: return '👷';
    }
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
              colors: [Color(0xFF0F172A), Color(0xFF1E3A5F),
                Color(0xFF4C1D95)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.security_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Accès & Rôles', style: TextStyle(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w900)),
                    Text('Gestion des permissions utilisateurs',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ])),
              IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.white54, size: 20),
                  onPressed: _load),
            ]),
            const SizedBox(height: 12),

            // Stats
            Row(children: [
              _headerStat('${_employes.length}', 'Utilisateurs',
                  Colors.white),
              _headerStat(
                  '${_employes.where((e) => e['role'] == 'admin').length}',
                  'Admins', Colors.redAccent),
              _headerStat(
                  '${_employes.where((e) => e['role'] == 'manager').length}',
                  'Managers', Colors.purpleAccent),
              _headerStat(
                  '${_employes.where((e) => e['role'] == 'employe').length}',
                  'Employés', Colors.greenAccent),
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
              tabs: const [
                Tab(text: '👥 Utilisateurs'),
                Tab(text: '🔐 Permissions'),
                Tab(text: '📋 Rôles'),
              ],
            ),
          ]),
        ),

        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kBlue))
            : TabBarView(controller: _tabCtrl, children: [
          _buildUtilisateurs(),
          _buildPermissions(),
          _buildRoles(),
        ])),
      ]),
    );
  }

  // ── UTILISATEURS ──
  Widget _buildUtilisateurs() => Column(children: [
    // Recherche
    Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
            hintText: 'Rechercher un utilisateur...',
            prefixIcon: const Icon(Icons.search_rounded,
                color: kBlueLight, size: 20),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8)),
        onChanged: (v) => setState(() => _recherche = v),
      ),
    ),

    // Mon compte
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _monCompteCard(),
    ),
    const SizedBox(height: 8),

    // Liste utilisateurs
    Expanded(child: _employesFiltres.isEmpty
        ? const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.people_outline_rounded,
          size: 56, color: Colors.grey),
      SizedBox(height: 12),
      Text('Aucun utilisateur',
          style: TextStyle(fontSize: 16,
              fontWeight: FontWeight.w700)),
    ]))
        : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _employesFiltres.length,
        itemBuilder: (_, i) => _utilisateurCard(
            _employesFiltres[i]))),
  ]);

  Widget _monCompteCard() {
    final role = SessionManager.role;
    final color = _roleColor(role);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3),
              blurRadius: 12, offset: const Offset(0, 4))]),
      child: Row(children: [
        CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2),
            radius: 24,
            child: Text(
                SessionManager.nom.isNotEmpty
                    ? SessionManager.nom.substring(0, 1).toUpperCase()
                    : 'U',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w900, fontSize: 20))),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(SessionManager.nom.isNotEmpty
              ? SessionManager.nom : 'Utilisateur',
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, fontSize: 14)),
          Text(SessionManager.email,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11)),
        ])),
        Container(padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Text(_roleBadge(role),
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(role.toUpperCase(), style: const TextStyle(
                  color: Colors.white, fontSize: 10,
                  fontWeight: FontWeight.w800)),
            ])),
      ]),
    );
  }

  Widget _utilisateurCard(Map e) {
    final role = e['role'] ?? 'employe';
    final color = _roleColor(role);
    final nom = e['nom'] ?? 'Utilisateur';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Row(children: [
        CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            radius: 20,
            child: Text(nom.substring(0, 1).toUpperCase(),
                style: TextStyle(color: color,
                    fontWeight: FontWeight.w900, fontSize: 16))),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nom, style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13,
              color: Color(0xFF1E293B))),
          Text(e['telephone'] ?? e['email'] ?? '-',
              style: const TextStyle(
                  color: Colors.grey, fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_roleBadge(role),
                    style: const TextStyle(fontSize: 10)),
                const SizedBox(width: 3),
                Text(role, style: TextStyle(
                    color: color, fontSize: 9,
                    fontWeight: FontWeight.w700)),
              ])),
          if (SessionManager.isAdmin) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _showChangerRole(e),
              child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: kBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: const Text('Changer rôle',
                      style: TextStyle(color: kBlue,
                          fontSize: 9, fontWeight: FontWeight.w600))),
            ),
          ],
        ]),
      ]),
    );
  }

  // ── PERMISSIONS ──
  Widget _buildPermissions() => Column(children: [
    // Sélecteur rôle
    Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: _roles.map((r) {
        final isSelected = _roleSelectionne == r['role'];
        final color = r['color'] as Color;
        return Expanded(child: GestureDetector(
          onTap: () => setState(
                  () => _roleSelectionne = r['role'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isSelected ? color : Colors.grey.shade200),
                boxShadow: isSelected ? [BoxShadow(
                    color: color.withOpacity(0.3), blurRadius: 8)] : []),
            child: Column(children: [
              Text(r['badge'] as String,
                  style: const TextStyle(fontSize: 16)),
              Text(r['label'] as String, style: TextStyle(
                  color: isSelected ? Colors.white
                      : const Color(0xFF1E293B),
                  fontSize: 8, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ));
      }).toList()),
    ),

    // Table permissions
    Expanded(child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        // En-tête
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: _roleColor(_roleSelectionne),
              borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Expanded(child: Text('Module', style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700,
                fontSize: 12))),
            _permHeader('👁️ Lire'),
            _permHeader('✏️ Écrire'),
            _permHeader('🗑️ Suppr.'),
          ]),
        ),
        const SizedBox(height: 8),

        // Lignes permissions
        if (!_permissionsLoaded)
          const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: kBlue),
          ))
        else
          ...(_permissions[_roleSelectionne] ?? []).map((p) {
            final module = p['module'] as String;
            final color = _roleColor(_roleSelectionne);
            final canEdit = SessionManager.isAdmin;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
              child: Row(children: [
                Icon(p['icon'] as IconData, color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(module, style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12))),
                _permToggle(p['lecture'] as bool, canEdit,
                    (v) => _togglePermission(_roleSelectionne, module, 'lecture', v)),
                _permToggle(p['ecriture'] as bool, canEdit,
                    (v) => _togglePermission(_roleSelectionne, module, 'ecriture', v)),
                _permToggle(p['suppression'] as bool, canEdit,
                    (v) => _togglePermission(_roleSelectionne, module, 'suppression', v)),
              ]),
            );
          }),
      ]),
    )),
  ]);

  // ── RÔLES ──
  Widget _buildRoles() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // Info
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: kBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBlue.withOpacity(0.2))),
        child: const Row(children: [
          Icon(Icons.info_rounded, color: kBlue, size: 16),
          SizedBox(width: 8),
          Expanded(child: Text(
              'Les rôles définissent les accès de chaque utilisateur dans l\'application',
              style: TextStyle(color: kBlue, fontSize: 12))),
        ]),
      ),
      const SizedBox(height: 16),

      ..._roles.map((r) => _roleCard(r)),
      const SizedBox(height: 16),

      // Mon rôle actuel
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
        child: Row(children: [
          const Icon(Icons.account_circle_rounded,
              color: kBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Mon rôle actuel', style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13)),
            Text(SessionManager.role, style: TextStyle(
                color: _roleColor(SessionManager.role),
                fontSize: 12, fontWeight: FontWeight.w600)),
          ])),
          Text(_roleBadge(SessionManager.role),
              style: const TextStyle(fontSize: 24)),
        ]),
      ),
    ],
  );

  Widget _roleCard(Map r) {
    final color = r['color'] as Color;
    final perms = _permissions[r['role'] as String] ?? [];
    final nbAcces = perms.where((p) =>
    p['lecture'] == true || p['ecriture'] == true).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(r['icon'] as IconData, color: color, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(r['badge'] as String,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(r['label'] as String, style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15,
                      color: color)),
                ]),
                Text(r['desc'] as String, style: const TextStyle(
                    color: Colors.grey, fontSize: 11)),
              ])),
              Container(padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('$nbAcces modules',
                      style: TextStyle(color: color, fontSize: 10,
                          fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 12),

            // Résumé permissions
            Wrap(spacing: 6, runSpacing: 4, children: perms
                .where((p) => p['lecture'] == true)
                .map((p) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(p['module'] as String,
                    style: TextStyle(color: color, fontSize: 9,
                        fontWeight: FontWeight.w600))))
                .toList()),
          ]),
    );
  }

  // ── MODAL ──
  void _showChangerRole(Map e) {
    String roleSelected = e['role'] ?? 'employe';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModal) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Changer le rôle de ${e['nom']}',
                  style: const TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 16),
              ..._roles.map((r) => GestureDetector(
                onTap: () => setModal(
                        () => roleSelected = r['role'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: roleSelected == r['role']
                          ? (r['color'] as Color).withOpacity(0.1)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: roleSelected == r['role']
                              ? r['color'] as Color
                              : Colors.grey.shade200,
                          width: roleSelected == r['role'] ? 2 : 1)),
                  child: Row(children: [
                    Text(r['badge'] as String,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(r['label'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
                    if (roleSelected == r['role'])
                      Icon(Icons.check_circle_rounded,
                          color: r['color'] as Color, size: 20),
                  ]),
                ),
              )),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, height: 48,
                  child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final ok = await ApiService.updateEmploye(
                          e['id'].toString(),
                          {'role': roleSelected, 'poste': roleSelected},
                        );
                        if (ok) {
                          setState(() => e['role'] = roleSelected);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('✅ Rôle mis à jour : $roleSelected'),
                                  backgroundColor: kGreen,
                                  behavior: SnackBarBehavior.floating));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('❌ Erreur lors de la mise à jour'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0),
                      child: const Text('Confirmer',
                          style: TextStyle(
                              fontWeight: FontWeight.w700)))),
            ]),
          )),
    );
  }

  // ── HELPERS ──
  Widget _permHeader(String label) => SizedBox(width: 56,
      child: Text(label, style: const TextStyle(
          color: Colors.white, fontSize: 9,
          fontWeight: FontWeight.w600),
          textAlign: TextAlign.center));

  Widget _permToggle(bool value, bool canEdit, ValueChanged<bool> onChanged) =>
      SizedBox(width: 56,
          child: canEdit
              ? Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: kGreen,
                  inactiveThumbColor: kRed,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )
              : Icon(value ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: value ? kGreen : kRed, size: 18));

  Widget _headerStat(String value, String label, Color color) =>
      Expanded(child: Column(children: [
        Text(value, style: TextStyle(
            color: color, fontSize: 16, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(
            color: Colors.white38, fontSize: 9)),
      ]));
}