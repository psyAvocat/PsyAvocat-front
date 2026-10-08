import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../../profile/data/repositories/profil_repository.dart';
import '../../data/repositories/auth_repository.dart';
import 'session_controller.dart';

/// Actions d'authentification déclenchées par les écrans.
///
/// La navigation n'est PAS décidée ici : le routeur réagit à [sessionControllerProvider]
/// (Firebase → `GET /me` → rôle réel). L'état indique seulement chargement / erreur.
class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  /// Connexion Firebase. La suite (identité backend, accès) est gérée par la session.
  Future<bool> signIn({required String email, required String password}) {
    return _run(() => _authRepository.signIn(email: email, password: password));
  }

  /// Inscription : compte Firebase + profil client unique dans le backend,
  /// puis déconnexion : l'utilisateur revient DIRECTEMENT à l'écran de connexion.
  ///
  /// Si le profil ne peut pas être créé (ex. téléphone déjà utilisé), le compte
  /// Firebase est supprimé pour pouvoir recommencer proprement.
  Future<bool> register({
    required String prenom,
    required String nom,
    required String telephone,
    required String email,
    required String password,
  }) {
    final session = ref.read(sessionControllerProvider.notifier);
    return _run(() async {
      session.beginRegistration();
      try {
        await _authRepository.signUp(email: email, password: password);
        try {
          await ref.read(profilRepositoryProvider).createClientProfile(
            nom: nom,
            prenom: prenom,
            telephone: telephone,
          );
        } catch (_) {
          await _authRepository.deleteCurrentUser();
          rethrow;
        }
      } finally {
        if (_authRepository.currentUser != null) {
          await _authRepository.signOut();
        }
        session.endRegistration();
      }
    });
  }

  Future<bool> sendPasswordResetEmail({required String email}) {
    return _run(() => _authRepository.sendPasswordResetEmail(email));
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _run(() => _authRepository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    ));
  }

  /// Exécute [action] : chargement → succès (true) / erreur (false, voir `state.error`).
  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);
