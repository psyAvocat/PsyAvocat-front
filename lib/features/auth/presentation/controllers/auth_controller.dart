import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/network_providers.dart';
import '../../../profile/data/repositories/profil_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/session_repository.dart';
import 'session_controller.dart';

/// Inscription incomplète : le compte Firebase existe mais le profil n'a pas
/// pu être confirmé. Il sera complété à la prochaine connexion.
class IncompleteRegistrationException extends AppException {
  const IncompleteRegistrationException()
    : super(
        "Votre compte a été créé, mais votre profil n'a pas pu être "
        'enregistré. Connectez-vous pour le compléter.',
      );
}

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
  /// envoi de l'email de confirmation, puis déconnexion : l'utilisateur revient
  /// à l'écran de connexion.
  ///
  /// Si le backend REFUSE le profil (4xx : téléphone déjà utilisé, données
  /// invalides…), rien n'a été créé côté serveur : le compte Firebase est
  /// supprimé pour pouvoir recommencer proprement.
  /// Si la réponse est perdue (réseau, délai dépassé, 5xx), le profil a pu être
  /// créé : on vérifie via `GET /me` au lieu de supprimer le compte à l'aveugle.
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
        var profileCreated = true;
        try {
          await ref
              .read(profilRepositoryProvider)
              .createClientProfile(
                nom: nom,
                prenom: prenom,
                telephone: telephone,
              );
        } catch (error) {
          if (_isRejectedByServer(error)) {
            await _authRepository.deleteCurrentUser();
            rethrow;
          }
          profileCreated = await _hasBusinessProfile();
        }
        // Lien de confirmation : exigé par le backend avant tout accès client.
        // En cas d'échec, il pourra être renvoyé depuis l'écran de confirmation.
        try {
          await _authRepository.sendEmailVerification();
        } catch (_) {}
        if (!profileCreated) {
          throw const IncompleteRegistrationException();
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

  /// Refus explicite du backend (4xx) : la requête n'a rien créé.
  bool _isRejectedByServer(Object error) {
    final status = error is AppException ? error.statusCode : null;
    return status != null && status >= 400 && status < 500;
  }

  Future<bool> _hasBusinessProfile() async {
    try {
      final user = await ref.read(sessionRepositoryProvider).getCurrentUser();
      return user.hasMetierProfile;
    } catch (_) {
      return false;
    }
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
