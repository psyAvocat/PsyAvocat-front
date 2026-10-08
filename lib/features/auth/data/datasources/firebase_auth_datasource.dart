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

  /// Inscription (alias conforme aux spécifications)
  Future<UserCredential> register(String email, String password) =>
      signUpWithEmailAndPassword(email: email, password: password);

  /// Connexion (alias conforme aux spécifications)
  Future<UserCredential> login(String email, String password) =>
      signInWithEmailAndPassword(email: email, password: password);

  /// Déconnexion (alias conforme aux spécifications)
  Future<void> logout() => signOut();

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

  /// Changement de mot de passe : ré-authentification puis mise à jour.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthException('Session expirée. Veuillez vous reconnecter.');
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code, e.message));
    }
  }
}
