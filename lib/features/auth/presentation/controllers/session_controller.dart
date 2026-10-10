import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/network/api_logger_interceptor.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/push/push_service.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../data/models/current_user.dart';
import '../../data/repositories/session_repository.dart';
import '../utils/auth_navigation.dart';

/// Étapes de la session, dans l'ordre du parcours :
/// Firebase → `GET /me` → rôle réel → accès.
enum SessionStatus {
  /// Démarrage : état Firebase pas encore connu.
  unknown,

  /// Personne n'est connecté.
  unauthenticated,

  /// Connecté à Firebase, identité backend en cours de chargement (`/me`).
  loading,

  /// Client autorisé.
  authorized,

  /// Compte sans profil métier (inscription interrompue) : le profil doit être complété.
  profileIncomplete,

  /// Client dont l'adresse email n'est pas encore confirmée.
  emailNotVerified,

  /// Accès refusé (professionnel, administrateur ou compte désactivé) ; déconnecté.
  denied,

  /// `/me` injoignable : on ne laisse PAS passer, on propose de réessayer.
  error,
}

class SessionState {
  final SessionStatus status;
  final CurrentUser? user;

  /// Message à afficher (refus d'accès ou erreur).
  final String? message;

  const SessionState(this.status, {this.user, this.message});

  bool get isAuthorized => status == SessionStatus.authorized;
}

/// Source de vérité unique de la session, consultée par le routeur (guards).
///
/// Écoute Firebase Authentication ; à chaque connexion, interroge `GET /me`
/// et applique [evaluateAccess]. Aucun rôle n'est déduit localement.
class SessionController extends Notifier<SessionState> {
  StreamSubscription<Object?>? _authSubscription;

  /// Message de refus à conserver après la déconnexion forcée qui suit un refus.
  String? _pendingDeniedMessage;

  /// Pendant une inscription, la connexion Firebase automatique ne doit pas
  /// déclencher de navigation (le compte est déconnecté juste après).
  bool _registrationInProgress = false;

  @override
  SessionState build() {
    final authRepository = ref.watch(authRepositoryProvider);
    _authSubscription = authRepository.authStateChanges.listen(_onFirebaseUser);
    ref.onDispose(() => _authSubscription?.cancel());

    if (authRepository.currentUser == null) {
      return const SessionState(SessionStatus.unauthenticated);
    }
    // Session Firebase restaurée : l'identité backend est chargée juste après.
    Future.microtask(resolve);
    return const SessionState(SessionStatus.loading);
  }

  void _onFirebaseUser(Object? firebaseUser) {
    if (_registrationInProgress) return;
    if (firebaseUser == null) {
      final denied = _pendingDeniedMessage;
      _pendingDeniedMessage = null;
      // Refus déjà affiché : la déconnexion qui le suit ne doit pas l'effacer.
      if (denied == null && state.status == SessionStatus.denied) return;
      state = denied != null
          ? SessionState(SessionStatus.denied, message: denied)
          : const SessionState(SessionStatus.unauthenticated);
      return;
    }
    if (state.status != SessionStatus.loading) {
      resolve();
    }
  }

  /// Charge l'identité backend (`GET /me`) et décide de l'accès.
  Future<void> resolve() async {
    if (ref.read(authRepositoryProvider).currentUser == null) {
      state = const SessionState(SessionStatus.unauthenticated);
      return;
    }
    state = const SessionState(SessionStatus.loading);
    apiLog('Session : vérification du compte (GET /me)…');
    try {
      ref.invalidate(currentUserProvider);
      final user = await ref.read(currentUserProvider.future);

      final decision = evaluateAccess(user);
      apiLog('Session : /me OK → décision d’accès : ${decision.name}');
      switch (decision) {
        case AccessDecision.authorized:
          state = SessionState(SessionStatus.authorized, user: user);
        case AccessDecision.profileIncomplete:
          state = SessionState(SessionStatus.profileIncomplete, user: user);
        case AccessDecision.emailNotVerified:
          state = SessionState(SessionStatus.emailNotVerified, user: user);
        case AccessDecision.deniedProfessional:
          await _deny(professionalAccountMessage);
        case AccessDecision.deniedDeactivated:
          await _deny(deactivatedAccountMessage);
      }
    } catch (error) {
      apiLog('Session : /me en échec → ${error.runtimeType} : $error');
      // Échec sûr : sans réponse fiable de /me, aucun accès n'est accordé.
      state = SessionState(SessionStatus.error, message: userMessageFor(error));
    }
  }

  /// Le backend a refusé le compte en cours de session (403 `ACCOUNT_DISABLED`
  /// ou `EMAIL_NOT_VERIFIED`) : l'accès est réévalué via `GET /me`.
  /// Plusieurs requêtes refusées en même temps ne déclenchent qu'une vérification.
  void revalidate() {
    if (state.status == SessionStatus.loading) return;
    resolve();
  }

  /// Après création du profil manquant : l'accès est réévalué.
  Future<void> refreshAfterProfileCreation() => resolve();

  /// L'utilisateur indique avoir cliqué sur le lien : le jeton est renouvelé
  /// (le backend lit `email_verified` dans le jeton), puis l'accès réévalué.
  Future<void> confirmEmailVerified() async {
    await ref.read(authRepositoryProvider).reloadUser();
    await resolve();
  }

  Future<void> resendVerificationEmail() =>
      ref.read(authRepositoryProvider).sendEmailVerification();

  /// Déconnexion volontaire : Firebase + nettoyage des états locaux sensibles.
  /// La connexion temps réel se ferme d'elle-même sur ce changement d'état.
  Future<void> signOut() async {
    // Retrait de l'appareil tant que le jeton Firebase est encore valide.
    try {
      await ref.read(pushServiceProvider).unregister();
    } catch (_) {
      // Push indisponible (plateforme non prise en charge) : rien à retirer.
    }
    await ref.read(appPreferencesServiceProvider).clearSelectedUniverse();
    await ref.read(currentUniverseProvider.notifier).resetToNeutral();
    ref.invalidate(currentUserProvider);
    await ref.read(authRepositoryProvider).signOut();
    state = const SessionState(SessionStatus.unauthenticated);
  }

  /// Après lecture du message « accès refusé » : retour à l'écran de connexion.
  void acknowledgeDenied() {
    if (state.status == SessionStatus.denied) {
      state = const SessionState(SessionStatus.unauthenticated);
    }
  }

  void beginRegistration() => _registrationInProgress = true;

  void endRegistration() {
    _registrationInProgress = false;
    state = const SessionState(SessionStatus.unauthenticated);
  }

  Future<void> _deny(String message) async {
    _pendingDeniedMessage = message;
    // Plus d'univers enregistré : l'accueil ne pourra plus être rouvert
    // directement au prochain démarrage (voir route_guard.dart).
    await ref.read(appPreferencesServiceProvider).clearSelectedUniverse();
    await ref.read(currentUniverseProvider.notifier).resetToNeutral();
    ref.invalidate(currentUserProvider);
    await ref.read(authRepositoryProvider).signOut();
    // Si Firebase n'émet pas d'événement (déjà déconnecté), on applique le refus ici.
    state = SessionState(SessionStatus.denied, message: message);
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
