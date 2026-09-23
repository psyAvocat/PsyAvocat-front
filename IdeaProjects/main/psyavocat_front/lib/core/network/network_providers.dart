import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/datasources/firebase_auth_datasource.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import 'api_client.dart';
import 'auth_interceptor.dart';

/// Provider pour la datasource Firebase Auth
final authDatasourceProvider = Provider<FirebaseAuthDatasource>((ref) {
  return FirebaseAuthDatasource();
});

/// Provider pour le repository d'authentification
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final datasource = ref.watch(authDatasourceProvider);
  return AuthRepository(datasource);
});

/// Provider pour l'intercepteur d'authentification
final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor();
});

/// Provider pour le client HTTP Dio configuré avec l'AuthInterceptor
final apiClientProvider = Provider<ApiClient>((ref) {
  final authInterceptor = ref.watch(authInterceptorProvider);
  return ApiClient(interceptors: [authInterceptor]);
});

/// StreamProvider pour écouter l'état de connexion de l'utilisateur
final authStateChangesProvider = StreamProvider((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});
