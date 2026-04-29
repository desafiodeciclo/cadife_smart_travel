import 'package:cadife_smart_travel/core/network/exceptions/api_exception.dart';
import 'package:cadife_smart_travel/core/network/interceptors/error_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

DioException _badResponse(int status, {Map<String, dynamic>? data}) =>
    DioException(
      requestOptions: RequestOptions(path: '/test'),
      response: Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: status,
        data: data,
      ),
      type: DioExceptionType.badResponse,
    );

DioException _networkError(DioExceptionType type) => DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: type,
    );

void main() {
  late ErrorInterceptor interceptor;
  late MockErrorInterceptorHandler handler;

  setUpAll(() {
    registerFallbackValue(
      DioException(requestOptions: RequestOptions(path: '')),
    );
  });

  setUp(() {
    interceptor = ErrorInterceptor();
    handler = MockErrorInterceptorHandler();
  });

  DioException capturedError() =>
      verify(() => handler.next(captureAny())).captured.single as DioException;

  group('ErrorInterceptor — HTTP status mapping', () {
    test('401 → UnauthorizedException', () {
      interceptor.onError(_badResponse(401), handler);
      expect(capturedError().error, isA<UnauthorizedException>());
    });

    test('403 → ForbiddenException', () {
      interceptor.onError(_badResponse(403), handler);
      expect(capturedError().error, isA<ForbiddenException>());
    });

    test('409 → ConflictException', () {
      interceptor.onError(_badResponse(409), handler);
      expect(capturedError().error, isA<ConflictException>());
    });

    test('409 with message → ConflictException carries message', () {
      interceptor.onError(
        _badResponse(409, data: {'message': 'Conflito de horário'}),
        handler,
      );
      final ex = capturedError().error as ConflictException;
      expect(ex.message, 'Conflito de horário');
    });

    test('500 → ServerException with statusCode 500', () {
      interceptor.onError(_badResponse(500), handler);
      final ex = capturedError().error as ServerException;
      expect(ex.statusCode, 500);
    });

    test('503 → ServerException with statusCode 503', () {
      interceptor.onError(_badResponse(503), handler);
      final ex = capturedError().error as ServerException;
      expect(ex.statusCode, 503);
    });

    test('404 → UnknownApiException (not a mapped status)', () {
      interceptor.onError(_badResponse(404), handler);
      expect(capturedError().error, isA<UnknownApiException>());
    });
  });

  group('ErrorInterceptor — network errors', () {
    test('connectionTimeout → NetworkException', () {
      interceptor.onError(
        _networkError(DioExceptionType.connectionTimeout),
        handler,
      );
      expect(capturedError().error, isA<NetworkException>());
    });

    test('sendTimeout → NetworkException', () {
      interceptor.onError(
        _networkError(DioExceptionType.sendTimeout),
        handler,
      );
      expect(capturedError().error, isA<NetworkException>());
    });

    test('receiveTimeout → NetworkException', () {
      interceptor.onError(
        _networkError(DioExceptionType.receiveTimeout),
        handler,
      );
      expect(capturedError().error, isA<NetworkException>());
    });

    test('connectionError → NetworkException', () {
      interceptor.onError(
        _networkError(DioExceptionType.connectionError),
        handler,
      );
      expect(capturedError().error, isA<NetworkException>());
    });
  });

  group('ErrorInterceptor — envelope preservation', () {
    test('always calls handler.next (never handler.reject)', () {
      interceptor.onError(_badResponse(500), handler);
      verify(() => handler.next(any())).called(1);
      verifyNever(() => handler.reject(any()));
    });

    test('preserves original response in the forwarded DioException', () {
      final original = _badResponse(500);
      interceptor.onError(original, handler);
      final forwarded = capturedError();
      expect(forwarded.response?.statusCode, 500);
    });
  });
}
