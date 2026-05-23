import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';

class AddEmployeScreen extends StatefulWidget {
  final Map? employe;
  const AddEmployeScreen({super.key, this.employe});
  @override
  State<AddEmployeScreen> createState() => _AddEmployeScreenState();
}

class _AddEmployeScreenState extends State<AddEmployeScreen> {
  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _salaireCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  String _posteSelected = 'employe';
  bool _loading = false;
  String _error = '';

  bool get _isEdit => widget.employe != null;

  final List<Map<String, dynamic>> _postes = [
    {'value': 'employe', 'label': 'Employé', 'icon': Icons.person_rounded, 'color': kBlue},
    {'value': 'manager', 'label': 'Manager', 'icon': Icons.manage_accounts_rounded, 'color': kPurple},
    {'value': 'veterinaire', 'label': 'Vétérinaire', 'icon': Icons.medical_services_rounded, 'color': kGreen},
    {'value': 'chauffeur', 'label': 'Chauffeur', 'icon': Icons.drive_eta_rounded, 'color': kOrange},
    {'value': 'gardien', 'label': 'Gardien', 'icon': Icons.security_rounded, 'color': Colors.brown},
    {'value': 'comptable', 'label': 'Comptable', 'icon': Icons.calculate_rounded, 'color': Colors.teal},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nomCtrl.text = widget.employe!['nom'] ?? '';
      _telCtrl.text = widget.employe!['telephone'] ?? '';
      _salaireCtrl.text = (widget.employe!['salaire'] ?? 0).toString();
      _emailCtrl.text = widget.employe!['email'] ?? '';
      _adresseCtrl.text = widget.employe!['adresse'] ?? '';
      _posteSelected = widget.employe!['poste'] ?? 'employe';
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _telCtrl.dispose(); _salaireCtrl.dispose();
    _emailCtrl.dispose(); _adresseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nomCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Le nom est obligatoire'); return;
    }
    setState(() { _loading = true; _error = ''; });

    final data = {
      'nom': _nomCtrl.text.trim(),
      'telephone': _telCtrl.text.trim(),
      'salaire': double.tryParse(_salaireCtrl.text) ?? 0,
      'email': _emailCtrl.text.trim(),
      'adresse': _adresseCtrl.text.trim(),
      'poste': _posteSelected,
      'role': 'employe',
      'ferme_id': '11111111-1111-1111-1111-111111111111',
    };

    bool ok;
    if (_isEdit) {
      ok = await ApiService.updateEmploye(widget.employe!['id'].toString(), data);
    } else {
      ok = await ApiService.createEmploye(data);
    }

    setState(() => _loading = false);

    if (ok) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? '✅ Employé modifié !' : '✅ Employé ajouté !'),
          backgroundColor: kGreen, behavior: SnackBarBehavior.floating));
    } else {
      setState(() => _error = 'Erreur lors de l\'enregistrement');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white, elevation: 0,
        title: Text(_isEdit ? 'Modifier l\'employé' : 'Nouvel Employé',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar
          Center(child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kBlue, kBlueLight]),
                shape: BoxShape.circle),
            child: Center(child: Text(
                _nomCtrl.text.isNotEmpty
                    ? _nomCtrl.text.substring(0, 1).toUpperCase() : '👤',
                style: const TextStyle(color: Colors.white,
                    fontSize: 32, fontWeight: FontWeight.w900))),
          )),
          const SizedBox(height: 24),

          // Infos personnelles
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle('👤 Informations Personnelles'),
            _field(_nomCtrl, 'Nom complet *', Icons.person_rounded),
            const SizedBox(height: 12),
            _field(_telCtrl, 'Téléphone', Icons.phone_rounded, isPhone: true),
            const SizedBox(height: 12),
            _field(_emailCtrl, 'Email', Icons.email_rounded, isEmail: true),
            const SizedBox(height: 12),
            _field(_adresseCtrl, 'Adresse', Icons.location_on_rounded),
          ])),
          const SizedBox(height: 12),

          // Poste
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle('💼 Poste & Rémunération'),
            const SizedBox(height: 12),
            // Sélecteur poste visuel
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: _postes.map((p) {
                final isSelected = _posteSelected == p['value'];
                final color = p['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _posteSelected = p['value']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.15) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isSelected ? color : Colors.grey.shade200,
                            width: isSelected ? 2 : 1)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(p['icon'] as IconData,
                          color: isSelected ? color : Colors.grey, size: 14),
                      const SizedBox(width: 4),
                      Text(p['label'] as String, style: TextStyle(
                          color: isSelected ? color : Colors.grey,
                          fontSize: 10, fontWeight: isSelected
                          ? FontWeight.w700 : FontWeight.w400)),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            _field(_salaireCtrl, 'Salaire mensuel (FCFA)',
                Icons.attach_money_rounded, isNumber: true),
          ])),

          if (_error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.red.shade50, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200)),
              child: Row(children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                const SizedBox(width: 8),
                Text(_error, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ]),
            ),
          ],
          const SizedBox(height: 20),

          SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(_isEdit ? 'Enregistrer' : 'Ajouter l\'employé',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
        ]),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: child);

  Widget _sectionTitle(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(t, style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))));

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false, bool isPhone = false, bool isEmail = false}) =>
      TextField(controller: ctrl,
          keyboardType: isNumber ? TextInputType.number
              : isPhone ? TextInputType.phone
              : isEmail ? TextInputType.emailAddress
              : TextInputType.text,
          decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: kBlueLight, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kBlue, width: 2)),
              filled: true, fillColor: const Color(0xFFF8FAFC)));
}