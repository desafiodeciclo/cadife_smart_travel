import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cadife_smart_travel/services/api_service.dart';
import 'package:cadife_smart_travel/providers/auth_provider.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApiService;
  late ProviderContainer container;

  setUp(() {
    mockApiService = MockApiService();
    container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(mockApiService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Auth Provider Verification', () {
    test('User class has correct fields and factory', () {
      final json = {
        'id': '123',
        'name': 'Frank',
        'email': 'frank@test.com',
        'role': 'admin',
        'avatar': 'https://link.com'
      };
      
      final user = User.fromJson(json);
      
      expect(user.id, '123');
      expect(user.name, 'Frank');
      expect(user.email, 'frank@test.com');
      expect(user.role, 'admin');
      expect(user.avatar, 'https://link.com');
    });

    test('currentUserProvider should call /users/me in build()', () async {
      // Arrange
      final userData = {
        'id': '123',
        'name': 'Frank',
        'email': 'frank@test.com',
        'role': 'admin',
        'avatar': null
      };
      when(() => mockApiService.get('/users/me'))
          .thenAnswer((_) async => userData);

      // Act
      final user = await container.read(currentUserProvider.future);

      // Assert
      expect(user.name, 'Frank');
      verify(() => mockApiService.get('/users/me')).called(1);
    });

    test('logout() should clear token and reset state', () async {
      // Arrange
      when(() => mockApiService.clearToken()).thenAnswer((_) async => {});
      
      // Act
      await container.read(currentUserProvider.notifier).logout();

      // Assert
      verify(() => mockApiService.clearToken()).called(1);
    });
  });
}
