import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_universe.dart';
import '../../data/models/current_user.dart';

/// Message affiché à un professionnel ou administrateur qui se connecte sur l'app mobile.
const professionalAccountMessage =
    "L'application mobile est réservée aux particuliers. "
    "Les professionnels et administrateurs utilisent l'espace web PsyAvocat.";

/// Détermine la page à ouvrir après une connexion (ou une session restaurée),
/// à partir du rôle RÉEL renvoyé par `GET /me`.
///
/// - professionnel / administrateur → refus ([AuthException]) ;
/// - pas encore de profil métier → choix de l'univers (le profil y est créé) ;
/// - univers déjà choisi lors d'une session précédente → accueil ;
/// - sinon → choix de l'univers.
String resolvePostAuthRoute({
  required CurrentUser user,
  required AppUniverse? savedUniverse,
}) {
  if (user.isProfessionalOrAdmin) {
    throw const AuthException(professionalAccountMessage);
  }
  if (!user.hasMetierProfile) return '/selection-univers';
  if (savedUniverse != null && !savedUniverse.isNeutral) return '/home';
  return '/selection-univers';
}
