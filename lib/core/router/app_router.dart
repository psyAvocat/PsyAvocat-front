import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/session_controller.dart';
import '../../features/auth/presentation/screens/access_denied_screen.dart';
import '../../features/auth/presentation/screens/complete_profile_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/contenus/presentation/screens/contenu_detail_screen.dart';
import '../../features/contenus/presentation/screens/contenus_screen.dart';
import '../../features/dossiers/presentation/screens/dossiers_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/messagerie/presentation/screens/conversation_detail_screen.dart';
import '../../features/messagerie/presentation/screens/messagerie_screen.dart';
import '../../features/navigation/presentation/main_navigation_shell.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/orientation/presentation/screens/orientation_intro_screen.dart';
import '../../features/orientation/presentation/screens/orientation_questionnaire_screen.dart';
import '../../features/orientation/presentation/screens/orientation_result_screen.dart';
import '../../features/paiements/presentation/screens/paiements_screen.dart';
import '../../features/professionnels/data/models/professional_detail_model.dart';
import '../../features/professionnels/presentation/screens/professionnel_detail_screen.dart';
import '../../features/professionnels/presentation/screens/professionnels_list_screen.dart';
import '../../features/professionnels/presentation/screens/recherche_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/rendez_vous/presentation/screens/choix_creneau_screen.dart';
import '../../features/rendez_vous/presentation/screens/rendez_vous_confirmation_screen.dart';
import '../../features/rendez_vous/presentation/screens/rendez_vous_screen.dart';
import '../../features/selection_univers/presentation/screens/selection_univers_screen.dart';
import '../../features/suivi_psychologique/presentation/screens/suivi_psychologique_screen.dart';
import '../services/app_preferences_service.dart';
import '../theme/universe_provider.dart';
import 'app_routes.dart';
import 'route_guard.dart';

/// Configuration GoRouter de l'application PsyAvocat.
///
/// - Créé UNE seule fois ; les redirections sont réévaluées quand le statut de
///   session ou l'univers change (pas à chaque reconstruction).
/// - Toutes les règles d'accès sont dans [resolveRedirect] (route_guard.dart).
/// - Écrans d'entrée (splash, connexion, statut du compte, choix de l'univers,
///   onglets) : fondu enchaîné. Écrans de détail empilés : transition native.
final appRouterProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(appPreferencesServiceProvider);

  final refresh = ValueNotifier<int>(0);
  ref.listen(
    sessionControllerProvider.select((session) => session.status),
    (_, _) => refresh.value++,
  );
  ref.listen(currentUniverseProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(
      location: state.matchedLocation,
      session: ref.read(sessionControllerProvider).status,
      hasSeenOnboarding: prefs.hasSeenOnboarding(),
      universe: ref.read(currentUniverseProvider),
    ),
    errorBuilder: (context, state) => const _NotFoundScreen(),
    routes: [
      // --- Entrée et statut du compte (remplacés les uns par les autres) ---
      _fadeRoute(AppRoutes.splash, (_) => const SplashScreen()),
      _fadeRoute(AppRoutes.onboarding, (_) => const OnboardingScreen()),
      _fadeRoute(AppRoutes.login, (_) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      _fadeRoute(AppRoutes.accessDenied, (_) => const AccessDeniedScreen()),
      _fadeRoute(
        AppRoutes.completeProfile,
        (_) => const CompleteProfileScreen(),
      ),
      _fadeRoute(AppRoutes.verifyEmail, (_) => const VerifyEmailScreen()),
      _fadeRoute(
        AppRoutes.universeSelection,
        (_) => const SelectionUniversScreen(),
      ),

      // --- Navigation principale : 5 onglets (navigation_destinations.dart) ---
      // Chaque onglet garde son état (scroll, sous-pages) d'un passage à l'autre.
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) => _fadePage(
          state,
          MainNavigationShell(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.articles,
                builder: (_, _) => const ContenusScreen(),
              ),
              GoRoute(
                path: AppRoutes.conseils,
                builder: (_, _) => const ContenusScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.professionnels,
                builder: (_, _) => const ProfessionnelsListScreen(),
                routes: [
                  GoRoute(
                    path: 'recherche',
                    builder: (_, _) => const RechercheScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.rendezVous,
                builder: (_, _) => const RendezVousScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profil,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // --- Écrans plein écran, au-dessus de la barre de navigation ---
      _fadeRoute(
        AppRoutes.orientationIntro,
        (_) => const OrientationIntroScreen(),
      ),
      _fadeRoute(
        AppRoutes.orientation,
        (_) => const OrientationQuestionnaireScreen(),
      ),
      _fadeRoute(
        AppRoutes.orientationResult,
        (_) => const OrientationResultScreen(),
      ),
      GoRoute(
        path: AppRoutes.dossiers,
        builder: (_, _) => const DossiersScreen(),
      ),
      GoRoute(
        path: AppRoutes.messagerie,
        builder: (_, _) => const MessagerieScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.messagerie}/:id',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ConversationDetailScreen(
            conversationId: state.pathParameters['id']!,
            participantName: extra['name'] as String? ?? 'Discussion',
            participantRole: extra['role'] as String? ?? 'AVOCAT',
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.professionnels}/:id',
        builder: (context, state) => ProfessionnelDetailScreen(
          professionnelId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.professionnels}/:id/creneau',
        builder: (context, state) => ChoixCreneauScreen(
          professionnelId: state.pathParameters['id']!,
          initialTarif: state.extra as ProfessionalTarif?,
        ),
      ),
      GoRoute(
        path: AppRoutes.rendezVousConfirmation,
        builder: (context, state) => RendezVousConfirmationScreen(
          bookingData: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/contenus/:id',
        builder: (context, state) =>
            ContenuDetailScreen(contenuId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.suiviPsychologique,
        builder: (_, _) => const SuiviPsychologiqueScreen(),
      ),
      GoRoute(
        path: AppRoutes.paiements,
        builder: (_, _) => const PaiementsScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Durée commune des fondus : courte, pour une navigation fluide.
const _fadeDuration = Duration(milliseconds: 250);

GoRoute _fadeRoute(String path, Widget Function(GoRouterState) builder) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => _fadePage(state, builder(state)),
  );
}

Page<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: _fadeDuration,
    reverseTransitionDuration: _fadeDuration,
    transitionsBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

/// URL inconnue (lien profond obsolète…) : retour à l'accueil, que le guard
/// redirigera vers le bon écran selon la session.
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_outlined, size: 56),
              const SizedBox(height: 16),
              const Text('Page introuvable', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text("Retour à l'accueil"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
