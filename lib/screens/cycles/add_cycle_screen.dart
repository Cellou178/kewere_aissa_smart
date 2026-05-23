import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../../services/api_service.dart';

class AddCycleScreen extends StatefulWidget {
  final Map? cycle;
  const AddCycleScreen({super.key, this.cycle});
  @override
  State<AddCycleScreen> createState() => _AddCycleScreenState();
}

class _AddCycleScreenState extends State<AddCycleScreen> {
  final _nomCtrl = TextEditingController();
  final _sujetsCtrl = TextEditingController();
  final _batCtrl = TextEditingController();
  final _soucheCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  String _error = '';
  String _typeCycle = 'chair';
  String _statut = 'actif';
  DateTime _dateDebut = DateTime.now();
  DateTime? _dateFin;
  List _fermes = [];
  String? _fermeId;
  int _currentStep = 0;

  bool get _isEdit => widget.cycle != null;

  final List<Map<String, dynamic>> _typesCycle = [
    {'value': 'chair', 'label': 'Poulet de chair',
      'icon': Icons.set_meal_rounded, 'color': kOrange,
      'desc': 'Production de viande'},
    {'value': 'ponte', 'label': 'Poule pondeuse',
      'icon': Icons.egg_rounded, 'color': kYellow,
      'desc': 'Production d\'œufs'},
    {'value': 'reproducteur', 'label': 'Reproducteur',
      'icon': Icons.pets_rounded, 'color': kPurple,
      'desc': 'Élevage reproducteur'},
  ];

  final List<Map<String, dynamic>> _souches = [
    {'label': 'Cobb 500', 'icon': '🐔'},
    {'label': 'Ross 308', 'icon': '🐓'},
    {'label': 'Hubbard', 'icon': '🐔'},
    {'label': 'Arbor Acres', 'icon': '🐓'},
    {'label': 'Autre', 'icon': '🐣'},
  ];

  @override
  void initState() {
    super.initState();
    _fermeId = SessionManager.fermeId.isNotEmpty
        ? SessionManager.fermeId : null;
    _loadFermes();
    if (_isEdit) {
      final c = widget.cycle!;
      _nomCtrl.text = c['nom'] ?? '';
      _sujetsCtrl.text = (c['nombre_sujets'] ?? 0).toString();
      _batCtrl.text = c['batiment'] ?? '';
      _soucheCtrl.text = c['souche'] ?? '';
      _notesCtrl.text = c['notes'] ?? '';
      _typeCycle = c['type_cycle'] ?? 'chair';
      _statut = c['statut'] ?? 'actif';
      _fermeId = c['ferme_id']?.toString();
      try { _dateDebut = DateTime.parse(c['date_debut'] ?? ''); } catch (_) {}
    } else {
      _nomCtrl.text = 'Lot${DateTime.now().month}-${DateTime.now().year}';
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _sujetsCtrl.dispose();
    _batCtrl.dispose(); _soucheCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFermes() async {
    final f = await ApiService.getFermes();
    setState(() {
      _fermes = f is List ? f : [];
      if (_fermes.isNotEmpty && _fermeId == null) {
        _fermeId = _fermes.first['id']?.toString();
      }
    });
  }

  Future<void> _selectDate(bool isDebut) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: isDebut ? _dateDebut : (_dateFin ?? DateTime.now()),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030));
    if (picked != null) {
      setState(() => isDebut ? _dateDebut = picked : _dateFin = picked);
    }
  }

  bool _isStep1Valid() {
    if (_nomCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Le nom est obligatoire'); return false;
    }
    if (_sujetsCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Le nombre de sujets est obligatoire'); return false;
    }
    return true;
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = ''; });
    final fermeId = _fermeId ?? SessionManager.fermeId.isNotEmpty
        ? _fermeId ?? SessionManager.fermeId
        : '11111111-1111-1111-1111-111111111111';

    final data = {
      'ferme_id': fermeId,
      'nom': _nomCtrl.text.trim(),
      'date_debut': _dateDebut.toIso8601String().split('T')[0],
      'date_fin': _dateFin?.toIso8601String().split('T')[0],
      'nombre_sujets': int.tryParse(_sujetsCtrl.text) ?? 0,
      'type_cycle': _typeCycle,
      'batiment': _batCtrl.text.trim(),
      'souche': _soucheCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
      'statut': _statut,
    };

    bool ok;
    if (_isEdit) {
      ok = await ApiService.updateCycle(widget.cycle!['id'].toString(), data);
    } else {
      ok = await ApiService.createCycle(data);
    }

    setState(() => _loading = false);
    if (ok) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? '✅ Cycle modifié !' : '✅ Cycle créé !'),
          backgroundColor: kGreen, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    } else {
      setState(() => _error = 'Erreur lors de l\'enregistrement');
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
              colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(children: [
            Row(children: [
              IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => _currentStep > 0
                      ? setState(() { _currentStep--; _error = ''; })
                      : Navigator.pop(context)),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_isEdit ? 'Modifier le cycle' : 'Nouveau Cycle',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 18, fontWeight: FontWeight.w900)),
                Text('Étape ${_currentStep + 1} sur 3',
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ])),
              Container(width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: Text('🐔', style: TextStyle(fontSize: 22)))),
            ]),
            const SizedBox(height: 12),
            // Progress
            Row(children: List.generate(3, (i) => Expanded(
              child: Container(
                height: 4, margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                    color: i <= _currentStep
                        ? kBlueLight : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ))),
          ]),
        ),

        // Contenu
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(
                  key: ValueKey(_currentStep),
                  child: _currentStep == 0 ? _buildStep1()
                      : _currentStep == 1 ? _buildStep2()
                      : _buildStep3()),
            ),
            const SizedBox(height: 16),

            // Erreur
            if (_error.isNotEmpty) Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.red.shade50, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200)),
              child: Row(children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_error, style: TextStyle(
                    color: Colors.red.shade700, fontSize: 12))),
              ]),
            ),
            if (_error.isNotEmpty) const SizedBox(height: 12),

            // Bouton
            SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                    onPressed: _loading ? null : () {
                      setState(() => _error = '');
                      if (_currentStep == 0 && !_isStep1Valid()) return;
                      if (_currentStep < 2) {
                        setState(() => _currentStep++);
                      } else {
                        _submit();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _currentStep < 2 ? kBlue : kGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                        : Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_currentStep < 2
                              ? Icons.arrow_forward_rounded
                              : (_isEdit ? Icons.save_rounded
                              : Icons.check_circle_rounded),
                              size: 18),
                          const SizedBox(width: 8),
                          Text(_currentStep < 2 ? 'Continuer'
                              : _isEdit ? 'Enregistrer' : 'Créer le cycle',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                        ]))),
          ]),
        )),
      ]),
    );
  }

  // ── ÉTAPE 1 — Infos de base ──
  Widget _buildStep1() => _card(
    title: '📋 Informations de base',
    child: Column(children: [
      _field(_nomCtrl, 'Nom du cycle *', Icons.label_rounded),
      const SizedBox(height: 12),
      _field(_sujetsCtrl, 'Nombre de sujets *',
          Icons.pets_rounded, isNumber: true),
      const SizedBox(height: 12),
      _field(_batCtrl, 'Bâtiment', Icons.home_work_rounded),
      const SizedBox(height: 12),

      // Souche rapide
      const Align(alignment: Alignment.centerLeft,
          child: Text('Souche', style: TextStyle(
              color: Colors.grey, fontSize: 12))),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 8, children: _souches.map((s) {
        final isSelected = _soucheCtrl.text == s['label'];
        return GestureDetector(
          onTap: () => setState(() => _soucheCtrl.text = s['label']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: isSelected ? kBlue : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSelected ? kBlue : Colors.grey.shade300)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(s['icon']!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(s['label']!, style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 11, fontWeight: isSelected
                  ? FontWeight.w700 : FontWeight.w400)),
            ]),
          ),
        );
      }).toList()),
      const SizedBox(height: 12),

      // Ou saisie manuelle
      _field(_soucheCtrl, 'Ou saisir la souche manuellement',
          Icons.science_rounded),
    ]),
  );

  // ── ÉTAPE 2 — Type & Dates ──
  Widget _buildStep2() => Column(children: [
    _card(
      title: '🐔 Type de cycle',
      child: Column(children: _typesCycle.map((t) {
        final isSelected = _typeCycle == t['value'];
        final color = t['color'] as Color;
        return GestureDetector(
          onTap: () => setState(() => _typeCycle = t['value']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.08)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isSelected ? color : Colors.grey.shade200,
                    width: isSelected ? 2 : 1)),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: color.withOpacity(isSelected ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(t['icon'] as IconData, color: color, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t['label'] as String, style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13,
                    color: isSelected ? color : const Color(0xFF1E293B))),
                Text(t['desc'] as String, style: TextStyle(
                    color: isSelected ? color.withOpacity(0.7) : Colors.grey,
                    fontSize: 11)),
              ])),
              if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 20),
            ]),
          ),
        );
      }).toList()),
    ),
    const SizedBox(height: 12),

    _card(
      title: '📅 Dates',
      child: Column(children: [
        // Date début
        GestureDetector(
          onTap: () => _selectDate(true),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300)),
            child: Row(children: [
              const Icon(Icons.calendar_today_rounded,
                  color: kBlueLight, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Date de début', style: TextStyle(
                    color: Colors.grey, fontSize: 10)),
                Text('${_dateDebut.day}/${_dateDebut.month}/${_dateDebut.year}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ])),
              const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
            ]),
          ),
        ),
        const SizedBox(height: 10),

        // Date fin (optionnelle)
        GestureDetector(
          onTap: () => _selectDate(false),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300)),
            child: Row(children: [
              const Icon(Icons.event_rounded, color: kBlueLight, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Date de fin (optionnelle)', style: TextStyle(
                    color: Colors.grey, fontSize: 10)),
                Text(_dateFin != null
                    ? '${_dateFin!.day}/${_dateFin!.month}/${_dateFin!.year}'
                    : 'Non définie',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14,
                        color: _dateFin != null
                            ? const Color(0xFF1E293B) : Colors.grey)),
              ])),
              const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
            ]),
          ),
        ),
      ]),
    ),
  ]);

  // ── ÉTAPE 3 — Ferme & Résumé ──
  Widget _buildStep3() => Column(children: [
    // Ferme
    if (_fermes.isNotEmpty) _card(
      title: '🏡 Ferme',
      child: DropdownButtonFormField<String>(
          value: _fermeId,
          decoration: InputDecoration(
              prefixIcon: const Icon(Icons.agriculture_rounded,
                  color: kBlueLight, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true, fillColor: const Color(0xFFF8FAFC)),
          items: _fermes.map((f) => DropdownMenuItem<String>(
              value: f['id']?.toString(),
              child: Text(f['nom']?.toString() ?? ''))).toList(),
          onChanged: (v) => setState(() => _fermeId = v)),
    ),
    if (_fermes.isNotEmpty) const SizedBox(height: 12),

    // Notes
    _card(
      title: '📝 Notes',
      child: TextField(
          controller: _notesCtrl, maxLines: 3,
          decoration: InputDecoration(
              hintText: 'Observations, remarques particulières...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kBlue, width: 2)),
              filled: true, fillColor: const Color(0xFFF8FAFC))),
    ),
    const SizedBox(height: 12),

    // Résumé
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('📋', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text('Récapitulatif', style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
        ]),
        const SizedBox(height: 12),
        _resumeRow('Nom', _nomCtrl.text),
        _resumeRow('Sujets', _sujetsCtrl.text),
        _resumeRow('Type', _typeCycle),
        _resumeRow('Souche', _soucheCtrl.text.isNotEmpty
            ? _soucheCtrl.text : '-'),
        _resumeRow('Bâtiment', _batCtrl.text.isNotEmpty
            ? _batCtrl.text : '-'),
        _resumeRow('Début',
            '${_dateDebut.day}/${_dateDebut.month}/${_dateDebut.year}'),
      ]),
    ),
  ]);

  Widget _resumeRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(value, style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
      ]));

  Widget _card({required String title, required Widget child}) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        child,
      ]));

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false}) =>
      TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: kBlueLight, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBlue, width: 2)),
            filled: true, fillColor: const Color(0xFFF8FAFC)),
      );
}