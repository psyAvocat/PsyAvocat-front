import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../errors/app_exception.dart';
import 'error_interceptor.dart';

/// Client HTTP Dio configuré pour l'API Spring Boot PsyAvocat.
class ApiClient {
  late final Dio dio;

  ApiClient({Dio? customDio, List<Interceptor>? interceptors}) {
    dio =
        customDio ??
        Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            sendTimeout: AppConfig.sendTimeout,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    // Ajout des intercepteurs personnalisés (notamment AuthInterceptor)
    if (interceptors != null) {
      dio.interceptors.addAll(interceptors);
    }

    // Gestion centralisée des erreurs
    dio.interceptors.add(ErrorInterceptor());
  }

  // Raccourcis pour les verbes HTTP principaux
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _send(
    () => dio.get<T>(path, queryParameters: queryParameters, options: options),
  );

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _send(
    () => dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    ),
  );

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _send(
    () => dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    ),
  );

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _send(
    () => dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    ),
  );

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _send(
    () => dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    ),
  );

  /// Exécute la requête et remonte l'[AppException] préparée par l'ErrorInterceptor
  /// (au lieu de la DioException qui l'enveloppe) : les repositories et les écrans
  /// reçoivent directement un message compréhensible.
  Future<Response<T>> _send<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      final error = e.error;
      if (error is AppException) throw error;
      rethrow;
    }
  }
}
