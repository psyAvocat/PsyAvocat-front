import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/core/theme/design_system.dart';
import 'package:psyavocat_front/core/widgets/widgets.dart';

/// Enveloppe un composant dans une page minimale pour le tester.
Widget _wrap(Widget child, {AppUniverse universe = AppUniverse.psychologist}) {
  return MaterialApp(
    theme: AppTheme.buildTheme(universe),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('Thème par univers', () {
    test('le ColorScheme change selon l’univers', () {
      expect(
        AppTheme.buildTheme(AppUniverse.lawyer).colorScheme.primary,
        AppColors.lawyer,
      );
      expect(
        AppTheme.buildTheme(AppUniverse.psychologist).colorScheme.primary,
        AppColors.psychologist,
      );
    });
  });

  group('Composants partagés', () {
    testWidgets(
      'AppPrimaryButton est un FilledButton qui déclenche onPressed',
      (tester) async {
        var tapCount = 0;
        await tester.pumpWidget(
          _wrap(
            AppPrimaryButton(label: 'Suivant', onPressed: () => tapCount++),
          ),
        );

        expect(find.byType(FilledButton), findsOneWidget);
        await tester.tap(find.text('Suivant'));
        expect(tapCount, 1);
      },
    );

    testWidgets('AppPrimaryButton ne réagit pas pendant le chargement', (
      tester,
    ) async {
      var tapCount = 0;
      await tester.pumpWidget(
        _wrap(
          AppPrimaryButton(
            label: 'Envoyer',
            isLoading: true,
            onPressed: () => tapCount++,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Envoyer'), findsNothing);
      await tester.tap(find.byType(AppPrimaryButton));
      expect(tapCount, 0);
    });

    testWidgets('AppGradientButton est désactivé quand onPressed est null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const AppGradientButton(label: "S'inscrire", onPressed: null)),
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets(
      'AppStepProgress affiche « Question 3 / 20 » et une barre Material',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const AppStepProgress(
              currentStep: 3,
              totalSteps: 20,
              label: 'Question',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Question 3 / 20'), findsOneWidget);
        final bar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(bar.value, closeTo(3 / 20, 0.001));
      },
    );

    testWidgets(
      'AppChoiceTile : Radio en choix unique, Checkbox en choix multiple',
      (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          _wrap(
            RadioGroup<String>(
              groupValue: null,
              onChanged: (_) {},
              child: AppChoiceTile(
                value: 'r1',
                label: 'Terrain, maison ou propriété',
                isSelected: false,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );
        expect(find.byType(Radio<String>), findsOneWidget);
        await tester.tap(find.text('Terrain, maison ou propriété'));
        expect(tapped, isTrue);

        await tester.pumpWidget(
          _wrap(
            AppChoiceTile(
              value: 'r2',
              label: 'Plusieurs',
              isSelected: true,
              allowsMultiple: true,
              onTap: () {},
            ),
          ),
        );
        expect(find.byType(Checkbox), findsOneWidget);
      },
    );

    testWidgets('AppCheckboxTile inverse sa valeur au tap', (tester) async {
      bool? newValue;
      await tester.pumpWidget(
        _wrap(
          AppCheckboxTile(
            value: false,
            onChanged: (value) => newValue = value,
            label: const Text("J'accepte"),
          ),
        ),
      );

      await tester.tap(find.text("J'accepte"));
      expect(newValue, isTrue);
    });

    testWidgets('AppAvatar affiche les initiales sans photo', (tester) async {
      await tester.pumpWidget(_wrap(const AppAvatar(name: 'Awa Traoré')));
      expect(find.text('AT'), findsOneWidget);
    });

    testWidgets('AppUniverseCard affiche titre et description', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          AppUniverseCard(
            title: 'Avocat',
            description: 'Conseil juridique et accompagnement',
            icon: Icons.balance_rounded,
            gradient: AppColors.lawyerCardGradient,
            shadowColor: AppColors.lawyer,
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Conseil juridique et accompagnement'), findsOneWidget);
      await tester.tap(find.text('Avocat'));
      expect(tapped, isTrue);
    });

    testWidgets('AppTextDivider affiche son texte', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppTextDivider(label: 'CONTINUE AVEC')),
      );
      expect(find.text('CONTINUE AVEC'), findsOneWidget);
    });
  });
}
