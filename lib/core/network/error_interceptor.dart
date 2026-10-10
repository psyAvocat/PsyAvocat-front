import 'package:dio/dio.dart';
import '../errors/app_exception.dart';

/// Intercepteur Dio transformant les erreurs HTTP en exceptions typées de l'application.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppException exception;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        exception = const TimeoutException();
        break;

      case DioExceptionType.connectionError:
        exception = const NetworkException();
        break;

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final data = err.response?.data;
        // Seuls les messages métier (4xx) du backend sont affichables ; jamais
        // le message technique de Dio (il contient le code HTTP brut).
        String message = 'Une erreur est survenue. Veuillez réessayer.';
        final serverMessage = data is Map<String, dynamic>
            ? data['message']?.toString()
            : null;
        if (statusCode != null &&
            statusCode >= 400 &&
            statusCode < 500 &&
            serverMessage != null &&
            serverMessage.trim().isNotEmpty) {
          message = serverMessage;
        }

        switch (statusCode) {
          case 400:
            Map<String, dynamic>? validationErrors;
            if (data is Map<String, dynamic> &&
                data['errors'] is Map<String, dynamic>) {
              validationErrors = data['errors'] as Map<String, dynamic>;
            }
            exception = ValidationException(message, validationErrors, 400);
            break;
          case 401:
            exception = UnauthorizedException(message, 401);
            break;
          case 403:
            exception = ForbiddenException(message, 403);
            break;
          case 404:
            exception = NotFoundException(message, 404);
            break;
          case 409:
            exception = ConflictException(message);
            break;
          default:
            exception = (statusCode ?? 500) >= 500
                ? ServerException(
                    'Le service est momentanément indisponible. Veuillez réessayer.',
                    statusCode ?? 500,
                  )
                : AppException(message, statusCode);
            break;
        }
        break;

      case DioExceptionType.cancel:
        exception = const AppException('La requête a été annulée');
        break;

      case DioExceptionType.badCertificate:
        exception = const NetworkException('Certificat SSL non valide');
        break;

      case DioExceptionType.unknown:
      default:
        exception = const NetworkException();
        break;
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: exception,
      ),
    );
  }
}
