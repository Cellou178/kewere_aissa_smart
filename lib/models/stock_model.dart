class StockModel {
  final int id;
  final String produit;
  final double quantite;
  final String unite;
  final double seuilAlerte;
  final int fermeId;

  StockModel({
    required this.id,
    required this.produit,
    required this.quantite,
    required this.unite,
    required this.seuilAlerte,
    required this.fermeId,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) => StockModel(
    id: json['id'],
    produit: json['produit'],
    quantite: (json['quantite'] as num).toDouble(),
    unite: json['unite'],
    seuilAlerte: (json['seuil_alerte'] as num).toDouble(),
    fermeId: json['ferme_id'],
  );

  Map<String, dynamic> toJson() => {
    'produit': produit,
    'quantite': quantite,
    'unite': unite,
    'seuil_alerte': seuilAlerte,
    'ferme_id': fermeId,
  };
}