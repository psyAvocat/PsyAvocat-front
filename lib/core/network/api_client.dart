import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'error_interceptor.dart';

/// Client HTTP Dio configuré pour l'API Spring Boot PsyAvocat.
class ApiClient {
  late final Dio dio;

  ApiClient({Dio? customDio, List<Interceptor>? interceptors}) {
    dio = customDio ??
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
  }) =>
      dio.get<T>(path, queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
}
