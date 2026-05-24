Future<void> _login() async {
  if (!_isValid()) return;
  setState(() { _loading = true; _error = ''; });
  try {
    // Encoder manuellement le body
    final body = 'username=${Uri.encodeComponent(_loginCtrl.text.trim())}&password=${Uri.encodeComponent(_passCtrl.text.trim())}';

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
    print('Login error: $e');
    setState(() => _error = 'Erreur: ${e.toString().substring(0, 50)}');
    _shakeCtrl.forward(from: 0);
  }
  setState(() => _loading = false);
}
