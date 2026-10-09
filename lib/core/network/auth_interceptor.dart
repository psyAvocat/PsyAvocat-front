import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_logger_interceptor.dart';

/// Codes des refus de compte renvoyés par Spring Boot (403, champ `code`).
const accountRefusalCodes = {'ACCOUNT_DISABLED', 'EMAIL_NOT_VERIFIED'};

/// Intercepteur Dio qui injecte automatiquement le Firebase ID Token dans l'en-tête HTTP:
/// `Authorization: Bearer <token>`
/// Permet à l'API Spring Boot de vérifier l'authenticité de l'utilisateur.
class AuthInterceptor extends Interceptor {
  static const _retriedKey = 'authRetried';

  final Dio _dio;
  final FirebaseAuth _firebaseAuth;

  /// Appelé quand le backend refuse le compte lui-même (désactivé, email non
  /// confirmé) : la session doit être réévaluée, un nouveau jeton n'y changerait rien.
  final void Function()? onAccountRefused;

  AuthInterceptor(
    this._dio, {
    FirebaseAuth? firebaseAuth,
    this.onAccountRefused,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

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
    } catch (error) {
      // Si la récupération du token échoue, la requête continue sans header Bearer
      // Spring Security rejettera si l'endpoint est protégé
      apiLog('Jeton Firebase indisponible pour ${options.uri} : $error');
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final data = response?.data;
    if (response?.statusCode == 403 &&
        data is Map &&
        accountRefusalCodes.contains(data['code'])) {
      apiLog('403 ${data['code']} : réévaluation de la session');
      onAccountRefused?.call();
      return handler.next(err);
    }

    // 401 : jeton probablement expiré → un seul nouvel essai avec un jeton rafraîchi,
    // via le même client (mêmes intercepteurs, même gestion des erreurs).
    final options = err.requestOptions;
    if (response?.statusCode == 401 &&
        _firebaseAuth.currentUser != null &&
        options.extra[_retriedKey] != true) {
      apiLog('401 reçu : rafraîchissement du jeton Firebase puis nouvel essai');
      try {
        await _firebaseAuth.currentUser!.getIdToken(true);
        options.extra[_retriedKey] = true;
        return handler.resolve(await _dio.fetch(options));
      } on DioException catch (retryError) {
        return handler.next(retryError);
      } catch (error) {
        apiLog('Rafraîchissement du jeton en échec : $error');
      }
    }
    handler.next(err);
  }
}
