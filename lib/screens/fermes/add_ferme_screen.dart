import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';

class AddFermeScreen extends StatefulWidget {
  final Map? ferme;
  const AddFermeScreen({super.key, this.ferme});
  @override
  State<AddFermeScreen> createState() => _AddFermeScreenState();
}

class _AddFermeScreenState extends State<AddFermeScreen> {
  final _nomCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _superficieCtrl = TextEditingController();
  bool _loading = false;
  String _error = '';

  bool get _isEdit => widget.ferme != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nomCtrl.text = widget.ferme!['nom'] ?? '';
      _locCtrl.text = widget.ferme!['localisation'] ?? '';
      _superficieCtrl.text = (widget.ferme!['superficie'] ?? 0).toString();
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _locCtrl.dispose(); _superficieCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nomCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Le nom est obligatoire'); return;
    }
    if (_locCtrl.text.trim().isEmpty) {
      setState(() => _error = 'La localisation est obligatoire'); return;
    }
    setState(() { _loading = true; _error = ''; });

    final data = {
      'nom': _nomCtrl.text.trim(),
      'localisation': _locCtrl.text.trim(),
      'superficie': double.tryParse(_superficieCtrl.text) ?? 0,
    };

    bool ok;
    if (_isEdit) {
      ok = await ApiService.updateFerme(widget.ferme!['id'].toString(), data);
    } else {
      ok = await ApiService.createFerme(data);
    }

    setState(() => _loading = false);

    if (ok) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? '✅ Ferme modifiée !' : '✅ Ferme créée !'),
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
        title: Text(_isEdit ? 'Modifier la ferme' : 'Nouvelle Ferme',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color: kBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: const Center(child: Text('🏡', style: TextStyle(fontSize: 40))),
          )),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Informations générales', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              const SizedBox(height: 16),
              _field(_nomCtrl, 'Nom de la ferme *', Icons.agriculture_rounded),
              const SizedBox(height: 12),
              _field(_locCtrl, 'Localisation / Ville *', Icons.location_on_rounded),
              const SizedBox(height: 12),
              _field(_superficieCtrl, 'Superficie (m²)', Icons.square_foot_rounded, isNumber: true),
            ]),
          ),
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
                      : Text(_isEdit ? 'Enregistrer les modifications' : 'Créer la ferme',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false}) =>
      TextField(controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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