import 'package:flutter/material.dart';
import 'dart:math';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _progressCtrl;

  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _progressAnim;
  late Animation<double> _taglineAnim;

  final List<String> _loadingMessages = [
    'Initialisation...',
    'Chargement des données...',
    'Connexion au serveur...',
    'Préparation du tableau de bord...',
    'Presque prêt...',
  ];
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();

    // Animation principale
    _mainCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _mainCtrl, curve: Curves.easeOut));
    _scaleAnim = Tween<double>(begin: 0.5, end: 1).animate(
        CurvedAnimation(parent: _mainCtrl, curve: Curves.elasticOut));
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
        CurvedAnimation(parent: _mainCtrl, curve: Curves.easeOut));

    // Animation pulse logo
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Animation particules
    _particleCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat();

    // Animation progress
    _progressCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 3500));
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut));

    // Animation tagline
    _taglineAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _mainCtrl,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));

    // Démarrer les animations
    _mainCtrl.forward();
    _progressCtrl.forward();

    // Changer les messages
    _startMessageRotation();

    // Naviguer après délai
    Future.delayed(const Duration(milliseconds: 3800), _navigate);
  }

  void _startMessageRotation() {
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _messageIndex = 1);
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            setState(() => _messageIndex = 2);
            Future.delayed(const Duration(milliseconds: 700), () {
              if (mounted) {
                setState(() => _messageIndex = 3);
                Future.delayed(const Duration(milliseconds: 700), () {
                  if (mounted) setState(() => _messageIndex = 4);
                });
              }
            });
          }
        });
      }
    });
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final isLoggedIn = SessionManager.isLoggedIn;
    Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (_, anim, __) => isLoggedIn
            ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500)));
  }

  @override
  void dispose() {
    _mainCtrl.dispose(); _pulseCtrl.dispose();
    _particleCtrl.dispose(); _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), Color(0xFF1E3A5F),
              Color(0xFF0F3460), Color(0xFF0F172A)
            ],
          ),
        ),
        child: Stack(children: [
          // Particules de fond
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
                size: size,
                painter: _ParticlesPainter(_particleCtrl.value)),
          ),

          // Cercles décoratifs
          Positioned(top: -100, right: -100,
              child: Container(width: 300, height: 300,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kBlue.withOpacity(0.05)))),
          Positioned(bottom: -80, left: -80,
              child: Container(width: 250, height: 250,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kGreen.withOpacity(0.05)))),

          // Contenu principal
          SafeArea(child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(children: [
              const Spacer(flex: 2),

              // Logo
              AnimatedBuilder(
                animation: Listenable.merge([_scaleAnim, _pulseAnim]),
                builder: (_, child) => Transform.scale(
                  scale: _scaleAnim.value * _pulseAnim.value,
                  child: child,
                ),
                child: Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [
                            kBlue.withOpacity(0.3),
                            kBlueLight.withOpacity(0.2)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: kBlue.withOpacity(0.4),
                            blurRadius: 30, offset: const Offset(0, 10)),
                        BoxShadow(color: Colors.white.withOpacity(0.05),
                            blurRadius: 10, offset: const Offset(-5, -5)),
                      ]),
                  child: const Center(
                      child: Text('🐔', style: TextStyle(fontSize: 56))),
                ),
              ),
              const SizedBox(height: 28),

              // Titre
              AnimatedBuilder(
                animation: _slideAnim,
                builder: (_, child) => Transform.translate(
                    offset: Offset(0, _slideAnim.value), child: child),
                child: Column(children: [
                  const Text('Kewere Aissa Smart', style: TextStyle(
                      color: Colors.white, fontSize: 28,
                      fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  FadeTransition(opacity: _taglineAnim,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2))),
                        child: const Row(mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🌍', style: TextStyle(fontSize: 14)),
                              SizedBox(width: 6),
                              Text('Plateforme Avicole Intelligente',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                            ]),
                      )),
                  const SizedBox(height: 8),
                  FadeTransition(opacity: _taglineAnim,
                      child: const Text('Sénégal 🇸🇳',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 12))),
                ]),
              ),

              const Spacer(flex: 2),

              // Features chips
              FadeTransition(opacity: _taglineAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _featureChip('🤖', 'IA Claude'),
                          const SizedBox(width: 8),
                          _featureChip('📊', 'Analytics'),
                          const SizedBox(width: 8),
                          _featureChip('🔒', 'Sécurisé'),
                        ]),
                  )),
              const SizedBox(height: 40),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(children: [
                  // Message loading
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                        _loadingMessages[_messageIndex],
                        key: ValueKey(_messageIndex),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ),
                  const SizedBox(height: 12),
                  // Barre
                  AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (_, __) => Column(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                            value: _progressAnim.value,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation(
                                Color.lerp(kBlue, kGreen,
                                    _progressAnim.value) ?? kBlue),
                            minHeight: 4),
                      ),
                      const SizedBox(height: 6),
                      Text(
                          '${(_progressAnim.value * 100).toInt()}%',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 32),

              // Version
              const Text('v1.0.0 • Powered by Claude AI',
                  style: TextStyle(color: Colors.white24, fontSize: 10)),
              const SizedBox(height: 24),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _featureChip(String emoji, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(
            color: Colors.white60, fontSize: 10,
            fontWeight: FontWeight.w500)),
      ]));
}

// ── Painter particules ──
class _ParticlesPainter extends CustomPainter {
  final double progress;
  _ParticlesPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = Random(42);

    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2 + 0.5;
      final opacity = (sin(progress * 2 * pi + i * 0.5) * 0.5 + 0.5) * 0.3;

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}