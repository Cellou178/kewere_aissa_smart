import 'api_service.dart';

class DashboardStats {
  final int totalFermes;
  final int cyclesEnCours;
  final int alertesNonLues;
  final double revenusTotal;
  final double depensesTotal;
  final double solde;
  final List<Map<String, dynamic>> activiteRecente;

  const DashboardStats({
    required this.totalFermes,
    required this.cyclesEnCours,
    required this.alertesNonLues,
    required this.revenusTotal,
    required this.depensesTotal,
    required this.solde,
    required this.activiteRecente,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalFermes: json['total_fermes'] ?? 0,
    cyclesEnCours: json['cycles_en_cours'] ?? 0,
    alertesNonLues: json['alertes_non_lues'] ?? 0,
    revenusTotal: (json['revenus_total'] as num?)?.toDouble() ?? 0.0,
    depensesTotal: (json['depenses_total'] as num?)?.toDouble() ?? 0.0,
    solde: (json['solde'] as num?)?.toDouble() ?? 0.0,
    activiteRecente: List<Map<String, dynamic>>.from(json['activite_recente'] ?? []),
  );
}

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final ApiService _api = ApiService();

  Future<DashboardStats> getStats() async {
    final data = await _api.get('/dashboard/stats');
    return DashboardStats.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> getGraphiqueFinances({
    required String periode, // 'semaine', 'mois', 'annee'
  }) async {
    final data = await _api.get('/dashboard/graphiques?periode=$periode');
    return List<Map<String, dynamic>>.from(data);
  }
}