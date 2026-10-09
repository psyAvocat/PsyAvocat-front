import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/datasources/firebase_auth_datasource.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/controllers/session_controller.dart';
import 'api_client.dart';

/// Provider pour la datasource Firebase Auth
final authDatasourceProvider = Provider<FirebaseAuthDatasource>((ref) {
  return FirebaseAuthDatasource();
});

/// Provider pour le repository d'authentification
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final datasource = ref.watch(authDatasourceProvider);
  return AuthRepository(datasource);
});

/// Client HTTP Dio (jeton Firebase injecté par l'AuthInterceptor).
/// Un refus de compte par le backend (403 codé) réévalue la session.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    onAccountRefused: () =>
        ref.read(sessionControllerProvider.notifier).revalidate(),
  );
});

/// StreamProvider pour écouter l'état de connexion de l'utilisateur
final authStateChangesProvider = StreamProvider((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});
