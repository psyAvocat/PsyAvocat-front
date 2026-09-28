import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/selection_univers/presentation/screens/selection_univers_screen.dart';
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
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
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
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final location = state.matchedLocation;

      // Laisser le SplashScreen gérer sa transition fluide
      if (location == '/splash') {
        return null;
      }

      final isLoggedIn = authState.asData?.value != null;
      final isAuthRoute = location == '/login' ||
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
      final isProtectedRoute = location == '/home' || location == '/selection-univers';
      if (!isLoggedIn && isProtectedRoute) {
        final hasSeenOnboarding = prefs.hasSeenOnboarding();
        return hasSeenOnboarding ? '/login' : '/onboarding';
      }

      return null;
    },
  );
});
