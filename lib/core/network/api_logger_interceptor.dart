import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Journal des échanges avec le backend Spring Boot (mode debug uniquement).
///
/// Exemple dans la console `flutter run` :
/// ```text
/// [API] → GET http://10.0.2.2:8080/me (jeton Firebase : oui)
/// [API] ← 200 GET http://10.0.2.2:8080/me (84 ms)
/// [API] ✖ TIMEOUT connexion GET http://10.0.2.2:8080/me (15012 ms)
/// [API]   ↳ Le serveur n'a pas accepté la connexion à temps. Vérifiez : ...
/// ```
///
/// Le jeton Firebase et le contenu des requêtes ne sont jamais affichés.
class ApiLoggerInterceptor extends Interceptor {
  static const _startKey = 'api_logger_start';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now();
    final hasToken = options.headers.containsKey('Authorization');
    apiLog(
      '→ ${options.method} ${options.uri} '
      '(jeton Firebase : ${hasToken ? 'oui' : 'non'})',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final request = response.requestOptions;
    apiLog(
      '← ${response.statusCode} ${request.method} ${request.uri} '
      '(${_elapsed(request)})',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final request = err.requestOptions;
    final status = err.response?.statusCode;
    final label = status != null ? 'HTTP $status' : _typeLabel(err.type);
    apiLog('✖ $label ${request.method} ${request.uri} (${_elapsed(request)})');
    final hint = _hintFor(err);
    if (hint != null) apiLog('  ↳ $hint');
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown) {
      apiLog('  ↳ Détail technique : ${err.error ?? err.message}');
    }
    handler.next(err);
  }

  String _elapsed(RequestOptions request) {
    final start = request.extra[_startKey];
    if (start is! DateTime) return '? ms';
    return '${DateTime.now().difference(start).inMilliseconds} ms';
  }

  String _typeLabel(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return 'TIMEOUT connexion';
      case DioExceptionType.sendTimeout:
        return 'TIMEOUT envoi';
      case DioExceptionType.receiveTimeout:
        return 'TIMEOUT réponse';
      case DioExceptionType.connectionError:
        return 'CONNEXION IMPOSSIBLE';
      case DioExceptionType.badCertificate:
        return 'CERTIFICAT INVALIDE';
      case DioExceptionType.cancel:
        return 'ANNULÉE';
      default:
        return 'ERREUR';
    }
  }

  /// Piste de diagnostic pour un développeur, selon le type d'erreur.
  String? _hintFor(DioException err) {
    final server = AppConfig.serverBaseUrl;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        return 'Le serveur $server n\'a pas accepté la connexion à temps. '
            'Vérifiez : 1) Spring Boot est démarré (port 8080) ; '
            '2) sur un VRAI téléphone, 10.0.2.2 ne marche pas : en Wi-Fi, '
            'lancez flutter run --dart-define=ip=<IP-du-PC> (même réseau) ; '
            'en USB, adb reverse tcp:8080 tcp:8080 puis --dart-define=ip=localhost ; '
            '3) le pare-feu Windows autorise le port 8080.';
      case DioExceptionType.receiveTimeout:
        return 'Connexion établie mais le serveur n\'a pas répondu à temps '
            '(${AppConfig.receiveTimeout.inSeconds} s). Consultez les logs '
            'Spring Boot (requête lente ou bloquée, base de données ?).';
      case DioExceptionType.sendTimeout:
        return 'L\'envoi de la requête a pris trop de temps (réseau lent ?).';
      case DioExceptionType.connectionError:
        return 'Aucun serveur ne répond sur $server. Spring Boot est-il '
            'démarré ? L\'adresse est-elle joignable depuis cet appareil ?';
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode;
        if (status == 401) {
          return 'Jeton Firebase absent ou refusé par le backend '
              '(projet Firebase du backend identique à celui de l\'app ?).';
        }
        if (status == 403) return 'Accès refusé par le backend pour ce rôle.';
        if (status == 404) return 'Route inconnue côté backend.';
        if (status != null && status >= 500) {
          return 'Erreur interne du backend : consultez les logs Spring Boot.';
        }
        return null;
      default:
        return null;
    }
  }
}

/// Écrit une ligne `[API]` dans la console, en mode debug seulement.
void apiLog(String message) {
  if (kDebugMode) debugPrint('[API] $message');
}
