import '../models/alert_model.dart';
import 'api_service.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  final ApiService _api = ApiService();

  Future<List<AlertModel>> getAlertes({bool? nonLues}) async {
    final query = nonLues == true ? '?lue=false' : '';
    final data = await _api.get('/alertes$query');
    return (data as List).map((e) => AlertModel.fromJson(e)).toList();
  }

  Future<void> marquerLue(int id) async {
    await _api.put('/alertes/$id/lue', {});
  }

  Future<void> marquerToutesLues() async {
    await _api.put('/alertes/lues', {});
  }

  Future<void> deleteAlerte(int id) async {
    await _api.delete('/alertes/$id');
  }

  Future<int> getNombreNonLues() async {
    final data = await _api.get('/alertes/count');
    return data['count'] ?? 0;
  }
}