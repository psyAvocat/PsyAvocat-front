import '../../features/auth/presentation/controllers/session_controller.dart';
import '../theme/app_universe.dart';
import 'app_routes.dart';

/// Règle de navigation UNIQUE de l'application (`redirect` de GoRouter).
///
/// Parcours : splash (ouverture de l'app, une seule fois) → onboarding (1re fois)
/// → connexion / inscription (obligatoires) → choix de l'univers → accueil.
/// Une fois connecté, toutes les fonctionnalités sont accessibles.
///
/// | Situation                                   | Écran                                |
/// |---------------------------------------------|--------------------------------------|
/// | ouverture de l'app, session en vérification | splash (« Réessayer » si erreur)     |
/// | vérification après connexion                | l'écran courant reste affiché        |
/// | non connecté, 1re ouverture                 | onboarding                           |
/// | non connecté                                | connexion (inscription accessible)   |
/// | refusé                                      | accès refusé                         |
/// | profil absent                               | compléter le profil                  |
/// | connecté, univers non choisi                | choix de l'univers                   |
/// | connecté, univers choisi                    | écran demandé (accueil par défaut)   |
///
/// Renvoie la route vers laquelle rediriger, ou `null` pour laisser passer.
/// Connaître une URL ne donne jamais accès à un écran : tout passe par ici.
String? resolveRedirect({
  required String location,
  required SessionStatus session,
  required bool hasSeenOnboarding,
  required AppUniverse universe,
  bool splashDone = true,
}) {
  // Ouverture de l'app : le splash reste affiché sa durée minimale, puis tant
  // que la session restaurée se vérifie (ou pour proposer « Réessayer »).
  if (location == AppRoutes.splash) {
    if (!splashDone) return null;
    if (session == SessionStatus.unknown ||
        session == SessionStatus.loading ||
        session == SessionStatus.error) {
      return null;
    }
  }

  switch (session) {
    case SessionStatus.unknown:
    case SessionStatus.loading:
    case SessionStatus.error:
      // Vérification en cours ou échouée après une connexion : l'écran courant
      // (connexion, inscription) reste affiché et montre l'état ou l'erreur.
      if (AppRoutes.authRoutes.contains(location)) return null;
      return location == AppRoutes.splash ? null : AppRoutes.login;
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
  // L'onboarding n'est montré qu'à la première ouverture.
  if (!hasSeenOnboarding) return _stayOn(AppRoutes.onboarding, location);
  // Connexion, inscription et mot de passe oublié : seuls écrans accessibles.
  if (AppRoutes.authRoutes.contains(location)) return null;
  return AppRoutes.login;
}

String? _authorized(String location, AppUniverse universe) {
  // Après la connexion : choix de l'univers.
  if (universe.isNeutral) return _stayOn(AppRoutes.universeSelection, location);

  // Écrans d'entrée ou de session : plus rien à y faire, direction l'accueil.
  if (AppRoutes.entryRoutes.contains(location)) return AppRoutes.home;

  // L'orientation (questionnaire) n'existe que dans l'univers Psychologue.
  if (universe.isLawyer && location.startsWith(AppRoutes.orientation)) {
    return AppRoutes.home;
  }

  // Les dossiers juridiques n'existent que dans l'univers Avocat.
  if (universe.isPsychologist && location.startsWith(AppRoutes.dossiers)) {
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
