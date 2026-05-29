import '../models/finance_model.dart';
import 'api_service.dart';

class FinanceService {
  static final FinanceService _instance = FinanceService._internal();
  factory FinanceService() => _instance;
  FinanceService._internal();

  final ApiService _api = ApiService();

  Future<List<FinanceModel>> getFinances({int? fermeId}) async {
    final query = fermeId != null ? '?ferme_id=$fermeId' : '';
    final data = await _api.get('/finances$query');
    return (data as List).map((e) => FinanceModel.fromJson(e)).toList();
  }

  Future<FinanceModel> createFinance(Map<String, dynamic> body) async {
    final data = await _api.post('/finances', body);
    return FinanceModel.fromJson(data);
  }

  Future<FinanceModel> updateFinance(int id, Map<String, dynamic> body) async {
    final data = await _api.put('/finances/$id', body);
    return FinanceModel.fromJson(data);
  }

  Future<void> deleteFinance(int id) async {
    await _api.delete('/finances/$id');
  }

  Future<Map<String, dynamic>> getResume({int? fermeId}) async {
    final query = fermeId != null ? '?ferme_id=$fermeId' : '';
    return await _api.get('/finances/resume$query');
  }
}