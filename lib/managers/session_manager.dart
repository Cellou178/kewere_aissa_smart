import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';

class SessionManager {
  // ── Données en mémoire ──
  static String _token = '';
  static String _role = '';
  static String _nom = '';
  static String _email = '';
  static String _entrepriseId = '';
  static String _fermeId = '';
  static DateTime? _loginTime;
  static DateTime? _lastActivity;

  // ── Clés SharedPreferences (données non sensibles) ──
  static const String _kRole = 'role';
  static const String _kNom = 'nom';
  static const String _kEmail = 'email';
  static const String _kEntrepriseId = 'entreprise_id';
  static const String _kFermeId = 'ferme_id';
  static const String _kLoginTime = 'login_time';

  // ── Clé SecureStorage (token JWT chiffré) ──
  static const String _kToken = 'kas_jwt_token';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Init ──
  static Future<void> init() async {
    try {
      // Token JWT depuis le stockage chiffré
      _token = await _secureStorage.read(key: _kToken) ?? '';
      // Données non sensibles depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _role = prefs.getString(_kRole) ?? '';
      _nom = prefs.getString(_kNom) ?? '';
      _email = prefs.getString(_kEmail) ?? '';
      _entrepriseId = prefs.getString(_kEntrepriseId) ?? '';
      _fermeId = prefs.getString(_kFermeId) ?? '';
      final loginTimeStr = prefs.getString(_kLoginTime);
      if (loginTimeStr != null) {
        _loginTime = DateTime.tryParse(loginTimeStr);
      }
      _lastActivity = DateTime.now();
      debugPrint('✅ Session chargée — role: $_role, nom: $_nom');
    } catch (e) {
      debugPrint('❌ Erreur chargement session: $e');
    }
  }

  // ── Sauvegarder ──
  static Future<void> save({
    required String token,
    required String role,
    required String nom,
    required String email,
    required String entrepriseId,
    String fermeId = '',
  }) async {
    try {
      final now = DateTime.now();
      // Token JWT dans le stockage chiffré
      await _secureStorage.write(key: _kToken, value: token);
      // Données non sensibles dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_kRole, role),
        prefs.setString(_kNom, nom),
        prefs.setString(_kEmail, email),
        prefs.setString(_kEntrepriseId, entrepriseId),
        prefs.setString(_kFermeId, fermeId),
        prefs.setString(_kLoginTime, now.toIso8601String()),
      ]);
      _token = token;
      _role = role;
      _nom = nom;
      _email = email;
      _entrepriseId = entrepriseId;
      _fermeId = fermeId;
      _loginTime = now;
      _lastActivity = now;
      debugPrint('✅ Session sauvegardée — role: $role');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde session: $e');
    }
  }

  // ── Effacer ──
  static Future<void> clear() async {
    try {
      await _secureStorage.delete(key: _kToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _token = '';
      _role = '';
      _nom = '';
      _email = '';
      _entrepriseId = '';
      _fermeId = '';
      _loginTime = null;
      _lastActivity = null;
      debugPrint('✅ Session effacée');
    } catch (e) {
      debugPrint('❌ Erreur effacement session: $e');
    }
  }

  // ── Mettre à jour l'activité ──
  static void updateActivity() {
    _lastActivity = DateTime.now();
  }

  // ── Vérifier expiration ──
  static bool isExpired({Duration timeout = const Duration(minutes: 30)}) {
    if (_lastActivity == null) return true;
    return DateTime.now().difference(_lastActivity!) > timeout;
  }

  // ── Getters de base ──
  static bool get isLoggedIn => _token.isNotEmpty;
  static String get token => _token;
  static String get role => _role.toLowerCase();
  static String get nom => _nom;
  static String get email => _email;
  static String get entrepriseId => _entrepriseId;
  static String get fermeId => _fermeId;
  static DateTime? get loginTime => _loginTime;
  static DateTime? get lastActivity => _lastActivity;

  // ── Getters rôles ──
  static bool get isAdmin => role == 'admin';
  static bool get isProprietaire =>
      role == 'proprietaire' || role == 'proprietaire';
  static bool get isManager => role == 'manager';
  static bool get isEmploye => role == 'employe';
  static bool get isVeterinaire => role == 'veterinaire';
  static bool get isComptable => role == 'comptable';

  // ── Permissions ──
  static bool get peutVoirFinance =>
      isAdmin || isProprietaire || isComptable;
  static bool get peutCreerCycle =>
      isAdmin || isProprietaire || isManager;
  static bool get peutSupprimerDonnees =>
      isAdmin || isProprietaire;
  static bool get peutGererEmployes =>
      isAdmin || isProprietaire;
  static bool get peutVoirRapports =>
      isAdmin || isProprietaire || isManager;
  static bool get peutModifierParametres =>
      isAdmin || isProprietaire;

  // ── Infos session ──
  static String get dureeConnexion {
    if (_loginTime == null) return '-';
    final diff = DateTime.now().difference(_loginTime!);
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}min';
    return '${diff.inMinutes} min';
  }

  static String get initialesNom {
    if (_nom.isEmpty) return 'U';
    final parts = _nom.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _nom[0].toUpperCase();
  }

  static String get prenomNom {
    if (_nom.isEmpty) return 'Utilisateur';
    return _nom.split(' ').first;
  }

  static Color get roleColor {
    switch (role) {
      case 'admin': return const Color(0xFFDC2626);
      case 'proprietaire': return const Color(0xFF1B3A6B);
      case 'manager': return const Color(0xFF7C3AED);
      case 'employe': return const Color(0xFF16A34A);
      case 'veterinaire': return const Color(0xFF0891B2);
      case 'comptable': return const Color(0xFF059669);
      default: return const Color(0xFF6B7280);
    }
  }

  static String get roleBadge {
    switch (role) {
      case 'admin': return '👑';
      case 'proprietaire': return '🏆';
      case 'manager': return '⭐';
      case 'employe': return '👷';
      case 'veterinaire': return '🩺';
      case 'comptable': return '📊';
      default: return '👤';
    }
  }

  // ── Headers HTTP ──
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  static Map<String, String> get headersForm => {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Bearer $_token',
  };

  // ── Debug ──
  static void printSession() {
    debugPrint('=== SESSION INFO ===');
    debugPrint('Token: ${_token.isNotEmpty ? '✅ Présent' : '❌ Absent'}');
    debugPrint('Role: $_role');
    debugPrint('Nom: $_nom');
    debugPrint('Email: $_email');
    debugPrint('FermeId: $_fermeId');
    debugPrint('Connecté: $isLoggedIn');
    debugPrint('Durée: $dureeConnexion');
    debugPrint('===================');
  }
}