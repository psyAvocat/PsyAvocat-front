import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/core/errors/app_exception.dart';
import 'package:psyavocat_front/core/theme/app_theme.dart';
import 'package:psyavocat_front/core/theme/app_universe.dart';
import 'package:psyavocat_front/core/theme/universe_provider.dart';
import 'package:psyavocat_front/core/widgets/app_navigation_bar.dart';
import 'package:psyavocat_front/features/orientation/data/models/questionnaire_model.dart';
import 'package:psyavocat_front/features/orientation/data/repositories/orientation_repository.dart';
import 'package:psyavocat_front/features/orientation/presentation/controllers/orientation_controller.dart';
import 'package:psyavocat_front/features/orientation/presentation/screens/orientation_questionnaire_screen.dart';
import 'mocks/orientation_test_doubles.dart';

class FakeLawyerUniverseNotifier extends UniverseNotifier {
  @override
  AppUniverse build() => AppUniverse.lawyer;
}

/// Conteneur Riverpod avec un questionnaire simulé.
ProviderContainer _containerWith(FakeOrientationRepository repository) {
  final container = ProviderContainer(
    overrides: [
      currentUniverseProvider.overrideWith(FakeLawyerUniverseNotifier.new),
      orientationRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Questionnaire dynamique — OrientationController', () {
    test(
      'le nombre d’étapes suit le nombre de questions reçues (3 puis 40)',
      () async {
        for (final count in [3, 40]) {
          final container = _containerWith(
            FakeOrientationRepository(
              questionnaire: buildTestQuestionnaire(count: count),
            ),
          );
          final state = await container.read(
            orientationControllerProvider.future,
          );
          expect(state.totalQuestions, count);
          expect(state.currentIndex, 0);
        }
      },
    );

    test(
      'CHOIX_UNIQUE : une nouvelle réponse remplace la précédente',
      () async {
        final container = _containerWith(
          FakeOrientationRepository(questionnaire: buildTestQuestionnaire()),
        );
        await container.read(orientationControllerProvider.future);
        final controller = container.read(
          orientationControllerProvider.notifier,
        );

        controller.toggleAnswer('q1-a');
        controller.toggleAnswer('q1-b');

        final state = container.read(orientationControllerProvider).value!;
        expect(state.answersFor('q1'), {'q1-b'});
      },
    );

    test(
      'CHOIX_MULTIPLE : plusieurs réponses, un second tap retire la réponse',
      () async {
        final container = _containerWith(
          FakeOrientationRepository(
            questionnaire: buildTestQuestionnaire(
              typeReponse: QuestionModel.typeChoixMultiple,
            ),
          ),
        );
        await container.read(orientationControllerProvider.future);
        final controller = container.read(
          orientationControllerProvider.notifier,
        );

        controller
          ..toggleAnswer('q1-a')
          ..toggleAnswer('q1-b');
        expect(
          container.read(orientationControllerProvider).value!.answersFor('q1'),
          {'q1-a', 'q1-b'},
        );

        controller.toggleAnswer('q1-a');
        expect(
          container.read(orientationControllerProvider).value!.answersFor('q1'),
          {'q1-b'},
        );
      },
    );

    test(
      'OUI_NON est traité comme un choix unique (même règle que le backend)',
      () {
        final question = buildTestQuestionnaire(
          typeReponse: QuestionModel.typeOuiNon,
        ).questions.first;
        expect(question.allowsMultiple, isFalse);
        expect(question.isYesNo, isTrue);
      },
    );

    test('question obligatoire : impossible d’avancer sans réponse', () async {
      final container = _containerWith(
        FakeOrientationRepository(questionnaire: buildTestQuestionnaire()),
      );
      await container.read(orientationControllerProvider.future);
      final controller = container.read(orientationControllerProvider.notifier);

      controller.goToNextQuestion();
      expect(
        container.read(orientationControllerProvider).value!.currentIndex,
        0,
      );

      controller
        ..toggleAnswer('q1-a')
        ..goToNextQuestion();
      expect(
        container.read(orientationControllerProvider).value!.currentIndex,
        1,
      );

      expect(controller.goToPreviousQuestion(), isTrue);
      expect(controller.goToPreviousQuestion(), isFalse);
    });

    test('question facultative : on peut avancer sans répondre', () async {
      final container = _containerWith(
        FakeOrientationRepository(
          questionnaire: buildTestQuestionnaire(obligatoire: false),
        ),
      );
      await container.read(orientationControllerProvider.future);
      container.read(orientationControllerProvider.notifier).goToNextQuestion();
      expect(
        container.read(orientationControllerProvider).value!.currentIndex,
        1,
      );
    });

    test(
      'la soumission envoie toutes les réponses et mémorise le résultat',
      () async {
        final repository = FakeOrientationRepository(
          questionnaire: buildTestQuestionnaire(count: 2),
        );
        final container = _containerWith(repository);
        await container.read(orientationControllerProvider.future);
        final controller = container.read(
          orientationControllerProvider.notifier,
        );

        controller
          ..toggleAnswer('q1-b')
          ..goToNextQuestion()
          ..toggleAnswer('q2-a');
        await controller.submit();

        expect(repository.submittedQuestionnaireId, 'questionnaire-test');
        expect(
          repository.submittedReponseIds,
          unorderedEquals(['q1-b', 'q2-a']),
        );
        expect(
          container.read(lastOrientationResultProvider)?.mainLabel,
          'Catégorie de test',
        );
      },
    );

    test('aucun questionnaire publié : état vide', () async {
      final container = _containerWith(FakeOrientationRepository());
      final state = await container.read(orientationControllerProvider.future);
      expect(state.isEmpty, isTrue);
    });
  });

  group('AppNavigationBar', () {
    Future<void> pumpBar(
      WidgetTester tester,
      AppUniverse universe,
      ValueChanged<int> onTap,
    ) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.buildTheme(universe),
          home: Scaffold(
            bottomNavigationBar: AppNavigationBar(
              currentIndex: 0,
              universe: universe,
              onDestinationSelected: onTap,
            ),
          ),
        ),
      );
    }

    testWidgets('5 onglets ; le 3e affiche « Avocats » dans l’univers Avocat', (
      tester,
    ) async {
      var tappedIndex = -1;
      await pumpBar(tester, AppUniverse.lawyer, (index) => tappedIndex = index);

      for (final label in [
        'Accueil',
        'Articles',
        'Avocats',
        'Rendez-vous',
        'Profil',
      ]) {
        expect(find.text(label), findsOneWidget);
      }

      await tester.tap(find.text('Avocats'));
      expect(tappedIndex, 2);
      await tester.tap(find.text('Rendez-vous'));
      expect(tappedIndex, 3);
    });

    testWidgets(
      'le 3e onglet devient « Psychologues » dans l’univers Psychologue',
      (tester) async {
        await pumpBar(tester, AppUniverse.psychologist, (_) {});
        expect(find.text('Psychologues'), findsOneWidget);
        expect(find.text('Avocats'), findsNothing);
      },
    );
  });

  group('OrientationQuestionnaireScreen', () {
    Future<void> pumpScreen(
      WidgetTester tester,
      FakeOrientationRepository repository,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUniverseProvider.overrideWith(
              FakeLawyerUniverseNotifier.new,
            ),
            orientationRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            theme: AppTheme.buildTheme(AppUniverse.lawyer),
            home: const OrientationQuestionnaireScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'affiche la progression « Question 1 / N » et les réponses de l’API',
      (tester) async {
        await pumpScreen(
          tester,
          FakeOrientationRepository(
            questionnaire: buildTestQuestionnaire(count: 20),
          ),
        );

        expect(find.text('Question 1 / 20'), findsOneWidget);
        expect(find.text('Question de test numéro 1'), findsOneWidget);
        expect(find.text('Réponse A1'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        await tester.tap(find.text('Réponse A1'));
        await tester.pump();
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
        expect(find.text('Question 2 / 20'), findsOneWidget);
      },
    );

    testWidgets('CHOIX_MULTIPLE : des cases à cocher sont affichées', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        FakeOrientationRepository(
          questionnaire: buildTestQuestionnaire(
            typeReponse: QuestionModel.typeChoixMultiple,
          ),
        ),
      );
      expect(find.byType(Checkbox), findsNWidgets(2));
      expect(find.text('Plusieurs réponses possibles'), findsOneWidget);
    });

    testWidgets('aucun questionnaire : état vide', (tester) async {
      await pumpScreen(tester, FakeOrientationRepository());
      expect(find.text('Aucun questionnaire disponible'), findsOneWidget);
    });

    testWidgets('API en erreur : message + bouton Réessayer', (tester) async {
      await pumpScreen(
        tester,
        FakeOrientationRepository(loadError: const NetworkException()),
      );
      expect(find.text('Chargement impossible'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });
  });
}
