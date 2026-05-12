import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cadife_smart_travel/services/api_service.dart';

class MockClient extends Mock implements http.Client {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late ApiService apiService;
  late MockClient mockClient;
  late MockSecureStorage mockSecureStorage;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost:8000/test'));
  });

  setUp(() {
    mockClient = MockClient();
    mockSecureStorage = MockSecureStorage();
    apiService = ApiService(
      client: mockClient,
      secureStorage: mockSecureStorage,
    );
  });

  group('ApiService Tests', () {
    test('get() should include Authorization header with token', () async {
      // Arrange
      when(() => mockSecureStorage.read(key: 'jwt_token'))
          .thenAnswer((_) async => 'fake_token');
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{"status": "ok"}', 200));

      // Act
      final result = await apiService.get('/test');

      // Assert
      expect(result['status'], 'ok');
      verify(() => mockClient.get(
            any(),
            headers: any(named: 'headers', that: containsPair('Authorization', 'Bearer fake_token')),
          )).called(1);
    });

    test('get() should clear token on 401 error', () async {
      // Arrange
      when(() => mockSecureStorage.read(key: 'jwt_token'))
          .thenAnswer((_) async => 'expired_token');
      when(() => mockSecureStorage.delete(key: 'jwt_token'))
          .thenAnswer((_) async => {});
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Unauthorized', 401));

      // Act & Assert
      expect(() => apiService.get('/test'), throwsException);
      
      // Wait for async call to clearToken
      await Future.delayed(Duration(milliseconds: 100));
      verify(() => mockSecureStorage.delete(key: 'jwt_token')).called(1);
    });
  });
}
