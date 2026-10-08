import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/messagerie/presentation/screens/messagerie_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/dossiers/presentation/screens/dossiers_screen.dart';
import '../../features/navigation/presentation/main_navigation_shell.dart';
import '../../features/orientation/presentation/screens/orientation_intro_screen.dart';
import '../../features/orientation/presentation/screens/orientation_questionnaire_screen.dart';
import '../../features/orientation/presentation/screens/orientation_result_screen.dart';
import '../../features/professionnels/data/models/professional_detail_model.dart';
import '../../features/professionnels/presentation/screens/professionnel_detail_screen.dart';
import '../../features/professionnels/presentation/screens/professionnels_list_screen.dart';
import '../../features/professionnels/presentation/screens/recherche_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/rendez_vous/presentation/screens/choix_creneau_screen.dart';
import '../../features/rendez_vous/presentation/screens/rendez_vous_confirmation_screen.dart';
import '../../features/rendez_vous/presentation/screens/rendez_vous_screen.dart';
import '../../features/selection_univers/presentation/screens/selection_univers_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/contenus/presentation/screens/contenus_screen.dart';
import '../../features/contenus/presentation/screens/contenu_detail_screen.dart';
import '../../features/suivi_psychologique/presentation/screens/suivi_psychologique_screen.dart';
import '../../features/paiements/presentation/screens/paiements_screen.dart';
import '../network/network_providers.dart';
import '../services/app_preferences_service.dart';
import '../theme/app_universe.dart';

/// Routes accessibles sans être connecté.
const _publicRoutes = {
  '/splash',
  '/onboarding',
  '/login',
  '/register',
  '/forgot-password',
};

/// Configuration GoRouter de l'application PsyAvocat.
///
/// Le routeur est créé UNE seule fois : il est simplement « rafraîchi »
/// (redirect réévalué) quand l'état de connexion Firebase change.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final prefs = ref.watch(appPreferencesServiceProvider);
  final authRefresh = _StreamRefreshNotifier(authRepository.authStateChanges);
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authRefresh,
    redirect: (BuildContext context, GoRouterState state) {
      final location = state.matchedLocation;

      // Le splash décide lui-même de la suite (session restaurée ou non).
      if (location == '/splash') return null;

      final isLoggedIn = authRepository.currentUser != null;
      final isPublicRoute = _publicRoutes.contains(location);
      final hasSeenOnboarding = prefs.hasSeenOnboarding();

      // Utilisateur NON connecté :
      if (!isLoggedIn) {
        if (!isPublicRoute) {
          // Règle 8 : Si déjà vu, JAMAIS d'onboarding, aller au login
          return hasSeenOnboarding ? '/login' : '/onboarding';
        }
        // S'il tente d'accéder à l'onboarding alors qu'il l'a déjà vu
        if (location == '/onboarding' && hasSeenOnboarding) {
          return '/login';
        }
        return null;
      }

      // Utilisateur CONNECTÉ :
      // 1. Ne peut plus retourner sur les routes publiques
      if (location == '/login' ||
          location == '/register' ||
          location == '/onboarding') {
        return '/home';
      }

      // 2. Cloisonnement strict des univers (Règles 7, 10 & 14) :
      // L'avocat n'a jamais accès aux questionnaires d'orientation
      final currentUniverse = prefs.getSelectedUniverse();
      if (currentUniverse == AppUniverse.lawyer &&
          location.startsWith('/orientation')) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/selection-univers',
        builder: (_, _) => const SelectionUniversScreen(),
      ),

      // Navigation principale : 5 onglets (voir AppNavigationBar).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // 0. Accueil
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          // 1. Articles
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/articles',
                builder: (_, _) => const ContenusScreen(),
              ),
            ],
          ),
          // 2. Avocats ou Psychologues (selon l'univers)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/professionnels',
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
          // 3. Rendez-vous
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rendez-vous',
                builder: (_, _) => const RendezVousScreen(),
              ),
            ],
          ),
          // 4. Profil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profil',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Questionnaire d'orientation et résultat (Psychologue uniquement)
      GoRoute(
        path: '/orientation/intro',
        builder: (_, _) => const OrientationIntroScreen(),
      ),
      GoRoute(
        path: '/orientation',
        builder: (_, _) => const OrientationQuestionnaireScreen(),
      ),
      GoRoute(
        path: '/orientation/resultat',
        builder: (_, _) => const OrientationResultScreen(),
      ),

      // Dossiers juridiques
      GoRoute(path: '/dossiers', builder: (_, _) => const DossiersScreen()),

      // Messagerie & discussions
      GoRoute(path: '/messagerie', builder: (_, _) => const MessagerieScreen()),
      GoRoute(
        path: '/messagerie/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ConversationDetailScreen(
            conversationId: id,
            participantName: extra['name'] as String? ?? 'Discussion',
            participantRole: extra['role'] as String? ?? 'AVOCAT',
          );
        },
      ),

      // Fiche détaillée du professionnel
      GoRoute(
        path: '/professionnels/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ProfessionnelDetailScreen(professionnelId: id);
        },
      ),

      // Choix du créneau horaire
      GoRoute(
        path: '/professionnels/:id/creneau',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final tarif = state.extra as ProfessionalTarif?;
          return ChoixCreneauScreen(professionnelId: id, initialTarif: tarif);
        },
      ),

      // Confirmation du rendez-vous
      GoRoute(
        path: '/rendez-vous/confirmation',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return RendezVousConfirmationScreen(bookingData: extra);
        },
      ),

      // Centre de notifications
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),

      // Détail d'un article
      GoRoute(
        path: '/contenus/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ContenuDetailScreen(contenuId: id);
        },
      ),

      // Suivi & Bien-être psychologique
      GoRoute(
        path: '/suivi-psychologique',
        builder: (_, _) => const SuiviPsychologiqueScreen(),
      ),

      // Historique des paiements & Reçus
      GoRoute(path: '/paiements', builder: (_, _) => const PaiementsScreen()),
    ],
  );
});

/// Notifie GoRouter à chaque événement d'un Stream (ici : connexion / déconnexion).
class _StreamRefreshNotifier extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  _StreamRefreshNotifier(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
