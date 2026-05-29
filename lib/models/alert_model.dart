class AlertModel {
  final int id;
  final String message;
  final String type; // 'stock', 'cycle', 'finance'
  final bool lue;
  final String date;
  final int fermeId;

  AlertModel({
    required this.id,
    required this.message,
    required this.type,
    required this.lue,
    required this.date,
    required this.fermeId,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
    id: json['id'],
    message: json['message'],
    type: json['type'],
    lue: json['lue'] ?? false,
    date: json['date'],
    fermeId: json['ferme_id'],
  );

  Map<String, dynamic> toJson() => {
    'message': message,
    'type': type,
    'lue': lue,
    'date': date,
    'ferme_id': fermeId,
  };
}