import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cadife_smart_travel/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

class MockAuthNotifier extends AuthNotifier {
  @override
  Future<AuthUser?> build() async => null;

  @override
  Future<void> logout() async {}
}

void main() {
  late MockAuthRepository mockAuthRepository;
  late ProviderContainer container;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    // Register mock repository in GetIt
    if (GetIt.I.isRegistered<IAuthRepository>()) {
      GetIt.I.unregister<IAuthRepository>();
    }
    GetIt.I.registerSingleton<IAuthRepository>(mockAuthRepository);

    container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(MockAuthNotifier.new),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    if (GetIt.I.isRegistered<IAuthRepository>()) {
      GetIt.I.unregister<IAuthRepository>();
    }
  });

  group('Auth Provider Verification', () {
    test('AuthUser class has correct fields and factory', () {
      final json = {
        'id': '123',
        'name': 'Frank',
        'email': 'frank@test.com',
        'role': 'admin',
        'avatar_url': 'https://link.com'
      };
      
      final user = AuthUser.fromJson(json);
      
      expect(user.id, '123');
      expect(user.name, 'Frank');
      expect(user.email, 'frank@test.com');
      expect(user.role, UserRole.admin);
      expect(user.avatarUrl, 'https://link.com');
    });

    test('currentUserProvider should call getUserProfile when authNotifier has no user', () async {
      // Arrange
      const user = AuthUser(
        id: '123',
        name: 'Frank',
        email: 'frank@test.com',
        role: UserRole.admin,
      );
      when(() => mockAuthRepository.getUserProfile())
          .thenAnswer((_) async => const Right(user));

      // Ensure authNotifierProvider is settled before reading currentUserProvider
      await container.read(authNotifierProvider.future);

      // Act
      final result = await container.read(currentUserProvider.future);

      // Assert
      expect(result?.name, 'Frank');
      verify(() => mockAuthRepository.getUserProfile()).called(1);
    });

    test('logout() should complete without error', () async {
      // Act & Assert
      await container.read(currentUserProvider.notifier).logout();
    });
  });
}
