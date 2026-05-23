import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../../services/api_service.dart';
import 'add_employe_screen.dart';

class EmployeDetailScreen extends StatefulWidget {
  final Map employe;
  const EmployeDetailScreen({super.key, required this.employe});
  @override
  State<EmployeDetailScreen> createState() => _EmployeDetailScreenState();
}

class _EmployeDetailScreenState extends State<EmployeDetailScreen> {
  bool _loading = false;

  Color get _posteColor {
    switch (widget.employe['poste'] ?? '') {
      case 'manager': return kPurple;
      case 'veterinaire': return kGreen;
      case 'chauffeur': return kOrange;
      case 'gardien': return Colors.brown;
      case 'comptable': return Colors.teal;
      default: return kBlue;
    }
  }

  IconData get _posteIcon {
    switch (widget.employe['poste'] ?? '') {
      case 'manager': return Icons.manage_accounts_rounded;
      case 'veterinaire': return Icons.medical_services_rounded;
      case 'chauffeur': return Icons.drive_eta_rounded;
      case 'gardien': return Icons.security_rounded;
      case 'comptable': return Icons.calculate_rounded;
      default: return Icons.person_rounded;
    }
  }

  String _formatSalaire(double v) =>
      '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA';

  Future<void> _supprimer() async {
    final confirm = await showDialog<bool>(context: context,
        builder: (_) => AlertDialog(
          title: const Text('Supprimer l\'employé ?'),
          content: Text('Voulez-vous supprimer ${widget.employe['nom']} ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler')),
            TextButton(onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
          ],
        ));
    if (confirm == true) {
      setState(() => _loading = true);
      await ApiService.deleteEmploye(widget.employe['id'].toString());
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.employe;
    final salaire = ((e['salaire'] ?? 0) as num).toDouble();
    final nom = e['nom'] ?? 'Employé';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(slivers: [
        // AppBar
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          actions: [
            if (SessionManager.isProprietaire || SessionManager.isAdmin) ...[
              IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () async {
                    final result = await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => AddEmployeScreen(employe: e)));
                    if (result == true) Navigator.pop(context, true);
                  }),
              IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                  onPressed: _supprimer),
            ],
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 40),
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_posteColor, _posteColor.withOpacity(0.7)]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: _posteColor.withOpacity(0.4),
                          blurRadius: 16, offset: const Offset(0, 6))]),
                  child: Center(child: Text(nom.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white,
                          fontSize: 28, fontWeight: FontWeight.w900))),
                ),
                const SizedBox(height: 10),
                Text(nom, style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: _posteColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_posteIcon, color: _posteColor, size: 13),
                    const SizedBox(width: 5),
                    Text(e['poste'] ?? 'Employé', style: TextStyle(
                        color: _posteColor, fontWeight: FontWeight.w700, fontSize: 12)),
                  ]),
                ),
              ])),
            ),
          ),
        ),

        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Salaire card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [kGreen.withOpacity(0.8), kGreen],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: kGreen.withOpacity(0.3),
                      blurRadius: 12, offset: const Offset(0, 4))]),
              child: Row(children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 36),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Salaire Mensuel', style: TextStyle(
                      color: Colors.white70, fontSize: 12)),
                  Text(_formatSalaire(salaire), style: const TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                ]),
              ]),
            ),
            const SizedBox(height: 16),

            // Infos contact
            _section('📞 Contact', [
              _infoRow(Icons.phone_rounded, 'Téléphone', e['telephone'] ?? '-', kBlue),
              _infoRow(Icons.email_rounded, 'Email', e['email'] ?? '-', kPurple),
              _infoRow(Icons.location_on_rounded, 'Adresse', e['adresse'] ?? '-', kOrange),
            ]),
            const SizedBox(height: 12),

            // Infos emploi
            _section('💼 Emploi', [
              _infoRow(Icons.work_rounded, 'Poste', e['poste'] ?? '-', _posteColor),
              _infoRow(Icons.attach_money_rounded, 'Salaire', _formatSalaire(salaire), kGreen),
              _infoRow(Icons.business_rounded, 'Ferme', e['ferme_id'] ?? '-', kBlue),
            ]),
            const SizedBox(height: 20),

            // Actions
            if (SessionManager.isProprietaire || SessionManager.isAdmin)
              SizedBox(width: double.infinity,
                  child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => AddEmployeScreen(employe: e)));
                        if (result == true) Navigator.pop(context, true);
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Modifier les informations',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kBlue, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0))),
          ]),
        )),
      ]),
    );
  }

  Widget _section(String title, List<Widget> items) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B))),
        const SizedBox(height: 10),
        ...items,
      ]));

  Widget _infoRow(IconData icon, String label, String value, Color color) =>
      Padding(padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 15)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              Text(value, style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
            ]),
          ]));
}