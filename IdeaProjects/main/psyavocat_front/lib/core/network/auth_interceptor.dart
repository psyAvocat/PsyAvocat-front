import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Intercepteur Dio qui injecte automatiquement le Firebase ID Token dans l'en-tête HTTP:
/// `Authorization: Bearer <token>`
/// Permet à l'API Spring Boot de vérifier l'authenticité de l'utilisateur.
class AuthInterceptor extends QueuedInterceptor {
  final FirebaseAuth _firebaseAuth;

  AuthInterceptor({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        // Récupération de l'ID Token Firebase
        final idToken = await user.getIdToken();
        if (idToken != null && idToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $idToken';
        }
      }
    } catch (_) {
      // Si la récupération du token échoue, la requête continue sans header Bearer
      // Spring Security rejettera si l'endpoint est protégé
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Si Spring Boot renvoie 401 Unauthorized, tentons de forcer le rafraîchissement du token
    if (err.response?.statusCode == 401 && _firebaseAuth.currentUser != null) {
      try {
        final refreshedToken = await _firebaseAuth.currentUser!.getIdToken(true);
        if (refreshedToken != null) {
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $refreshedToken';

          final dio = Dio();
          final response = await dio.fetch(options);
          return handler.resolve(response);
        }
      } catch (_) {
        // En cas d'échec du refresh, continuer avec l'erreur
      }
    }
    handler.next(err);
  }
}
