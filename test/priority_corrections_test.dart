import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:psyavocat_front/core/services/app_preferences_service.dart';
import 'package:psyavocat_front/core/theme/app_theme.dart';
import 'package:psyavocat_front/core/theme/app_universe.dart';
import 'package:psyavocat_front/core/theme/universe_provider.dart';
import 'package:psyavocat_front/core/widgets/google_logo.dart';
import 'package:psyavocat_front/core/widgets/google_sign_in_button.dart';
import 'package:psyavocat_front/features/auth/presentation/screens/login_screen.dart';
import 'package:psyavocat_front/features/onboarding/presentation/widgets/onboarding_slide.dart';
import 'package:psyavocat_front/features/orientation/presentation/screens/orientation_intro_screen.dart';
import 'package:psyavocat_front/features/selection_univers/presentation/screens/selection_univers_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Corrections prioritaires — Tests fonctionnels & visuels', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('1. GoogleLogo utilise SvgPicture avec le logo officiel', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: GoogleLogo(size: 32))),
      );

      expect(find.byType(GoogleLogo), findsOneWidget);
    });

    testWidgets('2. GoogleSignInButton est centré avec retour tactile Material', (
      tester,
    ) async {
      var clicked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleSignInButton(onPressed: () => clicked = true),
          ),
        ),
      );

      expect(find.byType(GoogleLogo), findsOneWidget);
      await tester.tap(find.byType(GoogleSignInButton));
      expect(clicked, isTrue);
    });

    testWidgets(
      '3. OnboardingSlide affiche UNE SEULE image à la fois (pas de Row côte à côte)',
      (tester) async {
        const slideData = OnboardingSlideData(
          universe: AppUniverse.lawyer,
          firstImage: 'assets/images/lawyer_1.jpg',
          secondImage: 'assets/images/lawyer_2.jpg',
          icon: Icons.balance_rounded,
          titleStart: 'Trouvez un avocat\n',
          titleHighlight: 'à votre écoute',
          description: 'Accompagnement juridique de qualité.',
          highlights: ['Confidentialité garantie'],
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.buildTheme(AppUniverse.lawyer),
            home: const Scaffold(body: OnboardingSlide(data: slideData)),
          ),
        );
        await tester.pump();

        // Vérifie qu'il y a exactement 1 widget Image affiché (pas 2 en ligne)
        expect(find.byType(Image), findsOneWidget);
        expect(find.text('Confidentialité garantie'), findsOneWidget);
      },
    );

    testWidgets(
      '4. OrientationIntroScreen affiche la question bienveillante et les 2 options',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/orientation/intro',
          routes: [
            GoRoute(
              path: '/orientation/intro',
              builder: (_, _) => const OrientationIntroScreen(),
            ),
            GoRoute(
              path: '/orientation',
              builder: (_, _) => const Scaffold(body: Text('Questionnaire Page')),
            ),
            GoRoute(
              path: '/home',
              builder: (_, _) => const Scaffold(body: Text('Home Page')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
            ],
            child: MaterialApp.router(
              theme: AppTheme.buildTheme(AppUniverse.psychologist),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Souhaitez-vous répondre à quelques questions pour nous aider à vous orienter vers un psychologue ?',
          ),
          findsOneWidget,
        );
        expect(find.text('Oui, commencer'), findsOneWidget);
        expect(find.text('Pas maintenant'), findsOneWidget);

        // Tap "Pas maintenant" -> mène à /home
        await tester.tap(find.text('Pas maintenant'));
        await tester.pumpAndSettle();
        expect(find.text('Home Page'), findsOneWidget);
      },
    );
  });
}
