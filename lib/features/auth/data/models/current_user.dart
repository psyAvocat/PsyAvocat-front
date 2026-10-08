/// Utilisateur connecté, tel que retourné par Spring Boot (`GET /me`).
///
/// Les rôles viennent exclusivement du backend (MySQL) :
/// ils ne sont jamais déduits de l'email ou d'une donnée locale.
class CurrentUser {
  final String? userId;
  final String email;
  final String? nom;
  final String? prenom;
  final List<String> roles;
  final bool hasMetierProfile;

  const CurrentUser({
    required this.userId,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.roles,
    required this.hasMetierProfile,
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      userId: json['userId']?.toString(),
      email: json['email'] as String? ?? '',
      nom: json['nom'] as String?,
      prenom: json['prenom'] as String?,
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((r) => r.toString())
          .toList(),
      hasMetierProfile: json['hasMetierProfile'] as bool? ?? false,
    );
  }

  /// Patient (psychologie) ou justiciable (droit) : utilisateur de l'app mobile.
  bool get isClient =>
      roles.contains('ROLE_PATIENT') || roles.contains('ROLE_JUSTICIABLE');

  /// Avocat, psychologue ou administrateur : ils utilisent l'espace web.
  bool get isProfessionalOrAdmin =>
      roles.contains('ROLE_PROFESSIONNEL') ||
      roles.contains('ROLE_ADMINISTRATEUR');
}
