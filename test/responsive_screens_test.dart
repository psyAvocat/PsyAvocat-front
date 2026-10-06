import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:psyavocat_front/core/network/network_providers.dart';
import 'package:psyavocat_front/core/services/app_preferences_service.dart';
import 'package:psyavocat_front/core/theme/app_theme.dart';
import 'package:psyavocat_front/core/theme/app_universe.dart';
import 'package:psyavocat_front/core/theme/universe_provider.dart';
import 'package:psyavocat_front/features/auth/data/repositories/session_repository.dart';
import 'package:psyavocat_front/features/auth/presentation/screens/login_screen.dart';
import 'package:psyavocat_front/features/auth/presentation/screens/register_screen.dart';
import 'package:psyavocat_front/features/home/presentation/screens/home_screen.dart';
import 'package:psyavocat_front/features/notifications/data/repositories/notifications_repository.dart';
import 'package:psyavocat_front/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:psyavocat_front/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:psyavocat_front/features/orientation/data/models/questionnaire_model.dart';
import 'package:psyavocat_front/features/orientation/data/repositories/orientation_repository.dart';
import 'package:psyavocat_front/features/orientation/presentation/controllers/orientation_controller.dart';
import 'package:psyavocat_front/features/orientation/presentation/screens/orientation_questionnaire_screen.dart';
import 'package:psyavocat_front/features/orientation/presentation/screens/orientation_result_screen.dart';
import 'package:psyavocat_front/features/professionnels/data/models/professionnel_summary.dart';
import 'package:psyavocat_front/features/professionnels/data/repositories/professionnels_repository.dart';
import 'package:psyavocat_front/features/professionnels/presentation/screens/professionnels_list_screen.dart';
import 'package:psyavocat_front/features/rendez_vous/data/repositories/rendez_vous_repository.dart';
import 'package:psyavocat_front/features/selection_univers/presentation/screens/selection_univers_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mocks/orientation_test_doubles.dart';
import 'mocks/test_mocks.dart';

/// Petit, standard et grand téléphone.
const _screenSizes = {
  'petit 320x568': Size(320, 568),
  'standard 393x852': Size(393, 852),
  'grand 430x932': Size(430, 932),
};

class _PsychologistUniverse extends UniverseNotifier {
  @override
  AppUniverse build() => AppUniverse.psychologist;
}

/// Résultat volontairement long pour vérifier que rien ne déborde.
class _LongResult extends LastOrientationResultNotifier {
  @override
  ResultatOrientationModel? build() => const ResultatOrientationModel(
    categorieBesoinNom: 'Gestion du stress et de l’anxiété au quotidien',
    categorieBesoinDescription:
        'Un accompagnement pour apprendre à identifier et apaiser les sources de stress.',
    scoresParCategorie: [
      CategorieScoreModel(nom: 'Stress', score: 12, rang: 1),
      CategorieScoreModel(nom: 'Sommeil', score: 6, rang: 2),
    ],
    professionnelsRecommandes: [
      ProfessionnelSummary(
        id: 'p1',
        fullName: 'Dr. Aminata Ndiaye-Konaté',
        ville: 'Dakar',
        specialites: [
          'Thérapie cognitive et comportementale',
          'Gestion du stress',
        ],
        noteMoyenne: 4.8,
        nombreAvis: 12,
        modeConsultation: 'VISIO',
      ),
    ],
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// Affiche [screen] à la taille donnée et vérifie l'absence de débordement.
  Future<void> expectNoOverflow(
    WidgetTester tester, {
    required Widget screen,
    required Size size,
    double textScale = 1.0,
    bool useRouter = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    // Questionnaire long : 25 questions avec un texte et des réponses longues.
    final longQuestionnaire = QuestionnaireModel(
      id: 'q-long',
      titre: 'Questionnaire',
      type: 'PSYCHOLOGIQUE',
      questions: [
        for (var i = 1; i <= 25; i++)
          QuestionModel(
            id: 'q$i',
            texte:
                'Depuis combien de temps ressentez-vous ces difficultés '
                'dans votre vie personnelle ou professionnelle ? ($i)',
            ordre: i,
            obligatoire: true,
            typeReponse: QuestionModel.typeChoixUnique,
            reponses: [
              for (var r = 1; r <= 6; r++)
                ReponseModel(
                  id: 'q$i-r$r',
                  libelle:
                      'Une réponse assez longue pour passer sur plusieurs lignes $r',
                ),
            ],
          ),
      ],
    );

    final theme = AppTheme.buildTheme(AppUniverse.psychologist);
    Widget app;
    if (useRouter) {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => screen),
          GoRoute(path: '/onboarding', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/login', builder: (_, _) => const SizedBox()),
        ],
      );
      app = MaterialApp.router(theme: theme, routerConfig: router);
    } else {
      app = MaterialApp(theme: theme, home: screen);
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUniverseProvider.overrideWith(_PsychologistUniverse.new),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
          orientationRepositoryProvider.overrideWithValue(
            FakeOrientationRepository(questionnaire: longQuestionnaire),
          ),
          lastOrientationResultProvider.overrideWith(_LongResult.new),
          professionnelsRepositoryProvider.overrideWithValue(
            MockProfessionnelsRepository(),
          ),
          rendezVousRepositoryProvider.overrideWithValue(
            MockRendezVousRepository(),
          ),
          notificationsRepositoryProvider.overrideWithValue(
            MockNotificationsRepository([]),
          ),
        ],
        child: app,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  }

  final screens = <String, (Widget, bool)>{
    'Splash': (const SplashScreen(), true),
    'Onboarding': (const OnboardingScreen(), false),
    'Connexion': (const LoginScreen(), false),
    'Inscription': (const RegisterScreen(), false),
    'Choix de l’univers': (const SelectionUniversScreen(), false),
    'Questionnaire': (const OrientationQuestionnaireScreen(), false),
    'Résultat d’orientation': (const OrientationResultScreen(), false),
    'Accueil': (const HomeScreen(), false),
    'Listing professionnels': (const ProfessionnelsListScreen(), false),
  };

  for (final entry in screens.entries) {
    final (screen, useRouter) = entry.value;
    group('${entry.key} — aucun débordement', () {
      for (final size in _screenSizes.entries) {
        testWidgets(size.key, (tester) async {
          await expectNoOverflow(
            tester,
            screen: screen,
            size: size.value,
            useRouter: useRouter,
          );
        });
      }
      testWidgets('petit écran + police agrandie (130 %)', (tester) async {
        await expectNoOverflow(
          tester,
          screen: screen,
          size: _screenSizes.values.first,
          textScale: 1.3,
          useRouter: useRouter,
        );
      });
    });
  }
}
