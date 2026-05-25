import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _loginCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String _error = '';
  bool _showPass = false;
  bool _rememberMe = false;
  late AnimationController _animCtrl;
  late AnimationController _shakeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _shakeAnim;
  late Animation<double> _pulseAnim;

  final List<Map<String, String>> _demoComptes = [
    {'email': 'admin@kewere.sn', 'pass': 'admin123',
      'role': 'Admin', 'icon': '👑'},
    {'email': 'proprio@kewere.sn', 'pass': 'proprio123',
      'role': 'Propriétaire', 'icon': '🏆'},
    {'email': 'manager@kewere.sn', 'pass': 'manager123',
      'role': 'Manager', 'icon': '⭐'},
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800));
    _shakeCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    _shakeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  bool _isValid() {
    if (_loginCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Entrez votre email ou numéro');
      _shakeCtrl.forward(from: 0);
      return false;
    }
    if (_passCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Entrez votre mot de passe');
      _shakeCtrl.forward(from: 0);
      return false;
    }
    return true;
  }

  Future<void> _login() async {
    if (!_isValid()) return;
    setState(() { _loading = true; _error = ''; });
    try {
      final body =
          'username=${Uri.encodeComponent(_loginCtrl.text.trim())}'
          '&password=${Uri.encodeComponent(_passCtrl.text.trim())}';

      final r = await http.post(
          Uri.parse('$API_URL/auth/login'),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': '*/*',
          },
          body: body)
          .timeout(const Duration(seconds: 20));

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final token = data['access_token'] ?? '';
        final tempHeaders = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': '*/*',
        };
        final meR = await http.get(
            Uri.parse('$API_URL/auth/me'),
            headers: tempHeaders)
            .timeout(const Duration(seconds: 10));

        String role = 'proprietaire', nom = '', email = '',
            entrepriseId = '', fermeId = '';
        if (meR.statusCode == 200) {
          final me = jsonDecode(meR.body);
          role = me['role'] ?? 'proprietaire';
          nom = me['nom'] ?? '';
          email = me['email'] ?? '';
          entrepriseId = me['entreprise_id']?.toString() ?? '';
          fermeId = me['ferme_id']?.toString() ?? '';
        }
        await SessionManager.save(
            token: token, role: role, nom: nom,
            email: email, entrepriseId: entrepriseId,
            fermeId: fermeId);
        _naviguerAccueil();
      } else if (r.statusCode == 401 || r.statusCode == 422) {
        setState(() => _error = 'Email ou mot de passe incorrect');
        _shakeCtrl.forward(from: 0);
      } else {
        setState(() => _error = 'Erreur serveur (${r.statusCode})');
        _shakeCtrl.forward(from: 0);
      }
    } catch (e) {
      final msg = e.toString();
      setState(() => _error = msg.length > 100
          ? '${msg.substring(0, 100)}...' : msg);
      _shakeCtrl.forward(from: 0);
    }
    setState(() => _loading = false);
  }

  void _naviguerAccueil() {
    Navigator.pushReplacement(context,
        PageRouteBuilder(
            pageBuilder: (_, anim, __) => const HomeScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400)));
  }

  void _loginDemo(Map<String, String> compte) {
    setState(() {
      _loginCtrl.text = compte['email']!;
      _passCtrl.text = compte['pass']!;
      _error = '';
    });
    Future.delayed(const Duration(milliseconds: 300), _login);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E3A5F),
              Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedBuilder(
              animation: _animCtrl,
              builder: (_, child) => Opacity(
                opacity: _fadeAnim.value,
                child: Transform.translate(
                    offset: Offset(0, _slideAnim.value), child: child),
              ),
              child: Column(children: [
                SizedBox(height: size.height * 0.06),

                // Logo
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) => Transform.scale(
                      scale: _pulseAnim.value, child: child),
                  child: Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          kBlue.withOpacity(0.3),
                          kBlueLight.withOpacity(0.2)]),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2)),
                        boxShadow: [BoxShadow(
                            color: kBlue.withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8))]),
                    child: const Center(child: Text('🐔',
                        style: TextStyle(fontSize: 48))),
                  ),
                ),
                const SizedBox(height: 14),

                const Text('Kewere Aissa Smart', style: TextStyle(
                    color: Colors.white, fontSize: 24,
                    fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text(
                      '🌍 Plateforme Avicole Intelligente • Sénégal',
                      style: TextStyle(
                          color: Colors.white60, fontSize: 11)),
                ),
                const SizedBox(height: 28),

                // Carte login
                AnimatedBuilder(
                  animation: _shakeCtrl,
                  builder: (_, child) => Transform.translate(
                      offset: Offset(
                          _error.isNotEmpty
                              ? 8 * (0.5 - (_shakeAnim.value - 0.5).abs())
                              : 0, 0),
                      child: child),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10))]),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: kBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.lock_open_rounded,
                                    color: kBlue, size: 20)),
                            const SizedBox(width: 10),
                            const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Connexion', style: TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E293B))),
                                  Text('Accédez à votre espace',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 11)),
                                ]),
                          ]),
                          const SizedBox(height: 20),

                          TextField(
                            controller: _loginCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                                labelText: 'Email ou téléphone',
                                hintText: 'nom@email.com',
                                prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
                                    color: kBlueLight, size: 20),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: kBlue, width: 2)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC)),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: _passCtrl,
                            obscureText: !_showPass,
                            onSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: kBlueLight, size: 20),
                                suffixIcon: IconButton(
                                    icon: Icon(
                                        _showPass
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: Colors.grey, size: 20),
                                    onPressed: () => setState(
                                            () => _showPass = !_showPass)),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: kBlue, width: 2)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC)),
                          ),

                          Row(children: [
                            Checkbox(
                                value: _rememberMe,
                                onChanged: (v) => setState(
                                        () => _rememberMe = v ?? false),
                                activeColor: kBlue,
                                materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap),
                            const Text('Se souvenir de moi',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            const Spacer(),
                            TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 30)),
                                child: const Text('Oublié ?',
                                    style: TextStyle(color: kBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600))),
                          ]),

                          if (_error.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.red.shade200)),
                              child: Row(children: [
                                Icon(Icons.error_outline_rounded,
                                    color: Colors.red.shade600, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error,
                                    style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 12))),
                              ]),
                            ),
                            const SizedBox(height: 8),
                          ],

                          const SizedBox(height: 4),

                          SizedBox(width: double.infinity, height: 52,
                              child: ElevatedButton(
                                  onPressed: _loading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: kBlue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(14)),
                                      elevation: 0),
                                  child: _loading
                                      ? const SizedBox(width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5))
                                      : const Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.login_rounded, size: 18),
                                        SizedBox(width: 8),
                                        Text('Se connecter', style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                                      ]))),
                          const SizedBox(height: 16),

                          Row(children: [
                            Expanded(child: Divider(
                                color: Colors.grey.shade200)),
                            Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                child: Text('ou', style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12))),
                            Expanded(child: Divider(
                                color: Colors.grey.shade200)),
                          ]),
                          const SizedBox(height: 12),

                          SizedBox(width: double.infinity, height: 48,
                              child: OutlinedButton.icon(
                                  onPressed: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) =>
                                      const RegisterScreen())),
                                  icon: const Icon(
                                      Icons.person_add_rounded, size: 18),
                                  label: const Text('Créer un compte',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: kBlue,
                                      side: const BorderSide(color: kBlue),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(14))))),
                        ]),
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.1))),
                  child: Column(children: [
                    const Row(children: [
                      Icon(Icons.science_rounded,
                          color: Colors.white54, size: 14),
                      SizedBox(width: 6),
                      Text('Comptes de démonstration',
                          style: TextStyle(color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: _demoComptes.map((c) =>
                        Expanded(child: GestureDetector(
                          onTap: () => _loginDemo(c),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 6),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.15))),
                            child: Column(children: [
                              Text(c['icon']!,
                                  style: const TextStyle(fontSize: 18)),
                              const SizedBox(height: 3),
                              Text(c['role']!, style: const TextStyle(
                                  color: Colors.white70, fontSize: 9,
                                  fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center),
                            ]),
                          ),
                        ))).toList()),
                    const SizedBox(height: 8),
                    const Text(
                        'Cliquez pour vous connecter automatiquement',
                        style: TextStyle(
                            color: Colors.white30, fontSize: 9)),
                  ]),
                ),
                const SizedBox(height: 20),

                Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.security_rounded,
                          color: Colors.white24, size: 12),
                      const SizedBox(width: 5),
                      Text('Connexion sécurisée SSL • v1.0.0',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.25),
                              fontSize: 10)),
                    ]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _featureChip('🤖 IA Claude'),
                      const SizedBox(width: 6),
                      _featureChip('📊 Analytics'),
                      const SizedBox(width: 6),
                      _featureChip('🔒 Sécurisé'),
                    ]),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureChip(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15))),
      child: Text(text, style: const TextStyle(
          color: Colors.white60, fontSize: 10)));
}