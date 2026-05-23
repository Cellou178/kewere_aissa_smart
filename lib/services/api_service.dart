import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../managers/session_manager.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException({required this.statusCode, required this.message});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static const Duration _timeout = Duration(seconds: 15);

  // ── HANDLER CENTRALISÉ ──
  static dynamic _handle(http.Response r) {
    if (r.statusCode == 401) {
      SessionManager.clear();
      throw const ApiException(statusCode: 401, message: 'SESSION_EXPIRED');
    }
    if (r.statusCode == 403) {
      throw const ApiException(statusCode: 403, message: 'ACCES_REFUSE');
    }
    if (r.statusCode == 200 || r.statusCode == 201) {
      final data = jsonDecode(utf8.decode(r.bodyBytes));
      if (data is Map && data.containsKey('items')) return data['items'];
      return data;
    }
    throw ApiException(statusCode: r.statusCode, message: 'Erreur ${r.statusCode}');
  }

  static Future<List> _getList(String url) async {
    try {
      final r = await http.get(Uri.parse(url),
          headers: SessionManager.headers).timeout(_timeout);
      final data = _handle(r);
      return data is List ? data : [];
    } on ApiException { rethrow; }
    catch (e) { debugPrint('GET $url: $e'); }
    return [];
  }

  static Future<Map<String, dynamic>> _getMap(String url) async {
    try {
      final r = await http.get(Uri.parse(url),
          headers: SessionManager.headers).timeout(_timeout);
      final data = _handle(r);
      return data is Map ? Map<String, dynamic>.from(data) : {};
    } on ApiException { rethrow; }
    catch (e) { debugPrint('GET $url: $e'); }
    return {};
  }

  static Future<bool> _post(String url, Map<String, dynamic> body) async {
    try {
      final r = await http.post(Uri.parse(url),
          headers: SessionManager.headers,
          body: jsonEncode(body)).timeout(_timeout);
      if (r.statusCode == 401) {
        SessionManager.clear();
        throw const ApiException(statusCode: 401, message: 'SESSION_EXPIRED');
      }
      return r.statusCode == 200 || r.statusCode == 201;
    } on ApiException { rethrow; }
    catch (e) { debugPrint('POST $url: $e'); }
    return false;
  }

  static Future<bool> _put(String url, Map<String, dynamic> body) async {
    try {
      final r = await http.put(Uri.parse(url),
          headers: SessionManager.headers,
          body: jsonEncode(body)).timeout(_timeout);
      if (r.statusCode == 401) {
        SessionManager.clear();
        throw const ApiException(statusCode: 401, message: 'SESSION_EXPIRED');
      }
      return r.statusCode == 200 || r.statusCode == 201;
    } on ApiException { rethrow; }
    catch (e) { debugPrint('PUT $url: $e'); }
    return false;
  }

  static Future<bool> _delete(String url) async {
    try {
      final r = await http.delete(Uri.parse(url),
          headers: SessionManager.headers).timeout(_timeout);
      if (r.statusCode == 401) {
        SessionManager.clear();
        throw const ApiException(statusCode: 401, message: 'SESSION_EXPIRED');
      }
      return r.statusCode == 200 || r.statusCode == 204;
    } on ApiException { rethrow; }
    catch (e) { debugPrint('DELETE $url: $e'); }
    return false;
  }

  // ── CYCLES ──
  static Future<List> getCycles() => _getList('$API_URL/cycles/');
  static Future<bool> createCycle(Map<String, dynamic> data) => _post('$API_URL/cycles/', data);
  static Future<bool> updateCycle(String id, Map<String, dynamic> data) => _put('$API_URL/cycles/$id', data);
  static Future<bool> deleteCycle(String id) => _delete('$API_URL/cycles/$id');

  // ── DONNÉES ──
  static Future<List> getDonnees({String? cycleId}) =>
      _getList('$API_URL/donnees/${cycleId != null ? '?cycle_id=$cycleId' : ''}');
  static Future<bool> createDonnee(Map<String, dynamic> data) => _post('$API_URL/donnees/', data);

  // ── STOCKS ──
  static Future<List> getStocks() => _getList('$API_URL/stocks/');
  static Future<bool> createStock(Map<String, dynamic> data) => _post('$API_URL/stocks/', data);
  static Future<bool> updateStock(String id, Map<String, dynamic> data) => _put('$API_URL/stocks/$id', data);
  static Future<bool> deleteStock(String id) => _delete('$API_URL/stocks/$id');

  // ── EMPLOYÉS ──
  static Future<List> getEmployes() => _getList('$API_URL/employes/');
  static Future<bool> createEmploye(Map<String, dynamic> data) => _post('$API_URL/employes/', data);
  static Future<bool> updateEmploye(String id, Map<String, dynamic> data) => _put('$API_URL/employes/$id', data);
  static Future<bool> deleteEmploye(String id) => _delete('$API_URL/employes/$id');

  // ── FERMES ──
  static Future<List> getFermes() => _getList('$API_URL/fermes/');
  static Future<bool> createFerme(Map<String, dynamic> data) => _post('$API_URL/fermes/', data);
  static Future<bool> updateFerme(String id, Map<String, dynamic> data) => _put('$API_URL/fermes/$id', data);
  static Future<bool> deleteFerme(String id) => _delete('$API_URL/fermes/$id');

  // ── ALERTES ──
  static Future<List> getAlertes() => _getList('$API_URL/dashboard/alertes');

  // ── AUTH ──
  static Future<Map<String, dynamic>> getMe() => _getMap('$API_URL/auth/me');

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final r = await http.post(Uri.parse('$API_URL/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data)).timeout(_timeout);
      return {'status': r.statusCode, 'body': jsonDecode(r.body)};
    } catch (e) { debugPrint('register: $e'); }
    return {'status': 500, 'body': {}};
  }

  // ── MÉTÉO ──
  static Future<Map<String, dynamic>> getMeteo(String ville) async {
    try {
      final r = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$ville,SN&appid=$WEATHER_KEY&units=metric&lang=fr'
      )).timeout(_timeout);
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) { debugPrint('getMeteo: $e'); }
    return {};
  }
}