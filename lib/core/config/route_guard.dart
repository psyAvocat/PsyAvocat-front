import '../../features/auth/presentation/controllers/session_controller.dart';
import '../theme/app_universe.dart';
import 'app_routes.dart';

/// Routes accessibles sans session (connexion, inscription, mot de passe oublié).
const _authRoutes = {AppRoutes.login, AppRoutes.register, AppRoutes.forgotPassword};

/// Décide où envoyer l'utilisateur avant d'afficher [location].
/// Renvoie `null` si l'accès est autorisé, sinon la route de redirection.
///
/// Seule source de décision de navigation (GoRouter `redirect`) :
/// connaître une URL ne donne jamais accès à l'écran correspondant.
String? computeRedirect({
  required String location,
  required SessionState session,
  required bool onboardingCompleted,
  required bool splashDone,
  required AppUniverse universe,
}) {
  // 1. Le splash reste affiché jusqu'à la fin de son animation.
  if (!splashDone) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  switch (session.status) {
    case SessionStatus.unknown:
    case SessionStatus.loading:
      // Identité en cours de chargement : on reste sur l'écran de connexion
      // (bouton en chargement) ou on attend sur le splash.
      if (location == AppRoutes.splash ||
          _authRoutes.contains(location) ||
          location == AppRoutes.completeProfile) {
        return null;
      }
      return AppRoutes.splash;

    case SessionStatus.error:
      // `/me` injoignable : le splash propose de réessayer. Aucun accès accordé.
      return location == AppRoutes.splash ? null : AppRoutes.splash;

    case SessionStatus.unauthenticated:
    case SessionStatus.denied:
      if (!onboardingCompleted) {
        return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }
      return _authRoutes.contains(location) ? null : AppRoutes.login;

    case SessionStatus.profileIncomplete:
      return location == AppRoutes.completeProfile ? null : AppRoutes.completeProfile;

    case SessionStatus.authorized:
      // Premier choix d'univers obligatoire.
      if (universe.isNeutral) {
        return location == AppRoutes.universeSelection ? null : AppRoutes.universeSelection;
      }
      if (location == AppRoutes.splash ||
          location == AppRoutes.onboarding ||
          location == AppRoutes.completeProfile ||
          location == AppRoutes.universeSelection ||
          _authRoutes.contains(location)) {
        return AppRoutes.home;
      }
      // Le questionnaire d'orientation n'existe que dans l'univers Psychologue.
      if (location.startsWith(AppRoutes.orientation) && !universe.isPsychologist) {
        return AppRoutes.home;
      }
      return null;
  }
}
