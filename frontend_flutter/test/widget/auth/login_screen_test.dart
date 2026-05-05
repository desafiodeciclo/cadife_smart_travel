import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:cadife_smart_travel/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  late MockAuthRepository authRepository;

  setUp(() {
    authRepository = MockAuthRepository();
    // Comportamento padrão para evitar erros no build() do AsyncNotifier ou Bloc
    when(() => authRepository.isLoggedIn()).thenAnswer((_) async => const Right(false));
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('exibe erro de validação ao tentar entrar com campos vazios', (tester) async {
      await pumpApp(
        tester, 
        const LoginScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
      );

      await tester.tap(find.text('ENTRAR'));
      await tester.pumpAndSettle();

      expect(find.text('Informe o e-mail'), findsOneWidget);
      expect(find.text('Informe a senha'), findsOneWidget);
    });

    testWidgets('campos de entrada aceitam texto corretamente', (tester) async {
      await pumpApp(
        tester, 
        const LoginScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
      );

      await tester.enterText(find.byType(TextField).at(0), 'user@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'senha123');

      expect(find.text('user@test.com'), findsOneWidget);
      expect(find.text('senha123'), findsOneWidget);
    });
  });
}
