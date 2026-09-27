import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../network/network_providers.dart';

/// Provider pour la configuration GoRouter de l'application PsyAvocat.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authState.asData?.value != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Si l'utilisateur est connecté et se trouve sur login/register, redirection vers /home
      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      // Si l'utilisateur n'est pas connecté et tente d'accéder à /home, redirection vers /login
      if (!isLoggedIn && state.matchedLocation == '/home') {
        return '/login';
      }

      return null;
    },
  );
});
