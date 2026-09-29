import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/core/theme/app_universe.dart';
import 'package:psyavocat_front/core/theme/universe_provider.dart';
import 'package:psyavocat_front/core/widgets/floating_navbar.dart';
import 'package:psyavocat_front/features/orientation/presentation/controllers/orientation_controller.dart';
import 'package:psyavocat_front/features/orientation/presentation/screens/orientation_questionnaire_screen.dart';
import 'package:psyavocat_front/features/orientation/presentation/screens/orientation_recap_screen.dart';

class FakeLawyerUniverseNotifier extends UniverseNotifier {
  @override
  AppUniverse build() => AppUniverse.lawyer;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Étape 2 — OrientationController Logic Tests', () {
    test('Initial state starts at step 0 with empty answers', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(orientationControllerProvider);
      expect(state.currentStep, equals(0));
      expect(state.answers.isEmpty, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('selectAnswer stores question, label, and code for a given step', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(orientationControllerProvider.notifier);
      notifier.selectAnswer(
        step: 0,
        question: 'Quel est votre problème principal ?',
        label: 'Travail, licenciement ou contrat de travail',
        code: 'TRAVAIL',
      );

      final state = container.read(orientationControllerProvider);
      expect(state.answers.containsKey(0), isTrue);
      expect(state.answers[0]?.code, equals('TRAVAIL'));
      expect(state.answers[0]?.label, equals('Travail, licenciement ou contrat de travail'));
    });

    test('nextStep and previousStep navigate steps properly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(orientationControllerProvider.notifier);
      const totalSteps = 3;

      // 0 -> 1
      expect(notifier.nextStep(totalSteps), isTrue);
      expect(container.read(orientationControllerProvider).currentStep, equals(1));

      // 1 -> 2
      expect(notifier.nextStep(totalSteps), isTrue);
      expect(container.read(orientationControllerProvider).currentStep, equals(2));

      // 2 is last step -> returns false
      expect(notifier.nextStep(totalSteps), isFalse);
      expect(container.read(orientationControllerProvider).currentStep, equals(2));

      // 2 -> 1
      expect(notifier.previousStep(), isTrue);
      expect(container.read(orientationControllerProvider).currentStep, equals(1));

      // 1 -> 0
      expect(notifier.previousStep(), isTrue);
      expect(container.read(orientationControllerProvider).currentStep, equals(0));

      // 0 is first step -> returns false
      expect(notifier.previousStep(), isFalse);
      expect(container.read(orientationControllerProvider).currentStep, equals(0));
    });

    test('reset clears state back to initial step and answers', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(orientationControllerProvider.notifier);
      notifier.selectAnswer(
        step: 0,
        question: 'Q1',
        label: 'A1',
        code: 'C1',
      );
      notifier.nextStep(3);

      notifier.reset();

      final state = container.read(orientationControllerProvider);
      expect(state.currentStep, equals(0));
      expect(state.answers.isEmpty, isTrue);
    });
  });

  group('Étape 1 — FloatingNavBar Widget Tests', () {
    testWidgets('Renders all 5 navigation tabs with labels', (tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUniverseProvider.overrideWith(
              FakeLawyerUniverseNotifier.new,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: FloatingNavBar(
                currentIndex: 0,
                onTap: (index) => tappedIndex = index,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Professionnels'), findsOneWidget);
      expect(find.text('Rendez-vous'), findsOneWidget);
      expect(find.text('Mes dossiers'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Tap on Professionnels (index 1)
      await tester.tap(find.text('Professionnels'));
      await tester.pump();
      expect(tappedIndex, equals(1));

      // Tap on Rendez-vous (index 2)
      await tester.tap(find.text('Rendez-vous'));
      await tester.pump();
      expect(tappedIndex, equals(2));

      // Tap on Mes dossiers (index 3)
      await tester.tap(find.text('Mes dossiers'));
      await tester.pump();
      expect(tappedIndex, equals(3));
    });
  });

  group('Étape 2 — Orientation Screens Widget Tests', () {
    testWidgets('OrientationQuestionnaireScreen renders question, segmented bars and button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUniverseProvider.overrideWith(
              FakeLawyerUniverseNotifier.new,
            ),
          ],
          child: const MaterialApp(
            home: OrientationQuestionnaireScreen(),
          ),
        ),
      );

      expect(find.text('Ignorer'), findsOneWidget);
      expect(find.text('Suivant'), findsOneWidget);
      expect(find.text('Famille, mariage, divorce'), findsOneWidget);
      expect(find.text('Travail, licenciement ou contrat de travail'), findsOneWidget);
    });

    testWidgets('OrientationRecapScreen renders recap title and action buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUniverseProvider.overrideWith(
              FakeLawyerUniverseNotifier.new,
            ),
          ],
          child: const MaterialApp(
            home: OrientationRecapScreen(),
          ),
        ),
      );

      expect(find.textContaining('Recapitulatif'), findsOneWidget);
      expect(find.text('Trouver mes professionnels'), findsOneWidget);
      expect(find.text('Reprendre'), findsOneWidget);
    });
  });
}
