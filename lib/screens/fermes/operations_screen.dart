import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';

class OperationsScreen extends StatefulWidget {
  final Map ferme;
  final List cycles;
  const OperationsScreen({super.key, required this.ferme, required this.cycles});
  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  String? _selectedCycleId;
  final _tempCtrl = TextEditingController();
  final _humCtrl = TextEditingController();
  final _mortCtrl = TextEditingController();
  final _prodCtrl = TextEditingController();
  bool _loading = false;
  String _error = '';
  DateTime _dateReleve = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.cycles.isNotEmpty) {
      _selectedCycleId = widget.cycles.first['id']?.toString();
    }
  }

  @override
  void dispose() {
    _tempCtrl.dispose(); _humCtrl.dispose();
    _mortCtrl.dispose(); _prodCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
        context: context,
        initialDate: _dateReleve,
        firstDate: DateTime(2020),
        lastDate: DateTime.now());
    if (picked != null) setState(() => _dateReleve = picked);
  }

  Future<void> _submit() async {
    if (_selectedCycleId == null) {
      setState(() => _error = 'Sélectionnez un cycle'); return;
    }
    if (_tempCtrl.text.isEmpty) {
      setState(() => _error = 'Température obligatoire'); return;
    }
    setState(() { _loading = true; _error = ''; });

    final ok = await ApiService.createDonnee({
      'cycle_id': _selectedCycleId,
      'date_releve': _dateReleve.toIso8601String().split('T')[0],
      'temperature': double.tryParse(_tempCtrl.text) ?? 0,
      'humidite': double.tryParse(_humCtrl.text) ?? 0,
      'mortalite': int.tryParse(_mortCtrl.text) ?? 0,
      'production': int.tryParse(_prodCtrl.text) ?? 0,
    });

    setState(() => _loading = false);

    if (ok) {
      _tempCtrl.clear(); _humCtrl.clear();
      _mortCtrl.clear(); _prodCtrl.clear();
      setState(() => _dateReleve = DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Données enregistrées !'),
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
        title: const Text('Saisie Journalière',
            style: TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(widget.ferme['nom'] ?? '',
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Cycle
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🔄 Cycle concerné', style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                value: _selectedCycleId,
                decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.loop_rounded, color: kBlueLight, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: const Color(0xFFF8FAFC)),
                items: widget.cycles.map((c) => DropdownMenuItem<String>(
                    value: c['id']?.toString(),
                    child: Text(c['nom']?.toString() ?? ''))).toList(),
                onChanged: (v) => setState(() => _selectedCycleId = v)),
          ])),
          const SizedBox(height: 12),

          // Date
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📅 Date du relevé', style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300)),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded, color: kBlueLight, size: 18),
                  const SizedBox(width: 10),
                  Text('${_dateReleve.day}/${_dateReleve.month}/${_dateReleve.year}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
                ]),
              ),
            ),
          ])),
          const SizedBox(height: 12),

          // Données
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📊 Données du jour', style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _field(_tempCtrl, 'Température (°C) *', '🌡️', isDecimal: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_humCtrl, 'Humidité (%)', '💧', isDecimal: true)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_mortCtrl, 'Mortalité', '💀')),
              const SizedBox(width: 12),
              Expanded(child: _field(_prodCtrl, 'Production', '📦')),
            ]),
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
                      : const Text('Enregistrer les données',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
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

  Widget _field(TextEditingController ctrl, String label, String emoji,
      {bool isDecimal = false}) =>
      TextField(
          controller: ctrl,
          keyboardType: isDecimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          decoration: InputDecoration(
              labelText: label,
              prefixText: '$emoji ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kBlue, width: 2)),
              filled: true, fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)));
}