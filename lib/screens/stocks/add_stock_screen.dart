import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';

class AddStockScreen extends StatefulWidget {
  final Map? stock;
  const AddStockScreen({super.key, this.stock});
  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _produitCtrl = TextEditingController();
  final _quantiteCtrl = TextEditingController();
  final _seuilCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _uniteSelected = 'kg';
  String _categorieSelected = 'aliment';
  bool _loading = false;
  String _error = '';

  bool get _isEdit => widget.stock != null;

  final List<Map<String, dynamic>> _unites = [
    {'value': 'kg', 'label': 'Kilogramme (kg)'},
    {'value': 'sac', 'label': 'Sac'},
    {'value': 'litre', 'label': 'Litre (L)'},
    {'value': 'unite', 'label': 'Unité'},
    {'value': 'tonne', 'label': 'Tonne'},
    {'value': 'boite', 'label': 'Boîte'},
  ];

  final List<Map<String, dynamic>> _categories = [
    {'value': 'aliment', 'label': 'Aliment', 'icon': Icons.grass_rounded, 'color': kGreen},
    {'value': 'medicament', 'label': 'Médicament', 'icon': Icons.medical_services_rounded, 'color': kRed},
    {'value': 'vaccin', 'label': 'Vaccin', 'icon': Icons.vaccines_rounded, 'color': kBlue},
    {'value': 'equipement', 'label': 'Équipement', 'icon': Icons.handyman_rounded, 'color': kOrange},
    {'value': 'desinfectant', 'label': 'Désinfectant', 'icon': Icons.sanitizer_rounded, 'color': kPurple},
    {'value': 'autre', 'label': 'Autre', 'icon': Icons.category_rounded, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _produitCtrl.text = widget.stock!['produit'] ?? '';
      _quantiteCtrl.text = (widget.stock!['quantite'] ?? 0).toString();
      _seuilCtrl.text = (widget.stock!['seuil_alerte'] ?? 0).toString();
      _prixCtrl.text = (widget.stock!['prix_unitaire'] ?? 0).toString();
      _uniteSelected = widget.stock!['unite'] ?? 'kg';
      _categorieSelected = widget.stock!['categorie'] ?? 'aliment';
    }
  }

  @override
  void dispose() {
    _produitCtrl.dispose(); _quantiteCtrl.dispose();
    _seuilCtrl.dispose(); _prixCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_produitCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Le nom du produit est obligatoire'); return;
    }
    setState(() { _loading = true; _error = ''; });

    final data = {
      'produit': _produitCtrl.text.trim(),
      'quantite': double.tryParse(_quantiteCtrl.text) ?? 0,
      'seuil_alerte': double.tryParse(_seuilCtrl.text) ?? 0,
      'prix_unitaire': double.tryParse(_prixCtrl.text) ?? 0,
      'unite': _uniteSelected,
      'categorie': _categorieSelected,
      'description': _descCtrl.text.trim(),
      'ferme_id': '11111111-1111-1111-1111-111111111111',
    };

    bool ok;
    if (_isEdit) {
      ok = await ApiService.updateStock(widget.stock!['id'].toString(), data);
    } else {
      ok = await ApiService.createStock(data);
    }

    setState(() => _loading = false);

    if (ok) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? '✅ Stock modifié !' : '✅ Stock ajouté !'),
          backgroundColor: kGreen, behavior: SnackBarBehavior.floating));
    } else {
      setState(() => _error = 'Erreur lors de l\'enregistrement');
    }
  }

  @override
  Widget build(BuildContext context) {
    final catSelected = _categories.firstWhere(
            (c) => c['value'] == _categorieSelected,
        orElse: () => _categories.last);
    final catColor = catSelected['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white, elevation: 0,
        title: Text(_isEdit ? 'Modifier le stock' : 'Nouveau Stock',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Catégorie
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📦 Catégorie', style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: _categories.map((c) {
                final isSelected = _categorieSelected == c['value'];
                final color = c['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _categorieSelected = c['value']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.15) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isSelected ? color : Colors.grey.shade200,
                            width: isSelected ? 2 : 1)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(c['icon'] as IconData,
                          color: isSelected ? color : Colors.grey, size: 16),
                      const SizedBox(height: 2),
                      Text(c['label'] as String, style: TextStyle(
                          color: isSelected ? color : Colors.grey,
                          fontSize: 9, fontWeight: isSelected
                          ? FontWeight.w700 : FontWeight.w400)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ])),
          const SizedBox(height: 12),

          // Informations produit
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📋 Informations', style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            _field(_produitCtrl, 'Nom du produit *', Icons.inventory_rounded),
            const SizedBox(height: 12),
            _field(_descCtrl, 'Description', Icons.notes_rounded),
            const SizedBox(height: 12),
            // Unité
            DropdownButtonFormField<String>(
                value: _uniteSelected,
                decoration: InputDecoration(
                    labelText: 'Unité de mesure',
                    prefixIcon: const Icon(Icons.scale_rounded, color: kBlueLight, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: const Color(0xFFF8FAFC)),
                items: _unites.map((u) => DropdownMenuItem<String>(
                    value: u['value'],
                    child: Text(u['label'] as String))).toList(),
                onChanged: (v) => setState(() => _uniteSelected = v!)),
          ])),
          const SizedBox(height: 12),

          // Quantités
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📊 Quantités', style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_quantiteCtrl, 'Quantité actuelle',
                  Icons.numbers_rounded, isNumber: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_seuilCtrl, 'Seuil d\'alerte',
                  Icons.warning_rounded, isNumber: true)),
            ]),
            const SizedBox(height: 12),
            _field(_prixCtrl, 'Prix unitaire (FCFA)',
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
              child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(_isEdit ? Icons.save_rounded : Icons.add_rounded),
                  label: Text(_isEdit ? 'Enregistrer' : 'Ajouter au stock',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: catColor, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0))),
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

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false}) =>
      TextField(controller: ctrl,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
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