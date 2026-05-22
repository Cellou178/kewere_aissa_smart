import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../managers/session_manager.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 15);

  static Future<List> getCycles() async {
    try {
      final r = await http.get(Uri.parse('$API_URL/cycles/'),
          headers: SessionManager.headers).timeout(_timeout);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data is Map && data.containsKey('items')) return data['items'];
        return data;
      }
    } catch (e) { debugPrint('getCycles: $e'); }
    return [];
  }

  static Future<List> getDonnees({String? cycleId}) async {
    try {
      String url = '$API_URL/donnees/';
      if (cycleId != null) url += '?cycle_id=$cycleId';
      final r = await http.get(Uri.parse(url),
          headers: SessionManager.headers).timeout(_timeout);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data is Map && data.containsKey('items')) return data['items'];
        return data;
      }
    } catch (e) { debugPrint('getDonnees: $e'); }
    return [];
  }

  static Future<List> getStocks() async {
    try {
      final r = await http.get(Uri.parse('$API_URL/stocks/'),
          headers: SessionManager.headers).timeout(_timeout);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data is Map && data.containsKey('items')) return data['items'];
        return data;
      }
    } catch (e) { debugPrint('getStocks: $e'); }
    return [];
  }

  static Future<List> getEmployes() async {
    try {
      final r = await http.get(Uri.parse('$API_URL/employes/'),
          headers: SessionManager.headers).timeout(_timeout);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data is Map && data.containsKey('items')) return data['items'];
        return data;
      }
    } catch (e) { debugPrint('getEmployes: $e'); }
    return [];
  }

  static Future<List> getAlertes() async {
    try {
      final r = await http.get(Uri.parse('$API_URL/dashboard/alertes'),
          headers: SessionManager.headers).timeout(_timeout);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data is Map && data.containsKey('items')) return data['items'];
        return data;
      }
    } catch (e) { debugPrint('getAlertes: $e'); }
    return [];
  }

  static Future<Map<String, dynamic>> getMeteo(String ville) async {
    try {
      final r = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$ville,SN&appid=$WEATHER_KEY&units=metric&lang=fr'
      )).timeout(_timeout);
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) { debugPrint('getMeteo: $e'); }
    return {};
  }

  static Future<Map<String, dynamic>> getMe() async {
    try {
      final r = await http.get(Uri.parse('$API_URL/auth/me'),
          headers: SessionManager.headers).timeout(_timeout);
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) { debugPrint('getMe: $e'); }
    return {};
  }

  static Future<bool> createDonnee(Map<String, dynamic> data) async {
    try {
      final r = await http.post(Uri.parse('$API_URL/donnees/'),
          headers: SessionManager.headers, body: jsonEncode(data)).timeout(_timeout);
      return r.statusCode == 201 || r.statusCode == 200;
    } catch (e) { debugPrint('createDonnee: $e'); }
    return false;
  }

  static Future<bool> createCycle(Map<String, dynamic> data) async {
    try {
      final r = await http.post(Uri.parse('$API_URL/cycles/'),
          headers: SessionManager.headers, body: jsonEncode(data)).timeout(_timeout);
      return r.statusCode == 201 || r.statusCode == 200;
    } catch (e) { debugPrint('createCycle: $e'); }
    return false;
  }

  static Future<bool> createStock(Map<String, dynamic> data) async {
    try {
      final r = await http.post(Uri.parse('$API_URL/stocks/'),
          headers: SessionManager.headers, body: jsonEncode(data)).timeout(_timeout);
      return r.statusCode == 201 || r.statusCode == 200;
    } catch (e) { debugPrint('createStock: $e'); }
    return false;
  }

  static Future<bool> createEmploye(Map<String, dynamic> data) async {
    try {
      final r = await http.post(Uri.parse('$API_URL/employes/'),
          headers: SessionManager.headers, body: jsonEncode(data)).timeout(_timeout);
      return r.statusCode == 201 || r.statusCode == 200;
    } catch (e) { debugPrint('createEmploye: $e'); }
    return false;
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final r = await http.post(Uri.parse('$API_URL/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data)).timeout(_timeout);
      return {'status': r.statusCode, 'body': jsonDecode(r.body)};
    } catch (e) { debugPrint('register: $e'); }
    return {'status': 500, 'body': {}};
  }
}