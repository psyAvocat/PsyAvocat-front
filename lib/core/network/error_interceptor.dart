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
        String message = 'Une erreur est survenue';

        if (data is Map<String, dynamic> && data['message'] != null) {
          message = data['message'].toString();
        } else if (err.message != null && err.message!.isNotEmpty) {
          message = err.message!;
        }

        switch (statusCode) {
          case 400:
            Map<String, dynamic>? validationErrors;
            if (data is Map<String, dynamic> && data['errors'] is Map<String, dynamic>) {
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
          case 500:
          default:
            exception = ServerException(message, statusCode ?? 500);
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
        exception = NetworkException(err.message ?? 'Erreur réseau inattendue');
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
