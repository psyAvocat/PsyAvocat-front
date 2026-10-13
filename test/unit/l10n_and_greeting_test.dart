import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/core/l10n/app_strings.dart';
import 'package:psyavocat_front/core/l10n/en_strings.dart';
import 'package:psyavocat_front/features/home/presentation/utils/home_greeting.dart';

Set<String> _variables(String texte) =>
    RegExp(r'\{(\w+)\}').allMatches(texte).map((m) => m.group(1)!).toSet();

void main() {
  tearDown(() => setAppLanguage('fr'));

  group('Traductions', () {
    test('français par défaut, anglais après changement de langue', () {
      expect(tr('Mes dossiers'), 'Mes dossiers');
      setAppLanguage('en');
      expect(tr('Mes dossiers'), 'My cases');
    });

    test('valeurs variables remplacées dans les deux langues', () {
      expect(tr('Tous ({n})', {'n': 3}), 'Tous (3)');
      setAppLanguage('en');
      expect(tr('Tous ({n})', {'n': 3}), 'All (3)');
    });

    test('sans traduction connue, le texte français s’affiche', () {
      setAppLanguage('en');
      expect(
        tr('Texte absent du dictionnaire'),
        'Texte absent du dictionnaire',
      );
    });

    test('chaque traduction garde les mêmes variables que le français', () {
      for (final entry in enStrings.entries) {
        expect(
          _variables(entry.value),
          _variables(entry.key),
          reason: entry.key,
        );
      }
    });
  });

  group('Salutation de l’accueil', () {
    // 12 octobre 2026 : un lundi.
    final lundi = DateTime(2026, 10, 12);

    test('Bonjour en journée, Bonsoir le soir, avec le prénom', () {
      expect(
        greetingFor(
          now: lundi.add(const Duration(hours: 9)),
          prenom: 'Awa',
          tirage: 1,
        ).titre,
        'Bonjour Awa',
      );
      expect(
        greetingFor(
          now: lundi.add(const Duration(hours: 20)),
          prenom: 'Awa',
          tirage: 1,
        ).titre,
        'Bonsoir Awa',
      );
    });

    test('formule de week-end le samedi (une fois sur deux)', () {
      final samedi = DateTime(2026, 10, 17, 10);
      expect(
        greetingFor(now: samedi, prenom: 'Awa', tirage: 2).titre,
        'Passez un excellent week-end Awa !',
      );
      expect(
        greetingFor(now: samedi, prenom: 'Awa', tirage: 1).titre,
        'Bonjour Awa',
      );
    });

    test('phrase tirée au hasard et traduite', () {
      final phrases = {
        for (var t = 0; t < 12; t++)
          greetingFor(
            now: lundi.add(const Duration(hours: 9)),
            prenom: null,
            tirage: t,
          ).phrase,
      };
      expect(phrases.length, greaterThan(3));
      setAppLanguage('en');
      final salut = greetingFor(
        now: lundi.add(const Duration(hours: 9)),
        prenom: 'Awa',
        tirage: 0,
      );
      expect(salut.titre, 'Hello Awa');
      expect(enStrings.values, contains(salut.phrase));
    });
  });
}
