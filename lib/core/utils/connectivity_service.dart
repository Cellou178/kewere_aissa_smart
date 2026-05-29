import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

class ConnectivityService {
  static bool _isOnline = true;
  static final List<Function(bool)> _listeners = [];
  static Timer? _timer;

  static bool get isOnline => _isOnline;
  static bool get isOffline => !_isOnline;

  // ── Démarrer la surveillance ──
  static void startMonitoring({
    Duration interval = const Duration(seconds: 10),
  }) {
    _timer?.cancel();
    _checkConnectivity();
    _timer = Timer.periodic(interval, (_) => _checkConnectivity());
    debugPrint('📡 ConnectivityService démarré');
  }

  static void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  // ── Vérifier connexion ──
  static Future<bool> _checkConnectivity() async {
    try {
      final r = await http.get(
          Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      final wasOnline = _isOnline;
      _isOnline = r.statusCode == 200;
      if (wasOnline != _isOnline) _notifyListeners();
      return _isOnline;
    } catch (_) {
      final wasOnline = _isOnline;
      _isOnline = false;
      if (wasOnline != _isOnline) _notifyListeners();
      return false;
    }
  }

  static Future<bool> check() => _checkConnectivity();

  // ── Listeners ──
  static void addListener(Function(bool) listener) {
    _listeners.add(listener);
  }

  static void removeListener(Function(bool) listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners() {
    for (final l in _listeners) l(_isOnline);
    debugPrint(_isOnline ? '📶 Connexion rétablie' : '📴 Connexion perdue');
  }
}