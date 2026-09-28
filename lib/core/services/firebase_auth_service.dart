import 'package:firebase_auth/firebase_auth.dart';
import '../errors/app_exception.dart';

/// Service Firebase Authentication dédié et conforme aux spécifications PsyAvocat.
/// Utilise exclusivement FirebaseAuth.instance sans mock ni stockage local de mot de passe.
class FirebaseAuthService {
  final FirebaseAuth _auth;

  FirebaseAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  /// Utilisateur actuellement connecté
  User? get currentUser => _auth.currentUser;

  /// Flux d'écoute réactif des changements d'état d'authentification
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Récupération du Firebase ID Token
  /// Sécurité : Ne jamais logger, afficher dans l'UI ou stocker ce token dans un fichier.
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken(forceRefresh);
  }

  /// Inscription d'un nouvel utilisateur avec email et mot de passe
  Future<UserCredential> register(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapFirebaseError(e.code, e.message));
    } catch (e) {
      throw AuthException('Échec d\'inscription : ${e.toString()}');
    }
  }

  /// Connexion d'un utilisateur avec email et mot de passe
  Future<UserCredential> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapFirebaseError(e.code, e.message));
    } catch (e) {
      throw AuthException('Échec de connexion : ${e.toString()}');
    }
  }

  /// Déconnexion de l'utilisateur actuel
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Réinitialisation de mot de passe par email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapFirebaseError(e.code, e.message));
    } catch (e) {
      throw AuthException('Impossible d\'envoyer l\'email de réinitialisation : ${e.toString()}');
    }
  }

  /// Traduction des codes d'erreur Firebase en messages conviviaux (pas de logs bruts à l'utilisateur)
  static String mapFirebaseError(String code, [String? defaultMessage]) {
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
        return 'Le mot de passe choisi est trop faible (minimum 6 caractères).';
      case 'user-disabled':
        return 'Ce compte utilisateur a été désactivé.';
      case 'operation-not-allowed':
        return 'L\'authentification par email/mot de passe n\'est pas activée sur Firebase Console.';
      case 'too-many-requests':
        return 'Trop de tentatives infructueuses. Veuillez réessayer ultérieurement.';
      case 'network-request-failed':
        return 'Erreur réseau : impossible de joindre le serveur Firebase.';
      default:
        return defaultMessage ?? 'Une erreur d\'authentification est survenue.';
    }
  }
}
