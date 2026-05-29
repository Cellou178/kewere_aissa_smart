class FermeModel {
  final int id;
  final String nom;
  final String localisation;
  final String type;
  final int proprietaireId;

  FermeModel({
    required this.id,
    required this.nom,
    required this.localisation,
    required this.type,
    required this.proprietaireId,
  });

  factory FermeModel.fromJson(Map<String, dynamic> json) => FermeModel(
    id: json['id'],
    nom: json['nom'],
    localisation: json['localisation'],
    type: json['type'],
    proprietaireId: json['proprietaire_id'],
  );

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'localisation': localisation,
    'type': type,
    'proprietaire_id': proprietaireId,
  };
}