import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mock_repositories.dart';
import '../../../helpers/test_fixtures.dart';

class Listener<T> extends Mock {
  void call(T? previous, T next);
}

void main() {
  late MockAuthRepository authRepository;

  setUp(() {
    authRepository = MockAuthRepository();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AuthNotifier', () {
    test('inicia com estado null quando não logado', () async {
      when(() => authRepository.isLoggedIn()).thenAnswer((_) async => const Right(false));
      
      final container = makeContainer();
      
      // Aguarda a inicialização do build()
      final result = await container.read(authNotifierProvider.future);
      
      expect(result, isNull);
      verify(() => authRepository.isLoggedIn()).called(1);
    });

    test('login com sucesso atualiza estado para o usuário autenticado', () async {
      final user = UserFixture.consultor();
      when(() => authRepository.isLoggedIn()).thenAnswer((_) async => const Right(false));
      when(() => authRepository.login(any(), any())).thenAnswer((_) async => Right(user));

      final container = makeContainer();
      final notifier = container.read(authNotifierProvider.notifier);

      await notifier.login('admin@cadife.com', '123456');

      expect(container.read(authNotifierProvider).value, equals(user));
      verify(() => authRepository.login('admin@cadife.com', '123456')).called(1);
    });

    test('logout limpa o estado para null', () async {
      final user = UserFixture.consultor();
      when(() => authRepository.isLoggedIn()).thenAnswer((_) async => const Right(true));
      when(() => authRepository.getCurrentUser()).thenAnswer((_) async => Right(user));
      when(() => authRepository.logout()).thenAnswer((_) async => const Right(null));

      final container = makeContainer();
      
      // Carrega usuário inicial
      await container.read(authNotifierProvider.future);
      expect(container.read(authNotifierProvider).value, equals(user));

      // Executa logout
      await container.read(authNotifierProvider.notifier).logout();

      expect(container.read(authNotifierProvider).value, isNull);
      verify(() => authRepository.logout()).called(1);
    });
  });
}
