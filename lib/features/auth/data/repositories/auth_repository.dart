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
      _datasource.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) =>
      _datasource.signUpWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _datasource.signOut();

  Future<void> deleteCurrentUser() => _datasource.deleteCurrentUser();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _datasource.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  Future<UserCredential> register(String email, String password) =>
      _datasource.register(email, password);

  Future<UserCredential> login(String email, String password) =>
      _datasource.login(email, password);

  Future<void> logout() => _datasource.logout();

  Future<void> sendPasswordResetEmail(String email) =>
      _datasource.sendPasswordResetEmail(email);
}
