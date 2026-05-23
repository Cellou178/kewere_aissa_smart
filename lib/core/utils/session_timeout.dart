import 'dart:async';
import 'package:flutter/material.dart';
import '../../managers/session_manager.dart';
import '../../screens/auth/login_screen.dart';

class SessionTimeout extends StatefulWidget {
  final Widget child;
  final Duration timeout;

  const SessionTimeout({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 30),
  });

  @override
  State<SessionTimeout> createState() => _SessionTimeoutState();
}

class _SessionTimeoutState extends State<SessionTimeout> {
  Timer? _timer;
  late DateTime _lastActivity;

  @override
  void initState() {
    super.initState();
    _lastActivity = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (DateTime.now().difference(_lastActivity) >= widget.timeout) {
        _logout();
      }
    });
  }

  void _resetTimer() {
    _lastActivity = DateTime.now();
  }

  Future<void> _logout() async {
    _timer?.cancel();
    await SessionManager.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('⏱️ Session expirée. Reconnectez-vous.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating));
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetTimer,
      onPanDown: (_) => _resetTimer(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}