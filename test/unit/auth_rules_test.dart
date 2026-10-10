import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/core/utils/validators.dart';
import 'package:psyavocat_front/features/auth/data/models/current_user.dart';
import 'package:psyavocat_front/features/auth/presentation/utils/auth_navigation.dart';

CurrentUser user({
  List<String> roles = const ['ROLE_CLIENT', 'ROLE_USER'],
  bool hasMetierProfile = true,
  bool emailVerified = true,
  bool actif = true,
}) {
  return CurrentUser(
    userId: 'uid',
    email: 'ramla@gmail.com',
    nom: 'Diarra',
    prenom: 'Ramla',
    roles: roles,
    hasMetierProfile: hasMetierProfile,
    emailVerified: emailVerified,
    actif: actif,
  );
}

void main() {
  group('Téléphone : même règle que PhoneNumbers (Spring Boot)', () {
    test('numéros valides : indicatif facultatif, séparateurs ignorés', () {
      expect(Validators.phone('+223 76 12 34 56'), isNull);
      expect(Validators.phone('76-12-34-56'), isNull);
      expect(Validators.phone('(+33) 6.12.34.56.78'), isNull);
    });

    test(
      'numéros invalides : trop courts, trop longs, lettres, séparateurs',
      () {
        for (final value in [
          '12',
          '1234567',
          '1234-567',
          '1234567890123456',
          '76 AB 34 56',
          '--------',
        ]) {
          expect(
            Validators.phone(value),
            Validators.phoneInvalidMessage,
            reason: value,
          );
        }
      },
    );

    test('obligatoire, comme à la création du profil client', () {
      expect(Validators.phone(''), isNotNull);
      expect(Validators.phone('   '), isNotNull);
      expect(Validators.phone(null), isNotNull);
    });
  });

  group('Accès à l’app mobile (GET /me)', () {
    test('client au profil complet et email confirmé : autorisé', () {
      expect(evaluateAccess(user()), AccessDecision.authorized);
    });

    test('client à l’email non confirmé : confirmation exigée', () {
      expect(
        evaluateAccess(user(emailVerified: false)),
        AccessDecision.emailNotVerified,
      );
    });

    test('sans profil métier : profil à compléter avant tout', () {
      expect(
        evaluateAccess(
          user(roles: const ['ROLE_USER'], hasMetierProfile: false),
        ),
        AccessDecision.profileIncomplete,
      );
    });

    test('désactivé ou professionnel : refusé', () {
      expect(
        evaluateAccess(user(actif: false)),
        AccessDecision.deniedDeactivated,
      );
      expect(
        evaluateAccess(
          user(roles: const ['ROLE_AVOCAT', 'ROLE_PROFESSIONNEL']),
        ),
        AccessDecision.deniedProfessional,
      );
    });
  });

  test('emailVerified absent de /me : considéré non confirmé', () {
    final parsed = CurrentUser.fromJson({
      'email': 'ramla@gmail.com',
      'roles': ['ROLE_CLIENT'],
      'hasMetierProfile': true,
    });
    expect(parsed.emailVerified, isFalse);
  });
}
