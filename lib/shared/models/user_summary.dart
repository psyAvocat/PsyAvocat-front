import '../enums/user_role.dart';

/// Résumé d'utilisateur partagé entre les différentes fonctionnalités.
class UserSummary {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final UserRole role;

  const UserSummary({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    required this.role,
  });

  String get fullName => '$prenom $nom'.trim();

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      email: json['email'] as String? ?? '',
      telephone: json['telephone'] as String?,
      role: UserRole.fromCode(json['role'] as String? ?? json['type'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'role': role.code,
    };
  }
}
