import 'package:cadife_smart_travel/core/network/interceptors/auth_interceptor.dart';
import 'package:cadife_smart_travel/core/security/secure_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureConfig extends Mock implements SecureConfig {}

class MockDio extends Mock implements Dio {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

DioException create401Exception({String path = '/leads'}) => DioException(
      requestOptions: RequestOptions(path: path),
      response: Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 401,
      ),
      type: DioExceptionType.badResponse,
    );

void main() {
  late MockSecureConfig secureConfig;
  late MockDio refreshDio;
  late List<String> expiredCalls;
  late AuthInterceptor interceptor;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(
      DioException(requestOptions: RequestOptions(path: '')),
    );
    registerFallbackValue(
      Response<dynamic>(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
      ),
    );
  });

  setUp(() {
    secureConfig = MockSecureConfig();
    refreshDio = MockDio();
    expiredCalls = [];
    interceptor = AuthInterceptor(
      secureConfig: secureConfig,
      refreshDio: refreshDio,
      onTokenExpired: () => expiredCalls.add('expired'),
    );
  });

  group('AuthInterceptor — onRequest', () {
    test('injects Authorization header when token exists', () async {
      when(() => secureConfig.getAccessToken())
          .thenAnswer((_) async => 'my-token');
      final handler = MockRequestInterceptorHandler();
      final options = RequestOptions(path: '/leads');

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer my-token');
      verify(() => handler.next(options)).called(1);
    });

    test('does not inject header when token is null', () async {
      when(() => secureConfig.getAccessToken()).thenAnswer((_) async => null);
      final handler = MockRequestInterceptorHandler();
      final options = RequestOptions(path: '/leads');

      await interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
      verify(() => handler.next(options)).called(1);
    });
  });

  group('AuthInterceptor — onError: non-401', () {
    test('passes non-401 errors through unchanged', () async {
      final handler = MockErrorInterceptorHandler();
      final err = DioException(
        requestOptions: RequestOptions(path: '/leads'),
        response: Response(
          requestOptions: RequestOptions(path: '/leads'),
          statusCode: 403,
        ),
        type: DioExceptionType.badResponse,
      );

      await interceptor.onError(err, handler);

      verify(() => handler.next(err)).called(1);
      verifyNever(() => refreshDio.post(any(), data: any(named: 'data')));
    });
  });

  group('AuthInterceptor — onError: 401 on refresh endpoint', () {
    test('skips refresh when path is /auth/refresh (prevents infinite loop)',
        () async {
      final handler = MockErrorInterceptorHandler();
      final err = create401Exception(path: '/auth/refresh');

      await interceptor.onError(err, handler);

      verify(() => handler.next(err)).called(1);
      verifyNever(() => refreshDio.post(any(), data: any(named: 'data')));
      expect(expiredCalls, isEmpty);
    });
  });

  group('AuthInterceptor — onError: successful refresh', () {
    test('calls POST /auth/refresh, saves tokens, retries original request',
        () async {
      when(() => secureConfig.getRefreshToken())
          .thenAnswer((_) async => 'old-refresh');
      when(() => secureConfig.getAccessToken())
          .thenAnswer((_) async => 'new-access');
      when(
        () => secureConfig.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenAnswer((_) async {});

      final refreshResponse = Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        data: {
          'access_token': 'new-access',
          'refresh_token': 'new-refresh',
        },
        statusCode: 200,
      );
      when(() => refreshDio.post('/auth/refresh', data: any(named: 'data')))
          .thenAnswer((_) async => refreshResponse);

      final retryResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: '/leads'),
        statusCode: 200,
        data: [],
      );
      when(() => refreshDio.fetch(any()))
          .thenAnswer((_) async => retryResponse);

      final handler = MockErrorInterceptorHandler();
      await interceptor.onError(create401Exception(), handler);

      verify(
        () => secureConfig.saveTokens(
          accessToken: 'new-access',
          refreshToken: 'new-refresh',
        ),
      ).called(1);
      verify(() => refreshDio.fetch(any())).called(1);
      verify(() => handler.resolve(retryResponse)).called(1);
      expect(expiredCalls, isEmpty);
    });
  });

  group('AuthInterceptor — onError: refresh failure', () {
    test('calls onTokenExpired and clears tokens when refresh token is null',
        () async {
      when(() => secureConfig.getRefreshToken()).thenAnswer((_) async => null);
      when(() => secureConfig.clearTokens()).thenAnswer((_) async {});

      final handler = MockErrorInterceptorHandler();
      await interceptor.onError(create401Exception(), handler);

      verify(() => secureConfig.clearTokens()).called(1);
      expect(expiredCalls, ['expired']);
      verify(() => handler.next(any())).called(1);
      verifyNever(() => refreshDio.post(any(), data: any(named: 'data')));
    });

    test('calls onTokenExpired and clears tokens when POST /auth/refresh throws',
        () async {
      when(() => secureConfig.getRefreshToken())
          .thenAnswer((_) async => 'old-refresh');
      when(() => secureConfig.clearTokens()).thenAnswer((_) async {});
      when(() => refreshDio.post('/auth/refresh', data: any(named: 'data')))
          .thenThrow(DioException(requestOptions: RequestOptions(path: '/auth/refresh')));

      final handler = MockErrorInterceptorHandler();
      await interceptor.onError(create401Exception(), handler);

      verify(() => secureConfig.clearTokens()).called(1);
      expect(expiredCalls, ['expired']);
      verify(() => handler.next(any())).called(1);
    });
  });

  group('AuthInterceptor — concurrent 401 deduplication', () {
    test('POST /auth/refresh called exactly once for two simultaneous 401s',
        () async {
      when(() => secureConfig.getRefreshToken())
          .thenAnswer((_) async => 'old-refresh');
      when(() => secureConfig.getAccessToken())
          .thenAnswer((_) async => 'new-access');
      when(
        () => secureConfig.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenAnswer((_) async {});

      final refreshResponse = Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        data: {'access_token': 'new-access', 'refresh_token': 'new-refresh'},
        statusCode: 200,
      );
      when(() => refreshDio.post('/auth/refresh', data: any(named: 'data')))
          .thenAnswer((_) async => refreshResponse);
      when(() => refreshDio.fetch(any())).thenAnswer(
        (invocation) async => Response<dynamic>(
          requestOptions: invocation.positionalArguments.first as RequestOptions,
          statusCode: 200,
          data: [],
        ),
      );

      final handler1 = MockErrorInterceptorHandler();
      final handler2 = MockErrorInterceptorHandler();

      // Fire both 401s concurrently — do NOT await sequentially.
      await Future.wait([
        interceptor.onError(create401Exception(path: '/leads'), handler1),
        interceptor.onError(create401Exception(path: '/agenda'), handler2),
      ]);

      // Refresh should have been called exactly once.
      verify(() => refreshDio.post('/auth/refresh', data: any(named: 'data')))
          .called(1);
      verify(() => handler1.resolve(any())).called(1);
      verify(() => handler2.resolve(any())).called(1);
      expect(expiredCalls, isEmpty);
    });
  });
}
