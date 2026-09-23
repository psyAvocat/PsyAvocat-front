import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/core/errors/app_exception.dart';
import 'package:psyavocat_front/core/network/error_interceptor.dart';
import 'package:psyavocat_front/shared/enums/user_role.dart';
import 'package:psyavocat_front/shared/enums/validation_status.dart';

void main() {
  group('Core & Shared Tests', () {
    test('UserRole parsing from code', () {
      expect(UserRole.fromCode('AVOCAT'), equals(UserRole.avocat));
      expect(UserRole.fromCode('PSYCHOLOGUE'), equals(UserRole.psychologue));
      expect(UserRole.fromCode('PATIENT'), equals(UserRole.patient));
      expect(UserRole.fromCode('UNKNOWN'), equals(UserRole.patient));
    });

    test('ErrorInterceptor converts 401 to UnauthorizedException', () {
      final interceptor = ErrorInterceptor();
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
          data: {'message': 'Unauthorized'},
        ),
        type: DioExceptionType.badResponse,
      );

      final handler = _TestErrorInterceptorHandler();
      interceptor.onError(dioException, handler);

      expect(handler.rejectedError, isNotNull);
      expect(handler.rejectedError!.error, isA<UnauthorizedException>());
    });

    test('ErrorInterceptor converts timeout to TimeoutException', () {
      final interceptor = ErrorInterceptor();
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final handler = _TestErrorInterceptorHandler();
      interceptor.onError(dioException, handler);

      expect(handler.rejectedError, isNotNull);
      expect(handler.rejectedError!.error, isA<TimeoutException>());
    });
  });
}

class _TestErrorInterceptorHandler extends ErrorInterceptorHandler {
  DioException? rejectedError;

  @override
  void reject(DioException error, [bool callNext = false]) {
    rejectedError = error;
  }
}
