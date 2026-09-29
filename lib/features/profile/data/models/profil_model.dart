/// Modèle représentant le profil utilisateur dans PsyAvocat.
class ProfilModel {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String? ville;
  final String role; // JUSTICIABLE | PATIENT | AVOCAT | PSYCHOLOGUE
  final bool profileComplet;

  const ProfilModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    this.ville,
    required this.role,
    this.profileComplet = false,
  });

  String get displayName => '$prenom $nom'.trim();

  String get roleLabel {
    switch (role) {
      case 'JUSTICIABLE':
        return 'Client juridique';
      case 'PATIENT':
        return 'Patient';
      case 'AVOCAT':
        return 'Avocat';
      case 'PSYCHOLOGUE':
        return 'Psychologue';
      default:
        return role;
    }
  }

  bool get isPatient => role == 'PATIENT';
  bool get isJusticiable => role == 'JUSTICIABLE';

  factory ProfilModel.fromJson(Map<String, dynamic> json) {
    return ProfilModel(
      id: json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      email: json['email'] as String? ?? '',
      telephone: json['telephone'] as String?,
      ville: json['ville'] as String?,
      role: json['role'] as String? ?? 'JUSTICIABLE',
      profileComplet: json['profileComplet'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      if (telephone != null) 'telephone': telephone,
      if (ville != null) 'ville': ville,
      'role': role,
      'profileComplet': profileComplet,
    };
  }

  ProfilModel copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? ville,
    String? role,
    bool? profileComplet,
  }) {
    return ProfilModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      ville: ville ?? this.ville,
      role: role ?? this.role,
      profileComplet: profileComplet ?? this.profileComplet,
    );
  }
}
