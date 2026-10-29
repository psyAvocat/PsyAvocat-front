import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../firebase_options.dart';
import '../../../../core/l10n/app_strings.dart';

/// Source de données concrète utilisant Firebase Authentication.
/// Règle stricte : mécanisme réel sans mock ni session indépendante.
class FirebaseAuthDatasource {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthDatasource({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Utilisateur actuellement connecté
  User? get currentUser => _firebaseAuth.currentUser;

  /// Nom du compte connecté tel que fourni par Google (connexion Google).
  String? get displayName => _firebaseAuth.currentUser?.displayName;

  /// Initialisation unique du module Google. Android : identifiants lus dans
  /// google-services.json. iOS : identifiant client de firebase_options.dart
  /// (GoogleService-Info.plist n'est pas embarqué dans le projet Xcode).
  static Future<void>? _initialisationGoogle;

  Future<void> _initialiserGoogle() async {
    final ios = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final enCours = _initialisationGoogle ??= GoogleSignIn.instance.initialize(
      clientId: ios ? DefaultFirebaseOptions.ios.iosClientId : null,
    );
    try {
      await enCours;
    } catch (_) {
      _initialisationGoogle = null;
      rethrow;
    }
  }

  /// Connexion avec Google : choix du compte Google de l'appareil, puis
  /// connexion Firebase avec son jeton (le compte Firebase est créé à la
  /// première connexion). Renvoie `null` si l'utilisateur a renoncé.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _initialiserGoogle();
      final compte = await GoogleSignIn.instance.authenticate();
      final jeton = compte.authentication.idToken;
      if (jeton == null) {
        throw AuthException(
          tr("La connexion Google n'a pas abouti. Réessayez."),
        );
      }
      return await _firebaseAuth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: jeton),
      );
    } on GoogleSignInException catch (e) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
          return null;
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          throw AuthException(
            tr(
              "La connexion Google n'est pas encore configurée pour cette application.",
            ),
            code: 'google-configuration',
          );
        default:
          throw AuthException(
            tr("La connexion Google n'a pas abouti. Réessayez."),
            code: 'google',
          );
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message), code: e.code);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(
        tr("La connexion Google n'a pas abouti. Réessayez."),
        code: 'google',
      );
    }
  }

  /// Flux réactif des changements d'état d'authentification
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Récupération du jeton Firebase ID pour transmission à Spring Boot
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return await user.getIdToken(forceRefresh);
  }

  /// Connexion avec Email et Mot de passe
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message), code: e.code);
    } catch (_) {
      throw AuthException(
        tr(
          "Connexion impossible. Vérifiez votre connexion Internet et réessayez.",
        ),
      );
    }
  }

  /// Inscription avec Email et Mot de passe
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message), code: e.code);
    } catch (_) {
      throw AuthException(
        tr(
          "Inscription impossible. Vérifiez votre connexion Internet et réessayez.",
        ),
      );
    }
  }

  /// Déconnexion (Firebase, et Google pour proposer à nouveau le choix du
  /// compte à la prochaine connexion Google).
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (_initialisationGoogle != null) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Sans incidence : la session Firebase est déjà fermée.
      }
    }
  }

  /// Réinitialisation de mot de passe
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message), code: e.code);
    } catch (_) {
      throw AuthException(
        tr(
          "Impossible d'envoyer l'email de réinitialisation. Réessayez plus tard.",
        ),
      );
    }
  }

  /// Envoie l'email de confirmation d'adresse à l'utilisateur connecté.
  Future<void> sendEmailVerification() async {
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message), code: e.code);
    } catch (_) {
      throw AuthException(
        tr(
          "Impossible d'envoyer l'email de confirmation. Réessayez plus tard.",
        ),
      );
    }
  }

  /// Recharge l'utilisateur puis force un nouveau jeton : le backend lit
  /// `email_verified` dans le jeton, qui n'est pas mis à jour sans cela.
  Future<void> reloadUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    await user.reload();
    await _firebaseAuth.currentUser?.getIdToken(true);
  }

  String _mapFirebaseError(String code, String? defaultMessage) {
    switch (code) {
      case 'user-not-found':
        return tr('Aucun utilisateur ne correspond à cette adresse email.');
      case 'wrong-password':
      case 'invalid-credential':
        return tr('Identifiants incorrects. Veuillez vérifier votre saisie.');
      case 'email-already-in-use':
        return tr('Cette adresse email est déjà associée à un compte.');
      case 'invalid-email':
        return tr('L\'adresse email saisie est invalide.');
      case 'weak-password':
        return tr('Le mot de passe choisi est trop faible.');
      case 'user-disabled':
        return tr('Ce compte utilisateur a été désactivé.');
      case 'too-many-requests':
        return tr(
          'Trop de tentatives. Patientez quelques minutes avant de réessayer.',
        );
      case 'network-request-failed':
        return tr('Connexion Internet indisponible. Vérifiez votre réseau.');
      case 'requires-recent-login':
        return tr('Par sécurité, reconnectez-vous puis réessayez.');
      case 'operation-not-allowed':
        return tr("Ce mode de connexion n'est pas disponible pour le moment.");
      case 'account-exists-with-different-credential':
        return tr(
          'Un compte existe déjà avec cette adresse email : connectez-vous avec votre mot de passe.',
        );
      default:
        // Jamais le message technique de Firebase.
        return tr(
          "Une erreur d'authentification est survenue. Veuillez réessayer.",
        );
    }
  }

  /// Supprime le compte Firebase connecté (annulation d'une inscription inachevée).
  Future<void> deleteCurrentUser() async {
    await _firebaseAuth.currentUser?.delete();
  }
}
