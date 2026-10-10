import '../../features/auth/presentation/controllers/session_controller.dart';
import '../theme/app_universe.dart';
import 'app_routes.dart';

/// Règle de navigation UNIQUE de l'application (`redirect` de GoRouter).
///
/// Une règle par état de session :
///
/// | Session                      | Écran                                   |
/// |------------------------------|-----------------------------------------|
/// | vérification / erreur `/me`  | splash (chargement ou « Réessayer »)    |
/// | non connecté                 | onboarding (1re fois), puis connexion   |
/// | refusé                       | accès refusé                            |
/// | profil absent                | compléter le profil                     |
/// | email non confirmé           | confirmation de l'email                 |
/// | autorisé, univers non choisi | choix de l'univers                      |
/// | autorisé, univers choisi     | écran demandé (accueil par défaut)      |
///
/// Renvoie la route vers laquelle rediriger, ou `null` pour laisser passer.
/// Connaître une URL ne donne jamais accès à un écran : tout passe par ici.
String? resolveRedirect({
  required String location,
  required SessionStatus session,
  required bool hasSeenOnboarding,
  required AppUniverse universe,
}) {
  switch (session) {
    case SessionStatus.unknown:
    case SessionStatus.loading:
    case SessionStatus.error:
      return _stayOn(AppRoutes.splash, location);
    case SessionStatus.denied:
      return _stayOn(AppRoutes.accessDenied, location);
    case SessionStatus.profileIncomplete:
      return _stayOn(AppRoutes.completeProfile, location);
    case SessionStatus.emailNotVerified:
      return _stayOn(AppRoutes.verifyEmail, location);
    case SessionStatus.unauthenticated:
      return _unauthenticated(location, hasSeenOnboarding);
    case SessionStatus.authorized:
      return _authorized(location, universe);
  }
}

/// Un seul écran possible : y rester, sinon y aller.
String? _stayOn(String target, String location) =>
    location == target ? null : target;

String? _unauthenticated(String location, bool hasSeenOnboarding) {
  // L'onboarding n'est montré qu'une seule fois.
  if (location == AppRoutes.onboarding && hasSeenOnboarding) {
    return AppRoutes.login;
  }
  if (AppRoutes.publicRoutes.contains(location)) return null;
  return hasSeenOnboarding ? AppRoutes.login : AppRoutes.onboarding;
}

String? _authorized(String location, AppUniverse universe) {
  if (universe.isNeutral) return _stayOn(AppRoutes.universeSelection, location);

  // Écrans d'entrée ou de session : plus rien à y faire, direction l'accueil.
  if (AppRoutes.entryRoutes.contains(location)) return AppRoutes.home;

  // L'orientation (questionnaire) n'existe que dans l'univers Psychologue.
  if (universe.isLawyer && location.startsWith(AppRoutes.orientation)) {
    return AppRoutes.home;
  }

  // Les contenus suivent l'univers : articles (Avocat) / conseils (Psychologue).
  if (universe.isLawyer && location == AppRoutes.conseils) {
    return AppRoutes.articles;
  }
  if (universe.isPsychologist && location == AppRoutes.articles) {
    return AppRoutes.conseils;
  }
  return null;
}
