import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/network/api_logger_interceptor.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/push/push_service.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/theme/universe_provider.dart';
import '../../../profile/data/repositories/profil_repository.dart';
import '../../data/models/current_user.dart';
import '../../data/repositories/pending_registration_store.dart';
import '../../data/repositories/session_repository.dart';
import '../utils/auth_navigation.dart';
import '../../../../core/l10n/app_strings.dart';

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

  /// Client dont l'adresse email n'est pas encore confirmée.
  emailNotVerified,

  /// Connecté sans profil PsyAvocat (première connexion Google, inscription
  /// commencée sur un autre appareil) : prénom, nom et téléphone à compléter.
  profileToComplete,

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
  /// déclencher `GET /me` avant la création du profil (voir [endRegistration]).
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

  /// Vérification en cours : la connexion explicite (AuthController) et
  /// l'événement Firebase qui la suit ne déclenchent qu'un seul `GET /me`.
  Future<void>? _resolving;

  /// Charge l'identité backend (`GET /me`) et décide de l'accès.
  Future<void> resolve() =>
      _resolving ??= _resolve().whenComplete(() => _resolving = null);

  Future<void> _resolve() async {
    if (ref.read(authRepositoryProvider).currentUser == null) {
      state = const SessionState(SessionStatus.unauthenticated);
      return;
    }
    // Revérification d'une session déjà ouverte : l'écran courant reste affiché
    // (jamais de retour au splash au milieu du parcours).
    if (!state.isAuthorized) state = const SessionState(SessionStatus.loading);
    apiLog('Session : vérification du compte (GET /me)…');
    try {
      var user = await _fetchCurrentUser();
      var decision = evaluateAccess(user);
      apiLog('Session : /me OK → décision d’accès : ${decision.name}');
      if (decision == AccessDecision.profileIncomplete) {
        if (!await _completeRegistration()) return;
        user = await _fetchCurrentUser();
        decision = evaluateAccess(user);
        apiLog('Session : profil créé → décision d’accès : ${decision.name}');
      }
      switch (decision) {
        case AccessDecision.authorized:
          state = SessionState(SessionStatus.authorized, user: user);
        case AccessDecision.profileIncomplete:
          // Profil toujours absent juste après sa création : réessai plus tard.
          state = SessionState(
            SessionStatus.error,
            message: tr('Votre profil est en cours de création. Réessayez.'),
          );
        case AccessDecision.emailNotVerified:
          state = SessionState(SessionStatus.emailNotVerified, user: user);
        case AccessDecision.deniedProfessional:
          await _deny(professionalAccountMessage);
        case AccessDecision.deniedDeactivated:
          await _deny(deactivatedAccountMessage);
      }
    } catch (error) {
      apiLog('Session : /me en échec → ${error.runtimeType} : $error');
      // Session déjà validée : une revérification en échec (réseau) ne déconnecte
      // pas l'utilisateur ; les refus réels du serveur (403) passent par revalidate.
      if (state.isAuthorized) return;
      // Échec sûr : sans réponse fiable de /me, aucun accès n'est accordé.
      state = SessionState(SessionStatus.error, message: userMessageFor(error));
    }
  }

  Future<CurrentUser> _fetchCurrentUser() {
    ref.invalidate(currentUserProvider);
    return ref.read(currentUserProvider.future);
  }

  /// Compte Firebase sans profil métier. Inscription interrompue sur cet
  /// appareil (serveur injoignable au moment de créer le profil) : le profil
  /// est créé avec les informations saisies, gardées sur l'appareil, sans rien
  /// redemander. Renvoie `true` si le profil a été créé.
  ///
  /// Sans ces informations (première connexion Google, inscription commencée
  /// sur un autre appareil) : l'écran « Compléter votre profil » les demande.
  /// Si le serveur refuse les informations gardées, l'utilisateur est
  /// déconnecté et invité à se réinscrire. Une erreur réseau remonte à
  /// [_resolve] (état `error`, nouvel essai possible).
  Future<bool> _completeRegistration() async {
    final uid = ref.read(authRepositoryProvider).currentUser!.uid;
    final store = ref.read(pendingRegistrationStoreProvider);
    final pending = store.read(uid);
    if (pending == null) {
      state = const SessionState(SessionStatus.profileToComplete);
      return false;
    }
    try {
      await ref
          .read(profilRepositoryProvider)
          .createClientProfile(
            nom: pending.nom,
            prenom: pending.prenom,
            telephone: pending.telephone,
          );
    } catch (error) {
      final status = error is AppException ? error.statusCode : null;
      if (status == null || status < 400 || status >= 500) rethrow;
      await store.clear(uid);
      await _signOutWithMessage(
        '${userMessageFor(error)} ${tr(incompleteRegistrationMessage)}',
      );
      return false;
    }
    await store.clear(uid);
    return true;
  }

  /// Déconnexion avec un message affiché sur l'écran de connexion.
  Future<void> _signOutWithMessage(String message) async {
    await signOut();
    state = SessionState(SessionStatus.unauthenticated, message: message);
  }

  /// Le backend a refusé le compte en cours de session (403 `ACCOUNT_DISABLED`
  /// ou `EMAIL_NOT_VERIFIED`) : l'accès est réévalué via `GET /me`.
  /// Plusieurs requêtes refusées en même temps ne déclenchent qu'une vérification.
  void revalidate() {
    if (state.status == SessionStatus.loading) return;
    resolve();
  }

  /// Jeton refusé par le backend même après rafraîchissement : la session est
  /// fermée (aucun écran protégé ne reste accessible), retour à la connexion.
  Future<void> expireSession() async {
    if (_expiring || state.status == SessionStatus.unauthenticated) return;
    _expiring = true;
    try {
      await signOut();
    } finally {
      _expiring = false;
    }
  }

  /// Plusieurs requêtes refusées en même temps ne ferment la session qu'une fois.
  bool _expiring = false;

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
  /// L'univers est oublié : il est choisi à nouveau après la prochaine connexion.
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

  /// Fin de l'inscription : le compte créé est connecté immédiatement
  /// (identité vérifiée via `GET /me`, puis choix de l'univers).
  Future<void> endRegistration() async {
    _registrationInProgress = false;
    if (ref.read(authRepositoryProvider).currentUser != null) {
      await resolve();
    } else {
      state = const SessionState(SessionStatus.unauthenticated);
    }
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

/// Compte connecté et autorisé, ou `null` sans session autorisée (déconnexion,
/// vérification du compte en cours). L'application n'a pas de mode invité.
///
/// Les données personnelles (rendez-vous, notifications, profil…) le surveillent :
/// elles restent vides sans session — aucun appel protégé n'est envoyé — et
/// se rechargent à chaque connexion, déconnexion ou changement de compte.
final signedInAccountProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionControllerProvider);
  if (!session.isAuthorized) return null;
  return session.user?.userId ?? session.user?.email;
});
