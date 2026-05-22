static Future<List> getCycles() async {
try {
final r = await http.get(Uri.parse('$API_URL/cycles/'),
headers: SessionManager.headers).timeout(_timeout);
if (r.statusCode == 200) {
final data = jsonDecode(r.body);
if (data is Map && data.containsKey('items')) {
return data['items'];
}
return data;
}
} catch (e) { debugPrint('getCycles: $e'); }
return [];
}