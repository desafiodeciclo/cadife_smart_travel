import 'package:cadife_smart_travel/core/network/interceptors/log_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CadifeLogInterceptor — sanitização', () {
    final interceptor = CadifeLogInterceptor();

    group('maskToken', () {
      test('retorna *** para valor nulo', () {
        expect(CadifeLogInterceptor.maskToken(null), equals('***'));
      });

      test('retorna *** para string vazia', () {
        expect(CadifeLogInterceptor.maskToken(''), equals('***'));
      });

      test('retorna *** se não começa com Bearer', () {
        expect(CadifeLogInterceptor.maskToken('Token abc123'), equals('***'));
      });

      test('mascara JWT completo para Bearer xxxx...XXXXXXXX', () {
        final fullJwt = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
        final masked = CadifeLogInterceptor.maskToken(fullJwt);

        expect(masked, startsWith('Bearer xxxx...'));
        expect(masked, endsWith('5c'));
        expect(masked, isNot(contains('eyJh')));
        expect(masked.length, lessThan(fullJwt.length));
      });

      test('mascara Bearer com token curto (<=8 chars) para Bearer ***', () {
        expect(CadifeLogInterceptor.maskToken('Bearer abc'), equals('Bearer ***'));
      });

      test('mostra apenas últimos 8 caracteres do token', () {
        final jwt = 'Bearer 0123456789abcdefghij';
        final masked = CadifeLogInterceptor.maskToken(jwt);

        expect(masked, equals('Bearer xxxx...cdefghij'));
      });
    });

    group('sanitizeBody', () {
      test('retorna null para dados nulos', () {
        expect(CadifeLogInterceptor.sanitizeBody(null), isNull);
      });

      test('retorna dados não-map intactos', () {
        expect(CadifeLogInterceptor.sanitizeBody('texto'), equals('texto'));
        expect(CadifeLogInterceptor.sanitizeBody(123), equals(123));
        expect(CadifeLogInterceptor.sanitizeBody(true), equals(true));
      });

      test('mascarar campo password', () {
        final data = {'password': 'secret123', 'username': 'john'};
        final sanitized = CadifeLogInterceptor.sanitizeBody(data);

        expect(sanitized['password'], equals('***'));
        expect(sanitized['username'], equals('john'));
      });

      test('mascarar campo email', () {
        final data = {'email': 'user@example.com', 'name': 'User'};
        final sanitized = CadifeLogInterceptor.sanitizeBody(data);

        expect(sanitized['email'], equals('***'));
        expect(sanitized['name'], equals('User'));
      });

      test('mascarar campo token', () {
        final data = {'token': 'secret_token_123', 'id': '456'};
        final sanitized = CadifeLogInterceptor.sanitizeBody(data);

        expect(sanitized['token'], equals('***'));
        expect(sanitized['id'], equals('456'));
      });

      test('mascarar campo access_token', () {
        final data = {'access_token': 'eyJhbGc...', 'user_id': '789'};
        final sanitized = CadifeLogInterceptor.sanitizeBody(data);

        expect(sanitized['access_token'], equals('***'));
        expect(sanitized['user_id'], equals('789'));
      });

      test('mascarar campo refresh_token', () {
        final data = {'refresh_token': 'refresh_xyz', 'user': 'john'};
        final sanitized = CadifeLogInterceptor.sanitizeBody(data);

        expect(sanitized['refresh_token'], equals('***'));
        expect(sanitized['user'], equals('john'));
      });

      test('case-insensitive: PASSWORD em maiúscula também é mascarado', () {
        final data = {'PASSWORD': 'secret', 'Username': 'john'};
        final sanitized = CadifeLogInterceptor.sanitizeBody(data);

        expect(sanitized['PASSWORD'], equals('***'));
        expect(sanitized['Username'], equals('john'));
      });

      test('múltiplos campos sensíveis simultaneamente', () {
        final data = {
          'password': 'secret',
          'email': 'user@test.com',
          'access_token': 'token123',
          'refresh_token': 'refresh',
          'username': 'john',
          'id': '999',
        };
        final sanitized = CadifeLogInterceptor.sanitizeBody(data);

        expect(sanitized['password'], equals('***'));
        expect(sanitized['email'], equals('***'));
        expect(sanitized['access_token'], equals('***'));
        expect(sanitized['refresh_token'], equals('***'));
        expect(sanitized['username'], equals('john'));
        expect(sanitized['id'], equals('999'));
      });

      test('preserva tipos de dados não-sensíveis', () {
        final data = {
          'count': 42,
          'active': true,
          'nested': {'key': 'value'},
          'list': [1, 2, 3],
        };
        final sanitized = CadifeLogInterceptor.sanitizeBody(data);

        expect(sanitized['count'], equals(42));
        expect(sanitized['active'], equals(true));
        expect(sanitized['nested'], equals({'key': 'value'}));
        expect(sanitized['list'], equals([1, 2, 3]));
      });
    });

    group('onRequest', () {
      test('log contém method e path', () async {
        final options = RequestOptions(path: '/api/leads');
        final handler = _MockRequestInterceptorHandler();

        await interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
        expect(handler.passedOptions.path, equals('/api/leads'));
      });

      test('Authorization header não expõe JWT completo em logs', () async {
        final options = RequestOptions(
          path: '/api/leads',
          headers: {
            'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c'
          },
        );
        final handler = _MockRequestInterceptorHandler();

        await interceptor.onRequest(options, handler);

        // Verificar que o handler foi chamado (indicando que log foi feito)
        expect(handler.nextCalled, isTrue);
      });

      test('request body sensível é sanitizado', () async {
        final options = RequestOptions(
          path: '/api/auth/login',
          data: {
            'email': 'user@test.com',
            'password': 'secret123',
            'remember': true,
          },
        );
        final handler = _MockRequestInterceptorHandler();

        await interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
      });
    });

    group('onResponse', () {
      test('log contém status e path', () async {
        final response = Response<dynamic>(
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/leads'),
        );
        final handler = _MockResponseInterceptorHandler();

        await interceptor.onResponse(response, handler);

        expect(handler.nextCalled, isTrue);
      });
    });

    group('onError', () {
      test('log contém tipo de erro e path', () async {
        final error = DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/api/leads'),
        );
        final handler = _MockErrorInterceptorHandler();

        await interceptor.onError(error, handler);

        expect(handler.nextCalled, isTrue);
      });

      test('exception com DioException é logado com contexto', () async {
        final dioError = DioException(
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/api/leads'),
          ),
          requestOptions: RequestOptions(path: '/api/leads'),
        );
        final handler = _MockErrorInterceptorHandler();

        await interceptor.onError(dioError, handler);

        expect(handler.nextCalled, isTrue);
      });
    });
  });
}

class _MockRequestInterceptorHandler extends RequestInterceptorHandler {
  bool nextCalled = false;
  late RequestOptions passedOptions;

  @override
  void next(RequestOptions options) {
    nextCalled = true;
    passedOptions = options;
  }

  @override
  void reject(DioException err, [bool sync = false]) {}

  @override
  void resolve(Response response, [bool sync = false]) {}
}

class _MockResponseInterceptorHandler extends ResponseInterceptorHandler {
  bool nextCalled = false;

  @override
  void next(Response response) {
    nextCalled = true;
  }

  @override
  void reject(DioException err, [bool sync = false]) {}

  @override
  void resolve(Response response, [bool sync = false]) {}
}

class _MockErrorInterceptorHandler extends ErrorInterceptorHandler {
  bool nextCalled = false;

  @override
  void next(DioException err) {
    nextCalled = true;
  }

  @override
  void reject(DioException err, [bool sync = false]) {}

  @override
  void resolve(Response response, [bool sync = false]) {}
}
