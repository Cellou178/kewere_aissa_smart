import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../managers/session_manager.dart';

// ── Exception API ──
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException({required this.statusCode, required this.message});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static const Duration _timeout = Duration(seconds: 20);
  static const int _maxRetries = 2;

  // ── Cache simple en mémoire ──
  static final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 2);

  static void clearCache() => _cache.clear();
  static void clearCacheFor(String key) => _cache.remove(key);

  // ── Logs ──
  static bool _logsEnabled = true;
  static void _log(String msg) {
    if (_logsEnabled) debugPrint('🌐 ApiService: $msg');
  }

  // ── Handler centralisé ──
  static dynamic _handle(http.Response r, String url) {
    _log('${r.statusCode} $url');
    switch (r.statusCode) {
      case 200:
      case 201:
        try {
          final data = jsonDecode(utf8.decode(r.bodyBytes));
          if (data is Map && data.containsKey('items')) return data['items'];
          return data;
        } catch (e) {
          _log('Erreur parsing JSON: $e');
          return null;
        }
      case 401:
        SessionManager.clear();
        throw const ApiException(statusCode: 401, message: 'SESSION_EXPIRED');
      case 403:
        throw const ApiException(statusCode: 403, message: 'ACCES_REFUSE');
      case 404:
        throw ApiException(statusCode: 404, message: 'Ressource introuvable: $url');
      case 422:
        throw const ApiException(statusCode: 422, message: 'Données invalides');
      case 500:
        throw const ApiException(statusCode: 500, message: 'Erreur serveur interne');
      default:
        throw ApiException(statusCode: r.statusCode,
            message: 'Erreur HTTP ${r.statusCode}');
    }
  }

  // ── GET avec cache et retry ──
  static Future<List> _getList(String url,
      {bool useCache = true, String? cacheKey}) async {
    final key = cacheKey ?? url;
    if (useCache && _cache.containsKey(key)) {
      final entry = _cache[key]!;
      if (!entry.isExpired) {
        _log('Cache hit: $key');
        return entry.data as List;
      }
    }
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final r = await http.get(Uri.parse(url),
            headers: SessionManager.headers).timeout(_timeout);
        final data = _handle(r, url);
        if (data is List) {
          if (useCache) {
            _cache[key] = _CacheEntry(data);
          }
          return data;
        }
        return [];
      } on ApiException { rethrow; }
      catch (e) {
        if (attempt == _maxRetries) {
          _log('Échec après $_maxRetries tentatives: $url — $e');
        } else {
          _log('Tentative ${attempt + 1}/$_maxRetries: $url');
          await Future.delayed(Duration(seconds: attempt + 1));
        }
      }
    }
    return [];
  }

  static Future<Map<String, dynamic>> _getMap(String url,
      {bool useCache = false}) async {
    if (useCache && _cache.containsKey(url)) {
      final entry = _cache[url]!;
      if (!entry.isExpired) return entry.data as Map<String, dynamic>;
    }
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final r = await http.get(Uri.parse(url),
            headers: SessionManager.headers).timeout(_timeout);
        final data = _handle(r, url);
        if (data is Map) {
          final result = Map<String, dynamic>.from(data);
          if (useCache) _cache[url] = _CacheEntry(result);
          return result;
        }
        return {};
      } on ApiException { rethrow; }
      catch (e) {
        if (attempt == _maxRetries) {
          _log('Échec GET map: $url — $e');
        } else {
          await Future.delayed(Duration(seconds: attempt + 1));
        }
      }
    }
    return {};
  }

  // ── POST ──
  static Future<bool> _post(String url, Map<String, dynamic> body,
      {List<String>? invalidateCache}) async {
    try {
      _log('POST $url');
      final r = await http.post(Uri.parse(url),
          headers: SessionManager.headers,
          body: jsonEncode(body)).timeout(_timeout);
      final ok = r.statusCode == 200 || r.statusCode == 201;
      if (ok && invalidateCache != null) {
        for (final k in invalidateCache) clearCacheFor(k);
      }
      if (r.statusCode == 401) {
        SessionManager.clear();
        throw const ApiException(statusCode: 401, message: 'SESSION_EXPIRED');
      }
      if (!ok) _log('POST échoué ${r.statusCode}: $url');
      return ok;
    } on ApiException { rethrow; }
    catch (e) { _log('POST erreur: $url — $e'); }
    return false;
  }

  // ── POST avec retour données ──
  static Future<Map<String, dynamic>> _postReturn(
      String url, Map<String, dynamic> body) async {
    try {
      final r = await http.post(Uri.parse(url),
          headers: SessionManager.headers,
          body: jsonEncode(body)).timeout(_timeout);
      return {'status': r.statusCode,
        'body': jsonDecode(utf8.decode(r.bodyBytes))};
    } catch (e) { _log('POST return erreur: $url — $e'); }
    return {'status': 500, 'body': {}};
  }

  // ── PUT ──
  static Future<bool> _put(String url, Map<String, dynamic> body,
      {List<String>? invalidateCache}) async {
    try {
      _log('PUT $url');
      final r = await http.put(Uri.parse(url),
          headers: SessionManager.headers,
          body: jsonEncode(body)).timeout(_timeout);
      final ok = r.statusCode == 200 || r.statusCode == 201;
      if (ok && invalidateCache != null) {
        for (final k in invalidateCache) clearCacheFor(k);
      }
      if (r.statusCode == 401) {
        SessionManager.clear();
        throw const ApiException(statusCode: 401, message: 'SESSION_EXPIRED');
      }
      return ok;
    } on ApiException { rethrow; }
    catch (e) { _log('PUT erreur: $url — $e'); }
    return false;
  }

  // ── DELETE ──
  static Future<bool> _delete(String url,
      {List<String>? invalidateCache}) async {
    try {
      _log('DELETE $url');
      final r = await http.delete(Uri.parse(url),
          headers: SessionManager.headers).timeout(_timeout);
      final ok = r.statusCode == 200 || r.statusCode == 204;
      if (ok && invalidateCache != null) {
        for (final k in invalidateCache) clearCacheFor(k);
      }
      if (r.statusCode == 401) {
        SessionManager.clear();
        throw const ApiException(statusCode: 401, message: 'SESSION_EXPIRED');
      }
      return ok;
    } on ApiException { rethrow; }
    catch (e) { _log('DELETE erreur: $url — $e'); }
    return false;
  }

  // ══════════════════════════════════════
  // ── ENDPOINTS ──
  // ══════════════════════════════════════

  // ── CYCLES ──
  static Future<List> getCycles({String? fermeId}) =>
      _getList('$API_URL/cycles/${fermeId != null ? '?ferme_id=$fermeId' : ''}',
          cacheKey: 'cycles_${fermeId ?? 'all'}');

  static Future<bool> createCycle(Map<String, dynamic> data) =>
      _post('$API_URL/cycles/', data,
          invalidateCache: ['cycles_all',
            'cycles_${data['ferme_id'] ?? ''}']);

  static Future<bool> updateCycle(String id, Map<String, dynamic> data) =>
      _put('$API_URL/cycles/$id', data,
          invalidateCache: ['cycles_all']);

  static Future<bool> deleteCycle(String id) =>
      _delete('$API_URL/cycles/$id',
          invalidateCache: ['cycles_all']);

  static Future<Map<String, dynamic>> getCycleById(String id) =>
      _getMap('$API_URL/cycles/$id');

  // ── DONNÉES ──
  static Future<List> getDonnees({String? cycleId}) =>
      _getList(cycleId != null
          ? '$API_URL/donnees/?cycle_id=$cycleId'
          : '$API_URL/donnees/',
          cacheKey: 'donnees_${cycleId ?? 'all'}');

  static Future<bool> createDonnee(Map<String, dynamic> data) =>
      _post('$API_URL/donnees/', data,
          invalidateCache: ['donnees_all',
            'donnees_${data['cycle_id'] ?? ''}']);

  static Future<bool> updateDonnee(String id, Map<String, dynamic> data) =>
      _put('$API_URL/donnees/$id', data,
          invalidateCache: ['donnees_all']);

  static Future<bool> deleteDonnee(String id) =>
      _delete('$API_URL/donnees/$id',
          invalidateCache: ['donnees_all']);

  // ── STOCKS ──
  static Future<List> getStocks() =>
      _getList('$API_URL/stocks/', cacheKey: 'stocks_all');

  static Future<bool> createStock(Map<String, dynamic> data) =>
      _post('$API_URL/stocks/', data, invalidateCache: ['stocks_all']);

  static Future<bool> updateStock(String id, Map<String, dynamic> data) =>
      _put('$API_URL/stocks/$id', data, invalidateCache: ['stocks_all']);

  static Future<bool> deleteStock(String id) =>
      _delete('$API_URL/stocks/$id', invalidateCache: ['stocks_all']);

  // ── EMPLOYÉS ──
  static Future<List> getEmployes({String? fermeId}) =>
      _getList('$API_URL/employes/${fermeId != null ? '?ferme_id=$fermeId' : ''}',
          cacheKey: 'employes_${fermeId ?? 'all'}');

  static Future<bool> createEmploye(Map<String, dynamic> data) =>
      _post('$API_URL/employes/', data, invalidateCache: ['employes_all']);

  static Future<bool> updateEmploye(String id, Map<String, dynamic> data) =>
      _put('$API_URL/employes/$id', data, invalidateCache: ['employes_all']);

  static Future<bool> deleteEmploye(String id) =>
      _delete('$API_URL/employes/$id', invalidateCache: ['employes_all']);

  // ── FERMES ──
  static Future<List> getFermes() =>
      _getList('$API_URL/fermes/', cacheKey: 'fermes_all');

  static Future<bool> createFerme(Map<String, dynamic> data) =>
      _post('$API_URL/fermes/', data, invalidateCache: ['fermes_all']);

  static Future<bool> updateFerme(String id, Map<String, dynamic> data) =>
      _put('$API_URL/fermes/$id', data, invalidateCache: ['fermes_all']);

  static Future<bool> deleteFerme(String id) =>
      _delete('$API_URL/fermes/$id', invalidateCache: ['fermes_all']);

  // ── ALERTES ──
  static Future<List> getAlertes() =>
      _getList('$API_URL/dashboard/alertes', useCache: false);

  // ── AUTH ──
  static Future<Map<String, dynamic>> getMe() =>
      _getMap('$API_URL/auth/me');

  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> data) async {
    try {
      final r = await http.post(Uri.parse('$API_URL/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data)).timeout(_timeout);
      return {
        'status': r.statusCode,
        'body': jsonDecode(utf8.decode(r.bodyBytes))
      };
    } catch (e) { _log('register: $e'); }
    return {'status': 500, 'body': {}};
  }

  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> data) async {
    try {
      final r = await http.put(Uri.parse('$API_URL/auth/me'),
          headers: SessionManager.headers,
          body: jsonEncode(data)).timeout(_timeout);
      return {
        'status': r.statusCode,
        'body': jsonDecode(utf8.decode(r.bodyBytes))
      };
    } catch (e) { _log('updateProfile: $e'); }
    return {'status': 500, 'body': {}};
  }

  static Future<bool> changePassword(
      String oldPass, String newPass) async {
    return _post('$API_URL/auth/change-password', {
      'old_password': oldPass,
      'new_password': newPass,
    });
  }

  // ── DASHBOARD ──
  static Future<Map<String, dynamic>> getDashboardStats() =>
      _getMap('$API_URL/dashboard/stats', useCache: false);

  // ── MÉTÉO ──
  static Future<Map<String, dynamic>> getMeteo(String ville) async {
    final cacheKey = 'meteo_$ville';
    if (_cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (!entry.isExpired) {
        _log('Cache météo: $ville');
        return entry.data as Map<String, dynamic>;
      }
    }
    try {
      final r = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather'
              '?q=$ville,SN&appid=$WEATHER_KEY&units=metric&lang=fr'))
          .timeout(_timeout);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        _cache[cacheKey] = _CacheEntry(data,
            duration: const Duration(minutes: 30));
        return data;
      }
    } catch (e) { _log('getMeteo $ville: $e'); }
    return {};
  }

  // ── RAPPORTS ──
  static Future<List> getRapports() =>
      _getList('$API_URL/rapports/', useCache: false);

  // ── TEST CONNEXION ──
  static Future<bool> testConnection() async {
    try {
      final r = await http.get(Uri.parse('$API_URL/health'),
          headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) { return false; }
  }

  // ── Stats cache ──
  static Map<String, dynamic> getCacheStats() => {
    'entries': _cache.length,
    'keys': _cache.keys.toList(),
    'expired': _cache.values.where((e) => e.isExpired).length,
  };
}

// ── Entrée cache ──
class _CacheEntry {
  final dynamic data;
  final DateTime createdAt;
  final Duration duration;

  _CacheEntry(this.data,
      {this.duration = const Duration(minutes: 2)})
      : createdAt = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(createdAt) > duration;
}