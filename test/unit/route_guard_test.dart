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
  bool splashDone = true,
}) {
  return resolveRedirect(
    location: location,
    session: session,
    hasSeenOnboarding: hasSeenOnboarding,
    universe: universe,
    splashDone: splashDone,
  );
}

void main() {
  group('Splash : uniquement à l’ouverture de l’app', () {
    test('affiché pendant sa durée minimale, quelle que soit la session', () {
      for (final status in SessionStatus.values) {
        expect(
          redirect(AppRoutes.splash, session: status, splashDone: false),
          isNull,
          reason: status.name,
        );
      }
    });

    test('reste affiché tant que la session restaurée se vérifie', () {
      for (final status in [SessionStatus.loading, SessionStatus.error]) {
        expect(redirect(AppRoutes.splash, session: status), isNull);
      }
    });

    test('jamais au milieu du parcours : vérification après connexion', () {
      for (final status in [SessionStatus.loading, SessionStatus.error]) {
        expect(redirect(AppRoutes.login, session: status), isNull);
        expect(redirect(AppRoutes.register, session: status), isNull);
      }
    });
  });

  group('Non connecté : connexion obligatoire', () {
    test('première ouverture : onboarding', () {
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

    test(
      'seuls connexion, inscription et mot de passe oublié sont accessibles',
      () {
        for (final route in AppRoutes.authRoutes) {
          expect(
            redirect(route, session: SessionStatus.unauthenticated),
            isNull,
            reason: route,
          );
        }
        for (final route in [
          AppRoutes.home,
          AppRoutes.professionnels,
          AppRoutes.universeSelection,
          AppRoutes.rendezVous,
        ]) {
          expect(
            redirect(route, session: SessionStatus.unauthenticated),
            AppRoutes.login,
            reason: route,
          );
        }
      },
    );
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
  });

  group('Client connecté', () {
    test('après la connexion : choix de l’univers', () {
      for (final route in [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.home,
      ]) {
        expect(
          redirect(route, session: SessionStatus.authorized),
          AppRoutes.universeSelection,
          reason: route,
        );
      }
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

    test('univers choisi : toutes les fonctionnalités sont accessibles', () {
      for (final route in [
        AppRoutes.rendezVous,
        AppRoutes.profil,
        AppRoutes.notifications,
        AppRoutes.messagerie,
        AppRoutes.paiements,
        AppRoutes.professionnel('pro-1'),
      ]) {
        expect(
          redirect(
            route,
            session: SessionStatus.authorized,
            universe: AppUniverse.psychologist,
          ),
          isNull,
          reason: route,
        );
      }
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
          AppRoutes.orientation,
          session: SessionStatus.authorized,
          universe: AppUniverse.psychologist,
        ),
        isNull,
      );
    });

    test('dossiers juridiques réservés à l’univers Avocat', () {
      expect(
        redirect(
          AppRoutes.dossiers,
          session: SessionStatus.authorized,
          universe: AppUniverse.psychologist,
        ),
        AppRoutes.home,
      );
      expect(
        redirect(
          AppRoutes.dossiers,
          session: SessionStatus.authorized,
          universe: AppUniverse.lawyer,
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
