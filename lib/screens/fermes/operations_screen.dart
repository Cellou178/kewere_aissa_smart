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
  bool _loading = false;
  String _error = '';
  DateTime _dateReleve = DateTime.now();

  // Effectif
  final _mortCtrl = TextEditingController();
  final _vendusCtrl = TextEditingController();
  final _prodCtrl = TextEditingController();

  // Pesées 5 groupes
  final _g1Ctrl = TextEditingController();
  final _g2Ctrl = TextEditingController();
  final _g3Ctrl = TextEditingController();
  final _g4Ctrl = TextEditingController();
  final _g5Ctrl = TextEditingController();
  final _poidsMoyenCtrl = TextEditingController();
  final _homogeneiteCtrl = TextEditingController();
  final _poidsStdCtrl = TextEditingController();
  final _devPlusCtrl = TextEditingController();
  final _devMoinsCtrl = TextEditingController();

  // Ambiance
  final _tempMatinCtrl = TextEditingController();
  final _tempSoirCtrl = TextEditingController();
  final _humValCtrl = TextEditingController();
  String? _tempStandard;
  String? _humStandard;

  // Alimentation
  final _alimentConsoCtrl = TextEditingController();
  final _alimentRestCtrl = TextEditingController();
  final _sacsRestCtrl = TextEditingController();

  // Indicateurs
  final _icCtrl = TextEditingController();
  final _tauxMortCtrl = TextEditingController();
  final _commentaireCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.cycles.isNotEmpty) {
      _selectedCycleId = widget.cycles.first['id']?.toString();
    }
  }

  @override
  void dispose() {
    _mortCtrl.dispose(); _vendusCtrl.dispose(); _prodCtrl.dispose();
    _g1Ctrl.dispose(); _g2Ctrl.dispose(); _g3Ctrl.dispose();
    _g4Ctrl.dispose(); _g5Ctrl.dispose();
    _poidsMoyenCtrl.dispose(); _homogeneiteCtrl.dispose();
    _poidsStdCtrl.dispose(); _devPlusCtrl.dispose(); _devMoinsCtrl.dispose();
    _tempMatinCtrl.dispose(); _tempSoirCtrl.dispose(); _humValCtrl.dispose();
    _alimentConsoCtrl.dispose(); _alimentRestCtrl.dispose(); _sacsRestCtrl.dispose();
    _icCtrl.dispose(); _tauxMortCtrl.dispose();
    _commentaireCtrl.dispose(); _actionCtrl.dispose();
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
    setState(() { _loading = true; _error = ''; });

    final ok = await ApiService.createDonnee({
      'cycle_id': _selectedCycleId,
      'date_releve': _dateReleve.toIso8601String().split('T')[0],
      'action': _actionCtrl.text.isEmpty ? null : _actionCtrl.text,

      // Effectif
      'mortalite': int.tryParse(_mortCtrl.text) ?? 0,
      'nombre_sujets_vendus': int.tryParse(_vendusCtrl.text) ?? 0,
      'production': double.tryParse(_prodCtrl.text) ?? 0,

      // Pesées
      'poids_g1': double.tryParse(_g1Ctrl.text),
      'poids_g2': double.tryParse(_g2Ctrl.text),
      'poids_g3': double.tryParse(_g3Ctrl.text),
      'poids_g4': double.tryParse(_g4Ctrl.text),
      'poids_g5': double.tryParse(_g5Ctrl.text),
      'poids_moyen_global': double.tryParse(_poidsMoyenCtrl.text),
      'homogeneite': double.tryParse(_homogeneiteCtrl.text),
      'poids_standard': double.tryParse(_poidsStdCtrl.text),
      'deviation_plus': double.tryParse(_devPlusCtrl.text),
      'deviation_moins': double.tryParse(_devMoinsCtrl.text),

      // Ambiance
      'temperature_matin': double.tryParse(_tempMatinCtrl.text),
      'temperature_soir': double.tryParse(_tempSoirCtrl.text),
      'temperature_standard': _tempStandard,
      'humidite_valeur': double.tryParse(_humValCtrl.text),
      'humidite_standard': _humStandard,

      // Alimentation
      'aliment_consomme': double.tryParse(_alimentConsoCtrl.text),
      'aliment_restant': double.tryParse(_alimentRestCtrl.text),
      'sacs_restants': double.tryParse(_sacsRestCtrl.text),

      // Indicateurs
      'ic_inis': double.tryParse(_icCtrl.text),
      'taux_mortalite': double.tryParse(_tauxMortCtrl.text),
      'commentaire': _commentaireCtrl.text.isEmpty ? null : _commentaireCtrl.text,
    });

    setState(() => _loading = false);

    if (ok) {
      _clearAll();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Données enregistrées !'),
          backgroundColor: kGreen, behavior: SnackBarBehavior.floating));
    } else {
      setState(() => _error = 'Erreur lors de l\'enregistrement');
    }
  }

  void _clearAll() {
    _mortCtrl.clear(); _vendusCtrl.clear(); _prodCtrl.clear();
    _g1Ctrl.clear(); _g2Ctrl.clear(); _g3Ctrl.clear();
    _g4Ctrl.clear(); _g5Ctrl.clear();
    _poidsMoyenCtrl.clear(); _homogeneiteCtrl.clear();
    _poidsStdCtrl.clear(); _devPlusCtrl.clear(); _devMoinsCtrl.clear();
    _tempMatinCtrl.clear(); _tempSoirCtrl.clear(); _humValCtrl.clear();
    _alimentConsoCtrl.clear(); _alimentRestCtrl.clear(); _sacsRestCtrl.clear();
    _icCtrl.clear(); _tauxMortCtrl.clear();
    _commentaireCtrl.clear(); _actionCtrl.clear();
    setState(() {
      _dateReleve = DateTime.now();
      _tempStandard = null;
      _humStandard = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white, elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Saisie Journalière',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(widget.ferme['nom'] ?? '',
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Cycle
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle('🔄 Cycle concerné'),
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
            _sectionTitle('📅 Date du relevé'),
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

          // Action
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle('📝 Action du jour'),
            const SizedBox(height: 12),
            _field(_actionCtrl, 'Action (optionnel)', '📝'),
          ])),
          const SizedBox(height: 12),

          // Effectif
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle('🐔 Effectif'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_mortCtrl, 'Mortalité', '💀')),
              const SizedBox(width: 12),
              Expanded(child: _field(_vendusCtrl, 'Sujets vendus', '🛒')),
            ]),
            const SizedBox(height: 12),
            _field(_prodCtrl, 'Production', '📦', isDecimal: true),
          ])),
          const SizedBox(height: 12),

          // Pesées
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle('⚖️ Pesées (5 groupes de 20)'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_g1Ctrl, 'Groupe 1 (g)', 'G1', isDecimal: true)),
              const SizedBox(width: 8),
              Expanded(child: _field(_g2Ctrl, 'Groupe 2 (g)', 'G2', isDecimal: true)),
              const SizedBox(width: 8),
              Expanded(child: _field(_g3Ctrl, 'Groupe 3 (g)', 'G3', isDecimal: true)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_g4Ctrl, 'Groupe 4 (g)', 'G4', isDecimal: true)),
              const SizedBox(width: 8),
              Expanded(child: _field(_g5Ctrl, 'Groupe 5 (g)', 'G5', isDecimal: true)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_poidsMoyenCtrl, 'Poids moyen (g)', '⚖️', isDecimal: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_homogeneiteCtrl, 'Homogénéité', '📊', isDecimal: true)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_poidsStdCtrl, 'Poids standard', '📏', isDecimal: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_devPlusCtrl, 'Déviation +', '➕', isDecimal: true)),
            ]),
            const SizedBox(height: 12),
            _field(_devMoinsCtrl, 'Déviation -', '➖', isDecimal: true),
          ])),
          const SizedBox(height: 12),

          // Ambiance
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle('🌡️ Ambiance'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_tempMatinCtrl, 'Temp. matin (°C)', '🌅', isDecimal: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_tempSoirCtrl, 'Temp. soir (°C)', '🌆', isDecimal: true)),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                value: _tempStandard,
                decoration: InputDecoration(
                    labelText: 'Standard température',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: const Color(0xFFF8FAFC)),
                items: ['Normal', 'Élevé', 'Bas'].map((s) => DropdownMenuItem(
                    value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _tempStandard = v)),
            const SizedBox(height: 12),
            _field(_humValCtrl, 'Humidité (%)', '💧', isDecimal: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                value: _humStandard,
                decoration: InputDecoration(
                    labelText: 'Standard humidité',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: const Color(0xFFF8FAFC)),
                items: ['Normal', 'Élevé', 'Bas'].map((s) => DropdownMenuItem(
                    value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _humStandard = v)),
          ])),
          const SizedBox(height: 12),

          // Alimentation
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle('🌾 Alimentation'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_alimentConsoCtrl, 'Aliment consommé (kg)', '🍽️', isDecimal: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_alimentRestCtrl, 'Aliment restant (kg)', '📦', isDecimal: true)),
            ]),
            const SizedBox(height: 12),
            _field(_sacsRestCtrl, 'Sacs restants', '🎒', isDecimal: true),
          ])),
          const SizedBox(height: 12),

          // Indicateurs
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitle('📈 Indicateurs'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_icCtrl, 'IC INIS', '📊', isDecimal: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_tauxMortCtrl, 'Taux mortalité (%)', '💀', isDecimal: true)),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _commentaireCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                  labelText: 'Commentaire',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kBlue, width: 2)),
                  filled: true, fillColor: const Color(0xFFF8FAFC)),
            ),
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
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B)));

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