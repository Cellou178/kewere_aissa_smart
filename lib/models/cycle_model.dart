class CycleModel {
  final int id;
  final String nom;
  final String dateDebut;
  final String? dateFin;
  final String statut;
  final int fermeId;

  CycleModel({
    required this.id,
    required this.nom,
    required this.dateDebut,
    this.dateFin,
    required this.statut,
    required this.fermeId,
  });

  factory CycleModel.fromJson(Map<String, dynamic> json) => CycleModel(
    id: json['id'],
    nom: json['nom'],
    dateDebut: json['date_debut'],
    dateFin: json['date_fin'],
    statut: json['statut'],
    fermeId: json['ferme_id'],
  );

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'date_debut': dateDebut,
    'date_fin': dateFin,
    'statut': statut,
    'ferme_id': fermeId,
  };
}