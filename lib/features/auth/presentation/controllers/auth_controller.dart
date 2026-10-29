import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/network_providers.dart';
import '../../../profile/data/repositories/profil_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/pending_registration_store.dart';
import '../../data/repositories/session_repository.dart';
import 'session_controller.dart';

/// Actions d'authentification déclenchées par les écrans.
///
/// La navigation n'est PAS décidée ici : le routeur réagit à [sessionControllerProvider]
/// (Firebase → `GET /me` → rôle réel). L'état indique seulement chargement / erreur.
class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

  /// Connexion Firebase, puis vérification du compte (`GET /me`) par la session.
  ///
  /// La vérification est lancée ici et non seulement sur l'événement Firebase :
  /// se reconnecter au compte DÉJÀ connecté dans Firebase (par exemple après un
  /// échec de `/me` à la fin de l'inscription) n'émet aucun `authStateChanges`,
  /// et l'utilisateur resterait bloqué sur l'écran de connexion.
  Future<bool> signIn({required String email, required String password}) {
    return _run(() async {
      await _authRepository.signIn(email: email, password: password);
      await ref.read(sessionControllerProvider.notifier).resolve();
    });
  }

  /// Connexion (ou première inscription) avec Google. Compte déjà inscrit :
  /// accès direct ; premier passage : la session demande de compléter le
  /// profil (téléphone). Fenêtre Google fermée : rien ne se passe.
  Future<bool> signInWithGoogle() {
    return _run(() async {
      final connexion = await _authRepository.signInWithGoogle();
      if (connexion == null) return;
      await ref.read(sessionControllerProvider.notifier).resolve();
    });
  }

  /// Compte connecté sans profil (première connexion Google, inscription
  /// commencée sur un autre appareil) : le profil client est créé, puis la
  /// session vérifie l'accès.
  Future<bool> completerProfil({
    required String prenom,
    required String nom,
    required String telephone,
  }) {
    return _run(() async {
      await ref
          .read(profilRepositoryProvider)
          .createClientProfile(nom: nom, prenom: prenom, telephone: telephone);
      await ref.read(sessionControllerProvider.notifier).resolve();
    });
  }

  /// Inscription : compte Firebase + profil client unique dans le backend.
  /// Le compte reste connecté : la session vérifie `GET /me`, puis le routeur
  /// ouvre le choix de l'univers. Aucune information n'est redemandée ensuite :
  ///
  /// - les informations saisies sont gardées sur l'appareil jusqu'à la
  ///   confirmation du serveur ; si la réponse est perdue (réseau, délai
  ///   dépassé, 5xx), la session crée le profil avec elles ;
  /// - si le backend REFUSE le profil (4xx : téléphone déjà utilisé, données
  ///   invalides…), rien n'a été créé côté serveur : le compte Firebase créé
  ///   est supprimé pour pouvoir recommencer proprement ;
  /// - si l'adresse a déjà un compte Firebase SANS profil (inscription
  ///   interrompue ailleurs), ce compte est repris avec le même mot de passe.
  Future<bool> register({
    required String prenom,
    required String nom,
    required String telephone,
    required String email,
    required String password,
  }) {
    final session = ref.read(sessionControllerProvider.notifier);
    final pendingStore = ref.read(pendingRegistrationStoreProvider);
    return _run(() async {
      session.beginRegistration();
      try {
        final accountCreated = await _signUpOrResume(email, password);
        final uid = _authRepository.currentUser!.uid;
        await pendingStore.save(
          uid,
          PendingRegistration(nom: nom, prenom: prenom, telephone: telephone),
        );
        try {
          await ref
              .read(profilRepositoryProvider)
              .createClientProfile(
                nom: nom,
                prenom: prenom,
                telephone: telephone,
              );
          await pendingStore.clear(uid);
        } catch (error) {
          if (!_isRejectedByServer(error)) {
            // Réponse perdue : la session vérifie /me et crée le profil si besoin.
            return;
          }
          await pendingStore.clear(uid);
          if (accountCreated) {
            await _authRepository.deleteCurrentUser();
          } else {
            await _authRepository.signOut();
          }
          rethrow;
        }
      } finally {
        await session.endRegistration();
      }
    });
  }

  /// Crée le compte Firebase (`true`), ou reprend un compte existant sans
  /// profil métier (`false`) quand l'adresse est déjà utilisée.
  Future<bool> _signUpOrResume(String email, String password) async {
    try {
      await _authRepository.signUp(email: email, password: password);
      return true;
    } on AuthException catch (error) {
      if (error.code != 'email-already-in-use') rethrow;
      try {
        await _authRepository.signIn(email: email, password: password);
      } catch (_) {
        // Mot de passe différent : le compte appartient à quelqu'un d'autre.
        throw error;
      }
      // Compte déjà complet : c'est une connexion, pas une inscription.
      if (await _hasBusinessProfile()) {
        await _authRepository.signOut();
        rethrow;
      }
      return false;
    }
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
