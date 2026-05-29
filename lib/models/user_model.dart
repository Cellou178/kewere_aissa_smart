class UserModel {
  final int id;
  final String nom;
  final String email;
  final String role;
  final String token;

  UserModel({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    nom: json['nom'],
    email: json['email'],
    role: json['role'],
    token: json['token'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'email': email,
    'role': role,
  };
}