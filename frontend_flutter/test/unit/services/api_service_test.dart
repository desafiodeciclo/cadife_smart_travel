import 'package:cadife_smart_travel/core/security/secure_config.dart';
import 'package:cadife_smart_travel/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockSecureConfig extends Mock implements SecureConfig {}

void main() {
  late ApiService apiService;
  late MockDio mockDio;
  late MockSecureConfig mockSecureConfig;

  setUp(() {
    mockDio = MockDio();
    mockSecureConfig = MockSecureConfig();
    apiService = ApiService(
      dio: mockDio,
      secureConfig: mockSecureConfig,
    );
  });

  group('ApiService Tests', () {
    test('get() should return data on 200', () async {
      // Arrange
      when(() => mockDio.get<Map<String, dynamic>>('/test'))
          .thenAnswer((_) async => Response(
                data: {'status': 'ok'},
                statusCode: 200,
                requestOptions: RequestOptions(path: '/test'),
              ));

      // Act
      final result = await apiService.get('/test');

      // Assert
      expect(result['status'], 'ok');
      verify(() => mockDio.get<Map<String, dynamic>>('/test')).called(1);
    });

    test('get() should clear token on 401 error', () async {
      // Arrange
      when(() => mockDio.get<Map<String, dynamic>>('/test'))
          .thenThrow(DioException(
            response: Response(statusCode: 401, requestOptions: RequestOptions(path: '/test')),
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.badResponse,
          ));
      when(() => mockSecureConfig.clearTokens())
          .thenAnswer((_) async {});

      // Act & Assert
      expect(() => apiService.get('/test'), throwsException);
      
      await Future<void>.delayed(const Duration(milliseconds: 100));
      verify(() => mockSecureConfig.clearTokens()).called(1);
    });
  });
}
