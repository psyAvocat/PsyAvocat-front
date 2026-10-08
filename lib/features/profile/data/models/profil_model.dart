/// Profil de l'utilisateur connecté, tel que renvoyé par `GET /api/profil`
/// (UserProfileResponse côté Spring Boot).
class ProfilModel {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;

  /// CLIENT, PATIENT, JUSTICIABLE, AVOCAT, PSYCHOLOGUE ou ADMINISTRATEUR.
  final String typeUtilisateur;
  final DateTime? dateInscription;

  /// URL d'affichage temporaire (bucket privé) générée par le backend.
  final String? photoUrl;

  const ProfilModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.typeUtilisateur,
    this.telephone,
    this.dateInscription,
    this.photoUrl,
  });

  factory ProfilModel.fromJson(Map<String, dynamic> json) {
    return ProfilModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      email: json['email'] as String? ?? '',
      telephone: json['telephone'] as String?,
      typeUtilisateur: json['typeUtilisateur'] as String? ?? '',
      dateInscription: DateTime.tryParse(json['dateInscription'] as String? ?? ''),
      photoUrl: json['photoUrl'] as String?,
    );
  }

  String get nomComplet => '$prenom $nom'.trim();
}
