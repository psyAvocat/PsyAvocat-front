import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psyavocat_front/core/services/app_preferences_service.dart';
import 'package:psyavocat_front/core/theme/app_colors.dart';
import 'package:psyavocat_front/core/theme/app_universe.dart';
import 'package:psyavocat_front/core/widgets/google_logo.dart';
import 'package:psyavocat_front/core/widgets/psyavocat_logo.dart';
import 'package:psyavocat_front/core/widgets/top_arch_clipper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2 — Services & Logic Tests', () {
    test('AppPreferencesService saves and restores onboarding & universe status', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = AppPreferencesService(prefs);

      // Par défaut, onboarding non vu et pas d'univers
      expect(service.hasSeenOnboarding(), isFalse);
      expect(service.getSelectedUniverse(), isNull);

      // Enregistrement onboarding vu
      await service.setHasSeenOnboarding(true);
      expect(service.hasSeenOnboarding(), isTrue);

      // Enregistrement univers avocat
      await service.setSelectedUniverse(AppUniverse.lawyer);
      expect(service.getSelectedUniverse(), equals(AppUniverse.lawyer));

      // Changement pour psychologue
      await service.setSelectedUniverse(AppUniverse.psychologist);
      expect(service.getSelectedUniverse(), equals(AppUniverse.psychologist));

      // Reset
      await service.clearAll();
      expect(service.hasSeenOnboarding(), isFalse);
      expect(service.getSelectedUniverse(), isNull);
    });

    test('AppUniverse properties match Figma and Design System specifications', () {
      // Univers Avocat
      expect(AppUniverse.lawyer.primaryColor, equals(AppColors.lawyer));
      expect(AppUniverse.lawyer.displayName, equals('Avocat'));
      expect(AppUniverse.lawyer.isLawyer, isTrue);
      expect(AppUniverse.lawyer.isPsychologist, isFalse);

      // Univers Psychologue
      expect(AppUniverse.psychologist.primaryColor, equals(AppColors.psychologist));
      expect(AppUniverse.psychologist.displayName, equals('Psychologue'));
      expect(AppUniverse.psychologist.isPsychologist, isTrue);
      expect(AppUniverse.psychologist.isLawyer, isFalse);

      // Neutre (transition)
      expect(AppUniverse.neutral.isNeutral, isTrue);
    });

    test('TopWaveClipper generates a valid, closed non-empty path', () {
      final clipper = TopWaveClipper();
      const size = Size(390, 280);
      final path = clipper.getClip(size);

      expect(path, isNotNull);
      final bounds = path.getBounds();
      expect(bounds.width, greaterThan(0));
      expect(bounds.height, greaterThan(0));
      expect(clipper.shouldReclip(clipper), isFalse);
    });
  });

  group('Phase 2 — Widget Component Tests', () {
    testWidgets('GoogleLogo renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GoogleLogo(size: 32),
            ),
          ),
        ),
      );

      expect(find.byType(GoogleLogo), findsOneWidget);
    });

    testWidgets('PsyAvocatLogo renders with fallback on missing asset in tests', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PsyAvocatLogo(
                size: 100,
                showText: true,
                isWhite: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PsyAvocatLogo), findsOneWidget);
    });
  });
}
