import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../managers/session_manager.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // Étape 1 : login
    final loginResponse = await http.post(
      Uri.parse('$API_URL/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'username=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}',
    ).timeout(const Duration(seconds: 60));

    if (loginResponse.statusCode != 200) {
      final body = jsonDecode(utf8.decode(loginResponse.bodyBytes));
      throw Exception(body['detail'] ?? 'Email ou mot de passe incorrect');
    }

    final loginData = jsonDecode(utf8.decode(loginResponse.bodyBytes));
    final token = loginData['access_token'];

    // Étape 2 : récupérer le profil
    final meResponse = await http.get(
      Uri.parse('$API_URL/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 60));

    if (meResponse.statusCode != 200) {
      throw Exception('Impossible de récupérer le profil');
    }

    final userData = jsonDecode(utf8.decode(meResponse.bodyBytes));

    // Étape 3 : sauvegarder la session
    await SessionManager.save(
      token: token,
      role: userData['role'] ?? '',
      nom: userData['nom'] ?? '',
      email: userData['email'] ?? '',
      entrepriseId: userData['entreprise_id'] ?? '',
      fermeId: userData['ferme_id'] ?? '',
    );

    return UserModel.fromJson(userData);
  }

  Future<UserModel> register({
    required String nom,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$API_URL/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nom': nom,
        'email': email,
        'mot_de_passe': password,
      }),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 201) {
      return await login(email: email, password: password);
    } else {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['detail'] ?? 'Erreur lors de l\'inscription');
    }
  }

  Future<void> logout() async {
    await SessionManager.clear();
  }

  Future<UserModel> getProfile() async {
    final meResponse = await http.get(
      Uri.parse('$API_URL/auth/me'),
      headers: {
        'Authorization': 'Bearer ${SessionManager.token}',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 60));

    if (meResponse.statusCode == 200) {
      final userData = jsonDecode(utf8.decode(meResponse.bodyBytes));
      return UserModel.fromJson(userData);
    } else {
      throw Exception('Impossible de récupérer le profil');
    }
  }
}