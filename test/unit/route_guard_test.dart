import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/core/router/app_routes.dart';
import 'package:psyavocat_front/core/router/route_guard.dart';
import 'package:psyavocat_front/core/theme/app_universe.dart';
import 'package:psyavocat_front/features/auth/presentation/controllers/session_controller.dart';

/// Raccourci : redirection calculée pour une situation donnée.
String? redirect(
  String location, {
  required SessionStatus session,
  bool hasSeenOnboarding = true,
  AppUniverse universe = AppUniverse.neutral,
}) {
  return resolveRedirect(
    location: location,
    session: session,
    hasSeenOnboarding: hasSeenOnboarding,
    universe: universe,
  );
}

void main() {
  group('Session en cours de vérification', () {
    test('chargement ou erreur /me : splash, même avec un univers', () {
      for (final status in [SessionStatus.loading, SessionStatus.error]) {
        expect(redirect(AppRoutes.splash, session: status), isNull);
        expect(
          redirect(
            AppRoutes.home,
            session: status,
            universe: AppUniverse.lawyer,
          ),
          AppRoutes.splash,
        );
      }
    });
  });

  group('Non connecté', () {
    test('premier lancement : onboarding', () {
      expect(
        redirect(
          AppRoutes.splash,
          session: SessionStatus.unauthenticated,
          hasSeenOnboarding: false,
        ),
        AppRoutes.onboarding,
      );
    });

    test('onboarding déjà vu : connexion, l’onboarding n’est plus montré', () {
      expect(
        redirect(AppRoutes.splash, session: SessionStatus.unauthenticated),
        AppRoutes.login,
      );
      expect(
        redirect(AppRoutes.onboarding, session: SessionStatus.unauthenticated),
        AppRoutes.login,
      );
    });

    test('écrans publics accessibles, écrans privés refusés', () {
      for (final route in [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ]) {
        expect(redirect(route, session: SessionStatus.unauthenticated), isNull);
      }
      expect(
        redirect(AppRoutes.home, session: SessionStatus.unauthenticated),
        AppRoutes.login,
      );
    });
  });

  group('Statut du compte renvoyé par /me', () {
    test('refusé : accès refusé', () {
      expect(
        redirect(AppRoutes.home, session: SessionStatus.denied),
        AppRoutes.accessDenied,
      );
      expect(
        redirect(AppRoutes.accessDenied, session: SessionStatus.denied),
        isNull,
      );
    });

    test('profil absent : compléter le profil', () {
      expect(
        redirect(
          AppRoutes.universeSelection,
          session: SessionStatus.profileIncomplete,
        ),
        AppRoutes.completeProfile,
      );
      expect(
        redirect(
          AppRoutes.completeProfile,
          session: SessionStatus.profileIncomplete,
        ),
        isNull,
      );
    });

    test('email non confirmé : confirmation, même avec un univers', () {
      expect(
        redirect(
          AppRoutes.home,
          session: SessionStatus.emailNotVerified,
          universe: AppUniverse.psychologist,
        ),
        AppRoutes.verifyEmail,
      );
      expect(
        redirect(
          AppRoutes.verifyEmail,
          session: SessionStatus.emailNotVerified,
        ),
        isNull,
      );
    });
  });

  group('Client autorisé', () {
    test('univers pas encore choisi : choix de l’univers obligatoire', () {
      expect(
        redirect(AppRoutes.splash, session: SessionStatus.authorized),
        AppRoutes.universeSelection,
      );
      expect(
        redirect(AppRoutes.home, session: SessionStatus.authorized),
        AppRoutes.universeSelection,
      );
    });

    test('univers choisi : écrans d’entrée → accueil', () {
      for (final route in AppRoutes.entryRoutes) {
        expect(
          redirect(
            route,
            session: SessionStatus.authorized,
            universe: AppUniverse.lawyer,
          ),
          AppRoutes.home,
          reason: route,
        );
      }
    });

    test('univers choisi : les écrans de l’app restent accessibles', () {
      expect(
        redirect(
          AppRoutes.rendezVous,
          session: SessionStatus.authorized,
          universe: AppUniverse.psychologist,
        ),
        isNull,
      );
    });

    test('orientation réservée à l’univers Psychologue', () {
      expect(
        redirect(
          AppRoutes.orientationIntro,
          session: SessionStatus.authorized,
          universe: AppUniverse.lawyer,
        ),
        AppRoutes.home,
      );
      expect(
        redirect(
          AppRoutes.orientationIntro,
          session: SessionStatus.authorized,
          universe: AppUniverse.psychologist,
        ),
        isNull,
      );
    });

    test(
      'contenus de l’univers : articles (Avocat) / conseils (Psychologue)',
      () {
        expect(
          redirect(
            AppRoutes.conseils,
            session: SessionStatus.authorized,
            universe: AppUniverse.lawyer,
          ),
          AppRoutes.articles,
        );
        expect(
          redirect(
            AppRoutes.articles,
            session: SessionStatus.authorized,
            universe: AppUniverse.psychologist,
          ),
          AppRoutes.conseils,
        );
      },
    );
  });
}
