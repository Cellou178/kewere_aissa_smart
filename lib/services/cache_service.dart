import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static SharedPreferences? _prefs;
  static const String _prefix = 'cache_';
  static const String _metaPrefix = 'meta_';

  // ── Init ──
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('✅ CacheService initialisé');
  }

  static SharedPreferences get _p {
    if (_prefs == null) throw Exception('CacheService non initialisé');
    return _prefs!;
  }

  // ── Sauvegarder ──
  static Future<void> set(String key, dynamic data,
      {Duration duration = const Duration(hours: 2)}) async {
    try {
      final json = jsonEncode(data);
      await _p.setString('$_prefix$key', json);
      await _p.setString('$_metaPrefix$key', jsonEncode({
        'savedAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now().add(duration).toIso8601String(),
      }));
      debugPrint('💾 Cache saved: $key');
    } catch (e) {
      debugPrint('❌ Cache set error: $e');
    }
  }

  // ── Récupérer ──
  static dynamic get(String key) {
    try {
      final raw = _p.getString('$_prefix$key');
      if (raw == null) return null;
      final metaRaw = _p.getString('$_metaPrefix$key');
      if (metaRaw != null) {
        final meta = jsonDecode(metaRaw);
        final expires = DateTime.parse(meta['expiresAt']);
        if (DateTime.now().isAfter(expires)) {
          debugPrint('⏰ Cache expired: $key');
          _delete(key);
          return null;
        }
      }
      debugPrint('✅ Cache hit: $key');
      return jsonDecode(raw);
    } catch (e) {
      debugPrint('❌ Cache get error: $e');
      return null;
    }
  }

  // ── Récupérer liste ──
  static List getList(String key) {
    final data = get(key);
    return data is List ? data : [];
  }

  // ── Récupérer map ──
  static Map<String, dynamic> getMap(String key) {
    final data = get(key);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // ── Existe et valide ──
  static bool has(String key) {
    try {
      final raw = _p.getString('$_prefix$key');
      if (raw == null) return false;
      final metaRaw = _p.getString('$_metaPrefix$key');
      if (metaRaw == null) return true;
      final meta = jsonDecode(metaRaw);
      final expires = DateTime.parse(meta['expiresAt']);
      return DateTime.now().isBefore(expires);
    } catch (_) { return false; }
  }

  // ── Supprimer ──
  static Future<void> _delete(String key) async {
    await _p.remove('$_prefix$key');
    await _p.remove('$_metaPrefix$key');
  }

  static Future<void> delete(String key) => _delete(key);

  // ── Effacer tout ──
  static Future<void> clearAll() async {
    final keys = _p.getKeys()
        .where((k) => k.startsWith(_prefix) ||
        k.startsWith(_metaPrefix)).toList();
    for (final k in keys) await _p.remove(k);
    debugPrint('🗑️ Cache effacé — ${ keys.length} entrées');
  }

  // ── Effacer expiré ──
  static Future<void> clearExpired() async {
    final metaKeys = _p.getKeys()
        .where((k) => k.startsWith(_metaPrefix)).toList();
    int count = 0;
    for (final metaKey in metaKeys) {
      try {
        final metaRaw = _p.getString(metaKey);
        if (metaRaw == null) continue;
        final meta = jsonDecode(metaRaw);
        final expires = DateTime.parse(meta['expiresAt']);
        if (DateTime.now().isAfter(expires)) {
          final dataKey = metaKey.replaceFirst(_metaPrefix, _prefix);
          await _p.remove(dataKey);
          await _p.remove(metaKey);
          count++;
        }
      } catch (_) {}
    }
    debugPrint('🗑️ Cache expiré effacé: $count entrées');
  }

  // ── Stats ──
  static Map<String, dynamic> getStats() {
    final allKeys = _p.getKeys();
    final cacheKeys = allKeys
        .where((k) => k.startsWith(_prefix)).toList();
    int expired = 0, valid = 0;
    for (final k in cacheKeys) {
      final shortKey = k.replaceFirst(_prefix, '');
      if (has(shortKey)) { valid++; } else { expired++; }
    }
    return {
      'total': cacheKeys.length,
      'valid': valid,
      'expired': expired,
      'keys': cacheKeys.map((k) => k.replaceFirst(_prefix, '')).toList(),
    };
  }

  // ── Clés standards ──
  static const String kCycles = 'cycles';
  static const String kDonnees = 'donnees';
  static const String kFermes = 'fermes';
  static const String kStocks = 'stocks';
  static const String kEmployes = 'employes';
  static const String kMeteo = 'meteo';
  static const String kDashboard = 'dashboard';
}