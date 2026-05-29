import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _loading = false;
  String _error = '';
  bool _showPass = false;
  bool _showConfirmPass = false;
  bool _acceptTerms = false;
  String _roleSelected = 'proprietaire';
  int _currentStep = 0;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  final List<Map<String, dynamic>> _roles = [
    {'value': 'proprietaire', 'label': 'Propriétaire',
      'icon': Icons.business_rounded, 'color': kBlue,
      'desc': 'Gérez votre ferme complète'},
    {'value': 'manager', 'label': 'Manager',
      'icon': Icons.manage_accounts_rounded, 'color': kPurple,
      'desc': 'Superviser les opérations'},
    {'value': 'employe', 'label': 'Employé',
      'icon': Icons.person_rounded, 'color': kGreen,
      'desc': 'Saisie des données terrain'},
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _emailCtrl.dispose();
    _telCtrl.dispose(); _passCtrl.dispose();
    _confirmPassCtrl.dispose(); _animCtrl.dispose();
    super.dispose();
  }

  bool _isStep1Valid() {
    if (_nomCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Le nom est obligatoire'); return false;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'L\'email est obligatoire'); return false;
    }
    if (!_emailCtrl.text.contains('@')) {
      setState(() => _error = 'Email invalide'); return false;
    }
    return true;
  }

  bool _isStep2Valid() {
    if (_passCtrl.text.length < 6) {
      setState(() => _error = 'Mot de passe: 6 caractères minimum'); return false;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas'); return false;
    }
    if (!_acceptTerms) {
      setState(() => _error = 'Acceptez les conditions d\'utilisation'); return false;
    }
    return true;
  }

  Future<void> _register() async {
    if (!_isStep2Valid()) return;
    setState(() { _loading = true; _error = ''; });
    try {
      final result = await ApiService.register({
        'nom': _nomCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'telephone': _telCtrl.text.trim(),
        'mot_de_passe': _passCtrl.text,
        'role': _roleSelected,
        'entreprise_id': '11111111-1111-1111-1111-111111111111',
      });
      if (result['status'] == 200 || result['status'] == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Compte créé ! Connectez-vous.'),
            backgroundColor: kGreen, behavior: SnackBarBehavior.floating));
      } else {
        setState(() => _error = result['body']['detail']?.toString() ?? 'Erreur');
      }
    } catch (e) {
      setState(() => _error = 'Erreur de connexion');
    }
    setState(() => _loading = false);
  }

  void _nextStep() {
    setState(() => _error = '');
    if (_currentStep == 0 && !_isStep1Valid()) return;
    if (_currentStep < 2) setState(() => _currentStep++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E3A5F), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animCtrl,
            builder: (_, child) => Opacity(
              opacity: _fadeAnim.value,
              child: Transform.translate(
                  offset: Offset(0, _slideAnim.value), child: child),
            ),
            child: Column(children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(children: [
                  IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                      onPressed: () => _currentStep > 0
                          ? setState(() { _currentStep--; _error = ''; })
                          : Navigator.pop(context)),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Créer un compte', style: TextStyle(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w900)),
                    Text('Étape ${_currentStep + 1} sur 3',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ])),
                  // Logo
                  Container(width: 40, height: 40,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Center(
                          child: Text('🐔', style: TextStyle(fontSize: 22)))),
                ]),
              ),

              // Barre de progression
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(children: List.generate(3, (i) => Expanded(
                  child: Container(
                    height: 4, margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                        color: i <= _currentStep
                            ? kGreen : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ))),
              ),
              const SizedBox(height: 16),

              // Contenu
              Expanded(child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => SlideTransition(
                        position: Tween<Offset>(
                            begin: const Offset(1, 0), end: Offset.zero)
                            .animate(anim), child: child),
                    child: KeyedSubtree(
                        key: ValueKey(_currentStep),
                        child: _currentStep == 0 ? _buildStep1()
                            : _currentStep == 1 ? _buildStep2()
                            : _buildStep3()),
                  ),
                  const SizedBox(height: 20),

                  // Erreur
                  if (_error.isNotEmpty) Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.3))),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error, style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12))),
                    ]),
                  ),
                  if (_error.isNotEmpty) const SizedBox(height: 12),

                  // Bouton
                  SizedBox(width: double.infinity, height: 52,
                      child: ElevatedButton(
                          onPressed: _loading ? null
                              : _currentStep < 2 ? _nextStep : _register,
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
                                    : Icons.check_circle_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(_currentStep < 2 ? 'Continuer'
                                    : 'Créer mon compte',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                              ]))),
                  const SizedBox(height: 16),

                  // Déjà un compte
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('Déjà un compte ?',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Se connecter',
                            style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700, fontSize: 12))),
                  ]),
                  const SizedBox(height: 24),
                ]),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  // ── ÉTAPE 1 — Infos personnelles ──
  Widget _buildStep1() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2),
            blurRadius: 30, offset: const Offset(0, 10))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _stepHeader('👤', 'Informations personnelles',
          'Renseignez vos coordonnées'),
      const SizedBox(height: 20),
      _field(_nomCtrl, 'Nom complet *', Icons.person_rounded),
      const SizedBox(height: 12),
      _field(_emailCtrl, 'Email *', Icons.email_rounded, isEmail: true),
      const SizedBox(height: 12),
      _field(_telCtrl, 'Téléphone', Icons.phone_rounded, isPhone: true),
    ]),
  );

  // ── ÉTAPE 2 — Sécurité ──
  Widget _buildStep2() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2),
            blurRadius: 30, offset: const Offset(0, 10))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _stepHeader('🔐', 'Sécurité', 'Choisissez un mot de passe fort'),
      const SizedBox(height: 20),
      _passField(_passCtrl, 'Mot de passe *', _showPass,
              () => setState(() => _showPass = !_showPass)),
      const SizedBox(height: 8),
      // Indicateur force
      _passwordStrength(_passCtrl.text),
      const SizedBox(height: 12),
      _passField(_confirmPassCtrl, 'Confirmer le mot de passe *',
          _showConfirmPass,
              () => setState(() => _showConfirmPass = !_showConfirmPass)),
      const SizedBox(height: 16),
      // CGU
      GestureDetector(
        onTap: () => setState(() => _acceptTerms = !_acceptTerms),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
                color: _acceptTerms ? kGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: _acceptTerms ? kGreen : Colors.grey.shade300,
                    width: 2)),
            child: _acceptTerms
                ? const Icon(Icons.check_rounded,
                color: Colors.white, size: 14) : null,
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text(
              'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
              style: TextStyle(fontSize: 12, color: Color(0xFF1E293B)))),
        ]),
      ),
    ]),
  );

  // ── ÉTAPE 3 — Rôle ──
  Widget _buildStep3() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2),
            blurRadius: 30, offset: const Offset(0, 10))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _stepHeader('💼', 'Votre rôle', 'Comment utilisez-vous Kewere ?'),
      const SizedBox(height: 20),
      ..._roles.map((r) {
        final isSelected = _roleSelected == r['value'];
        final color = r['color'] as Color;
        return GestureDetector(
          onTap: () => setState(() => _roleSelected = r['value']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.08) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isSelected ? color : Colors.grey.shade200,
                    width: isSelected ? 2 : 1)),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: color.withOpacity(isSelected ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(r['icon'] as IconData, color: color, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r['label'] as String, style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14,
                    color: isSelected ? color : const Color(0xFF1E293B))),
                Text(r['desc'] as String, style: TextStyle(
                    color: isSelected ? color.withOpacity(0.7) : Colors.grey,
                    fontSize: 11)),
              ])),
              if (isSelected) Icon(Icons.check_circle_rounded,
                  color: color, size: 22),
            ]),
          ),
        );
      }),

      // Résumé
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: kBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBlue.withOpacity(0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('📋 Récapitulatif', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 12, color: kBlue)),
          const SizedBox(height: 8),
          _resumeRow('👤 Nom', _nomCtrl.text),
          _resumeRow('📧 Email', _emailCtrl.text),
          if (_telCtrl.text.isNotEmpty) _resumeRow('📞 Tel', _telCtrl.text),
          _resumeRow('💼 Rôle', _roleSelected),
        ]),
      ),
    ]),
  );

  Widget _resumeRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Text('$label: ', style: const TextStyle(
            color: Colors.grey, fontSize: 11)),
        Text(value, style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 11,
            color: Color(0xFF1E293B))),
      ]));

  Widget _stepHeader(String emoji, String title, String subtitle) =>
      Row(children: [
        Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: kBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Text(emoji, style: const TextStyle(fontSize: 22))),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B))),
          Text(subtitle, style: const TextStyle(
              color: Colors.grey, fontSize: 11)),
        ]),
      ]);

  Widget _passwordStrength(String pass) {
    int strength = 0;
    if (pass.length >= 6) strength++;
    if (pass.length >= 10) strength++;
    if (pass.contains(RegExp(r'[A-Z]'))) strength++;
    if (pass.contains(RegExp(r'[0-9]'))) strength++;
    if (pass.contains(RegExp(r'[!@#$%^&*]'))) strength++;

    final color = strength <= 1 ? kRed : strength <= 3 ? kOrange : kGreen;
    final label = strength <= 1 ? 'Faible' : strength <= 3 ? 'Moyen' : 'Fort';

    return pass.isEmpty ? const SizedBox() : Row(children: [
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
              value: strength / 5, backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color), minHeight: 4))),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(color: color, fontSize: 10,
          fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool isEmail = false, bool isPhone = false}) =>
      TextField(
        controller: ctrl,
        onChanged: (_) => setState(() {}),
        keyboardType: isEmail ? TextInputType.emailAddress
            : isPhone ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: kBlueLight, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBlue, width: 2)),
            filled: true, fillColor: const Color(0xFFF8FAFC)),
      );

  Widget _passField(TextEditingController ctrl, String label,
      bool show, VoidCallback toggle) =>
      TextField(
        controller: ctrl,
        obscureText: !show,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                color: kBlueLight, size: 20),
            suffixIcon: IconButton(
                icon: Icon(show ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                    color: Colors.grey, size: 20),
                onPressed: toggle),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBlue, width: 2)),
            filled: true, fillColor: const Color(0xFFF8FAFC)),
      );
}