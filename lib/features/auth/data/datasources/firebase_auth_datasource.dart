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
    } catch (e) {
      throw AuthException('Échec de connexion : ${e.toString()}');
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
    } catch (e) {
      throw AuthException('Échec d\'inscription : ${e.toString()}');
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
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
      case 'operation-not-allowed':
        return 'L\'authentification par email/mot de passe n\'est pas activée sur Firebase Console.';
      default:
        return defaultMessage ?? 'Une erreur d\'authentification est survenue.';
    }
  }
}
