import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/core/errors/app_exception.dart';
import 'package:psyavocat_front/core/theme/app_universe.dart';
import 'package:psyavocat_front/features/auth/data/models/current_user.dart';
import 'package:psyavocat_front/features/auth/presentation/utils/auth_navigation.dart';

CurrentUser _user({required List<String> roles, bool hasMetierProfile = true}) {
  return CurrentUser(
    userId: '1',
    email: 'test@example.com',
    nom: 'Test',
    prenom: 'Awa',
    roles: roles,
    hasMetierProfile: hasMetierProfile,
  );
}

void main() {
  group(
    'resolvePostAuthRoute — navigation selon le rôle renvoyé par GET /me',
    () {
      test('le JSON de /me est lu tel quel (rôles du backend)', () {
        final user = CurrentUser.fromJson({
          'userId': 'abc',
          'email': 'a@b.c',
          'roles': ['ROLE_PATIENT', 'ROLE_USER'],
          'hasMetierProfile': true,
        });
        expect(user.isClient, isTrue);
        expect(user.isProfessionalOrAdmin, isFalse);
      });

      test('client avec univers déjà choisi → accueil', () {
        final route = resolvePostAuthRoute(
          user: _user(roles: ['ROLE_JUSTICIABLE']),
          savedUniverse: AppUniverse.lawyer,
        );
        expect(route, '/home');
      });

      test('client sans univers mémorisé → choix de l’univers', () {
        final route = resolvePostAuthRoute(
          user: _user(roles: ['ROLE_PATIENT']),
          savedUniverse: null,
        );
        expect(route, '/selection-univers');
      });

      test(
        'compte sans profil métier (juste inscrit) → choix de l’univers',
        () {
          final route = resolvePostAuthRoute(
            user: _user(roles: ['ROLE_USER'], hasMetierProfile: false),
            savedUniverse: AppUniverse.psychologist,
          );
          expect(route, '/selection-univers');
        },
      );

      test('professionnel ou administrateur → refusé sur l’app mobile', () {
        for (final roles in [
          ['ROLE_AVOCAT', 'ROLE_PROFESSIONNEL'],
          ['ROLE_ADMINISTRATEUR'],
        ]) {
          expect(
            () => resolvePostAuthRoute(
              user: _user(roles: roles),
              savedUniverse: null,
            ),
            throwsA(isA<AuthException>()),
          );
        }
      });
    },
  );
}
