import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../utils/auth_navigation.dart';
import 'pending_profile_controller.dart';

/// Contrôleur des actions d'authentification (Riverpod 3).
///
/// Parcours de connexion :
/// Firebase Authentication → ID Token → Spring Boot `GET /me` → rôle réel → route.
///
/// L'état ([AsyncValue]) indique à l'écran : chargement, erreur ou repos.
/// Les méthodes qui naviguent renvoient la route à ouvrir (ou `null` en cas d'échec).
class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  /// Connexion email / mot de passe.
  Future<String?> signIn({required String email, required String password}) {
    return _run(() async {
      await _authRepository.signIn(email: email, password: password);
      return _resolveRouteFromBackend();
    });
  }

  /// Session Firebase restaurée au démarrage : renvoie la route à ouvrir,
  /// ou `null` si personne n'est connecté.
  Future<String?> restoreSession() async {
    if (_authRepository.currentUser == null) return null;
    return _run(_resolveRouteFromBackend);
  }

  /// Inscription : crée le compte Firebase puis mémorise l'identité saisie.
  /// Le profil métier sera créé lors du choix de l'univers.
  Future<String?> signUp({
    required String prenom,
    required String nom,
    required String? telephone,
    required String email,
    required String password,
  }) {
    return _run(() async {
      final cred = await _authRepository.signUp(
        email: email,
        password: password,
      );
      try {
        await cred.user?.updateDisplayName('$prenom $nom');
      } catch (_) {}
      ref
          .read(pendingProfileProvider.notifier)
          .save(PendingProfile(prenom: prenom, nom: nom, telephone: telephone));

      // Règle 9 : Déconnexion immédiate de la session automatique Firebase
      await _authRepository.signOut();
      ref.invalidate(currentUserProvider);
      return '/login';
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.signOut();
      ref.invalidate(currentUserProvider);
    });
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authRepository.sendPasswordResetEmail(email),
    );
    return !state.hasError;
  }

  /// Interroge `GET /me` et choisit la route selon le rôle réel.
  Future<String> _resolveRouteFromBackend() async {
    ref.invalidate(currentUserProvider);
    final user = await ref.read(currentUserProvider.future);
    final savedUniverse = ref
        .read(appPreferencesServiceProvider)
        .getSelectedUniverse();

    final String route;
    try {
      route = resolvePostAuthRoute(user: user, savedUniverse: savedUniverse);
    } catch (_) {
      // Compte professionnel / admin : on ne garde pas de session sur le mobile.
      await _authRepository.signOut();
      rethrow;
    }

    if (route == '/home' && savedUniverse != null) {
      await ref
          .read(currentUniverseProvider.notifier)
          .setUniverse(savedUniverse);
    }
    return route;
  }

  /// Exécute [action] en mettant à jour l'état (chargement → succès / erreur).
  Future<String?> _run(Future<String> Function() action) async {
    state = const AsyncValue.loading();
    try {
      final route = await action();
      state = const AsyncValue.data(null);
      return route;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);
