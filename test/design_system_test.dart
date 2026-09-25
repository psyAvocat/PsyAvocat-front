import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:psyavocat_front/core/theme/design_system.dart';
import 'package:psyavocat_front/core/widgets/widgets.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Design System Tokens Tests', () {
    test('AppColors matches required primary and functional colors', () {
      expect(AppColors.psychologist, equals(const Color(0xFF45088E)));
      expect(AppColors.lawyer, equals(const Color(0xFF0C2659)));
      expect(AppColors.textPrimary, equals(const Color(0xFF383636)));
      expect(AppColors.success, equals(const Color(0xFF4BD418)));
      expect(AppColors.warning, equals(const Color(0xFFF2C121)));
      expect(AppColors.danger, equals(const Color(0xFFFB1216)));
      expect(AppColors.buttonText, equals(const Color(0xFFFFFFFF)));
    });

    test('AppColors transition gradient connects lawyer and psychologist universes', () {
      const gradient = AppColors.transitionGradient;
      expect(gradient.colors.first, equals(const Color(0xFF0C2659)));
      expect(gradient.colors.last, equals(const Color(0xFF45088E)));
    });

    test('AppSpacing adheres to 4/8 px scale', () {
      expect(AppSpacing.s4, equals(4.0));
      expect(AppSpacing.s8, equals(8.0));
      expect(AppSpacing.s12, equals(12.0));
      expect(AppSpacing.s16, equals(16.0));
      expect(AppSpacing.s20, equals(20.0));
      expect(AppSpacing.s24, equals(24.0));
      expect(AppSpacing.s32, equals(32.0));
      expect(AppSpacing.s40, equals(40.0));
      expect(AppSpacing.s48, equals(48.0));
    });

    test('AppTypography uses Montserrat font', () {
      expect(AppTypography.fontFamily, equals('Montserrat'));
      expect(AppTypography.grandTitre.fontSize, equals(32));
      expect(AppTypography.grandTitre.fontWeight, equals(FontWeight.w700));

      expect(AppTypography.titreMoyen.fontSize, equals(24));
      expect(AppTypography.titreMoyen.fontWeight, equals(FontWeight.w600));

      expect(AppTypography.petitTitre.fontSize, equals(20));
      expect(AppTypography.petitTitre.fontWeight, equals(FontWeight.w600));

      expect(AppTypography.texte.fontSize, equals(16));
      expect(AppTypography.texte.fontWeight, equals(FontWeight.w400));

      expect(AppTypography.miniTexte.fontSize, equals(12));
      expect(AppTypography.miniTexte.fontWeight, equals(FontWeight.w400));
    });

    test('AppButtonSizes standard height is 52px', () {
      expect(AppButtonSizes.heightDefault, equals(52.0));
      expect(AppButtonSizes.heightCompact, equals(42.0));
      expect(AppButtonSizes.heightLarge, equals(58.0));
    });
  });

  group('Design System Reusable Widgets Tests', () {
    testWidgets('AppButton renders normal, loading and handles clicks', (tester) async {
      bool clicked = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Valider',
              onPressed: () => clicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Valider'), findsOneWidget);
      await tester.tap(find.text('Valider'));
      expect(clicked, isTrue);

      // Loading state
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppButton(
              text: 'Valider',
              isLoading: true,
              onPressed: null,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AppTextField renders with label and hint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppTextField(
              label: 'Email professionnel',
              hint: 'exemple@avocat.fr',
            ),
          ),
        ),
      );

      expect(find.text('Email professionnel'), findsOneWidget);
      expect(find.text('exemple@avocat.fr'), findsOneWidget);
    });

    testWidgets('AppBadge displays correct labels and statuses', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Column(
              children: [
                AppBadge.success(label: 'Actif'),
                AppBadge.warning(label: 'En attente'),
                AppBadge.danger(label: 'Rejeté'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Actif'), findsOneWidget);
      expect(find.text('En attente'), findsOneWidget);
      expect(find.text('Rejeté'), findsOneWidget);
    });

    testWidgets('AppProgressBar renders with correct percentage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppProgressBar(
              value: 0.75,
              label: 'Progression du dossier',
              showPercentage: true,
            ),
          ),
        ),
      );

      expect(find.text('Progression du dossier'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('AppUniverseSwitch switches between universes', (tester) async {
      AppUniverse selected = AppUniverse.lawyer;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AppUniverseSwitch(
                  currentUniverse: selected,
                  onUniverseChanged: (u) => setState(() => selected = u),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Avocat'), findsOneWidget);
      expect(find.text('Psychologue'), findsOneWidget);

      await tester.tap(find.text('Psychologue'));
      await tester.pumpAndSettle();

      expect(selected, equals(AppUniverse.psychologist));
    });
  });
}
