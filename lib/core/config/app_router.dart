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
import '../../features/orientation/presentation/screens/orientation_matching_screen.dart';
import '../../features/orientation/presentation/screens/orientation_questionnaire_screen.dart';
import '../../features/orientation/presentation/screens/orientation_recap_screen.dart';
import '../../features/professionnels/data/models/professional_detail_model.dart';
import '../../features/professionnels/presentation/screens/professionnel_detail_screen.dart';
import '../../features/professionnels/presentation/screens/professionnels_list_screen.dart';
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

/// Provider pour la configuration GoRouter de l'application PsyAvocat (Phase 2).
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final prefs = ref.watch(appPreferencesServiceProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/selection-univers',
        builder: (context, state) => const SelectionUniversScreen(),
      ),
      // Navigation principale avec Navbar flottante (Étape 1)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Onglet 0 : Accueil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Onglet 1 : Professionnels
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/professionnels',
                builder: (context, state) => const ProfessionnelsListScreen(),
              ),
            ],
          ),
          // Onglet 2 : Rendez-vous (Bouton central surélevé)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rendez-vous',
                builder: (context, state) => const RendezVousScreen(),
              ),
            ],
          ),
          // Onglet 3 : Mes dossiers
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dossiers',
                builder: (context, state) => const DossiersScreen(),
              ),
            ],
          ),
          // Onglet 4 : Profil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profil',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Messagerie & discussions
      GoRoute(
        path: '/messagerie',
        builder: (context, state) => const MessagerieScreen(),
      ),
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

      // Questionnaire d'Orientation & Matching (Étape 2)
      GoRoute(
        path: '/orientation',
        builder: (context, state) => const OrientationQuestionnaireScreen(),
      ),
      GoRoute(
        path: '/orientation/recap',
        builder: (context, state) => const OrientationRecapScreen(),
      ),
      GoRoute(
        path: '/orientation/matching',
        builder: (context, state) => const OrientationMatchingScreen(),
      ),

      // Fiche détaillée du professionnel (Étape 4)
      GoRoute(
        path: '/professionnels/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ProfessionnelDetailScreen(professionnelId: id);
        },
      ),

      // Choix du créneau horaire en direct (Étape 4)
      GoRoute(
        path: '/professionnels/:id/creneau',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final tarif = state.extra as ProfessionalTarif?;
          return ChoixCreneauScreen(professionnelId: id, initialTarif: tarif);
        },
      ),

      // Confirmation du rendez-vous (Étape 5)
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
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Bibliothèque de contenus & articles
      GoRoute(
        path: '/contenus',
        builder: (context, state) => const ContenusScreen(),
      ),
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
        builder: (context, state) => const SuiviPsychologiqueScreen(),
      ),

      // Historique des paiements & Reçus
      GoRoute(
        path: '/paiements',
        builder: (context, state) => const PaiementsScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final location = state.matchedLocation;

      // Laisser le SplashScreen gérer sa transition fluide
      if (location == '/splash') {
        return null;
      }

      final isLoggedIn = authState.asData?.value != null;
      final isAuthRoute =
          location == '/login' ||
          location == '/register' ||
          location == '/forgot-password' ||
          location == '/onboarding';

      // 1. Utilisateur connecté tentant d'accéder aux écrans de connexion/inscription/onboarding
      if (isLoggedIn && isAuthRoute) {
        final universe = prefs.getSelectedUniverse();
        if (universe != null && !universe.isNeutral) {
          return '/home';
        }
        return '/selection-univers';
      }

      // 2. Utilisateur non connecté tentant d'accéder à des écrans protégés
      final isProtectedRoute =
          location.startsWith('/home') ||
          location.startsWith('/professionnels') ||
          location.startsWith('/rendez-vous') ||
          location.startsWith('/dossiers') ||
          location.startsWith('/profil') ||
          location.startsWith('/messagerie') ||
          location.startsWith('/orientation') ||
          location == '/selection-univers';

      if (!isLoggedIn && isProtectedRoute) {
        final hasSeenOnboarding = prefs.hasSeenOnboarding();
        return hasSeenOnboarding ? '/login' : '/onboarding';
      }

      return null;
    },
  );
});
