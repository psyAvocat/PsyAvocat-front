import '../../data/models/current_user.dart';

/// Message affiché à un professionnel ou administrateur qui se connecte sur l'app mobile.
const professionalAccountMessage =
    "L'application mobile est réservée aux particuliers. "
    "Les professionnels et administrateurs utilisent l'espace web PsyAvocat.";

/// Message affiché à un compte désactivé par l'administration.
const deactivatedAccountMessage =
    "Votre compte a été désactivé. Contactez le support PsyAvocat pour plus d'informations.";

/// Verdict d'accès à l'app mobile, calculé UNIQUEMENT à partir de `GET /me`.
enum AccessDecision {
  /// Client avec profil métier : accès autorisé.
  authorized,

  /// Compte Firebase sans profil métier : le profil doit être complété.
  profileIncomplete,

  /// Professionnel ou administrateur : refusé sur le mobile.
  deniedProfessional,

  /// Compte désactivé : refusé.
  deniedDeactivated,
}

/// Règle unique d'accès à l'application mobile.
AccessDecision evaluateAccess(CurrentUser user) {
  if (!user.actif) return AccessDecision.deniedDeactivated;
  if (user.isProfessionalOrAdmin) return AccessDecision.deniedProfessional;
  if (!user.hasMetierProfile) return AccessDecision.profileIncomplete;
  return user.isClient
      ? AccessDecision.authorized
      // Rôle inconnu : on refuse plutôt que d'autoriser par défaut.
      : AccessDecision.deniedProfessional;
}
