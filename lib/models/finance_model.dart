class FinanceModel {
  final int id;
  final String type; // 'depense' ou 'revenu'
  final double montant;
  final String categorie;
  final String date;
  final String? description;
  final int fermeId;

  FinanceModel({
    required this.id,
    required this.type,
    required this.montant,
    required this.categorie,
    required this.date,
    this.description,
    required this.fermeId,
  });

  factory FinanceModel.fromJson(Map<String, dynamic> json) => FinanceModel(
    id: json['id'],
    type: json['type'],
    montant: (json['montant'] as num).toDouble(),
    categorie: json['categorie'],
    date: json['date'],
    description: json['description'],
    fermeId: json['ferme_id'],
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'montant': montant,
    'categorie': categorie,
    'date': date,
    'description': description,
    'ferme_id': fermeId,
  };
}