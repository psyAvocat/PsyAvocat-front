import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/app_exception.dart';

/// Source de données concrète utilisant Firebase Authentication.
/// Règle stricte : mécanisme réel sans mock ni session indépendante.
class FirebaseAuthDatasource {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthDatasource({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Utilisateur actuellement connecté
  User? get currentUser => _firebaseAuth.currentUser;

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
      throw AuthException(_mapFirebaseError(e.code, e.message));
    } catch (_) {
      throw const AuthException(
        "Connexion impossible. Vérifiez votre connexion Internet et réessayez.",
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
      throw AuthException(_mapFirebaseError(e.code, e.message));
    } catch (_) {
      throw const AuthException(
        "Inscription impossible. Vérifiez votre connexion Internet et réessayez.",
      );
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Réinitialisation de mot de passe
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message));
    } catch (_) {
      throw const AuthException(
        "Impossible d'envoyer l'email de réinitialisation. Réessayez plus tard.",
      );
    }
  }

  /// Envoie l'email de confirmation d'adresse à l'utilisateur connecté.
  Future<void> sendEmailVerification() async {
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message));
    } catch (_) {
      throw const AuthException(
        "Impossible d'envoyer l'email de confirmation. Réessayez plus tard.",
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
        return 'Aucun utilisateur ne correspond à cette adresse email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Identifiants incorrects. Veuillez vérifier votre saisie.';
      case 'email-already-in-use':
        return 'Cette adresse email est déjà associée à un compte.';
      case 'invalid-email':
        return 'L\'adresse email saisie est invalide.';
      case 'weak-password':
        return 'Le mot de passe choisi est trop faible.';
      case 'user-disabled':
        return 'Ce compte utilisateur a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives. Patientez quelques minutes avant de réessayer.';
      case 'network-request-failed':
        return 'Connexion Internet indisponible. Vérifiez votre réseau.';
      case 'requires-recent-login':
        return 'Par sécurité, reconnectez-vous puis réessayez.';
      case 'operation-not-allowed':
        return "Ce mode de connexion n'est pas disponible pour le moment.";
      default:
        // Jamais le message technique de Firebase.
        return "Une erreur d'authentification est survenue. Veuillez réessayer.";
    }
  }

  /// Supprime le compte Firebase connecté (annulation d'une inscription inachevée).
  Future<void> deleteCurrentUser() async {
    await _firebaseAuth.currentUser?.delete();
  }
}
