import 'package:firebase_auth/firebase_auth.dart';
import '../datasources/firebase_auth_datasource.dart';

/// Repository pour l'authentification Firebase.
class AuthRepository {
  final FirebaseAuthDatasource _datasource;

  AuthRepository(this._datasource);

  User? get currentUser => _datasource.currentUser;

  Stream<User?> get authStateChanges => _datasource.authStateChanges;

  Future<String?> getIdToken([bool forceRefresh = false]) =>
      _datasource.getIdToken(forceRefresh);

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) =>
      _datasource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) =>
      _datasource.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );

  Future<void> signOut() => _datasource.signOut();
}
