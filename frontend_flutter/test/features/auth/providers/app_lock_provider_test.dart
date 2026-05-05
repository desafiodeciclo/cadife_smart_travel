import 'package:cadife_smart_travel/core/security/biometric_service.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_event.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_bloc_provider.dart';
import 'package:cadife_smart_travel/features/auth/providers/app_lock_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBiometricService extends Mock implements BiometricService {}
class MockAuthBloc extends Mock implements AuthBloc {
  @override
  Future<void> close() async {}
}

ProviderContainer buildContainer({
  required MockBiometricService biometric,
  required MockAuthBloc authBloc,
}) {
  return ProviderContainer(
    overrides: [
      biometricServiceProvider.overrideWithValue(biometric),
      authBlocProvider.overrideWithValue(authBloc),
    ],
  );
}

void main() {
  late MockBiometricService biometric;
  late MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(const AuthEvent.logoutRequested());
  });

  setUp(() {
    biometric = MockBiometricService();
    authBloc = MockAuthBloc();
    when(() => biometric.isAvailable()).thenAnswer((_) async => true);
  });

  group('AppLockNotifier — lifecycle', () {
    test('estado inicial não está bloqueado', () {
      final container = buildContainer(biometric: biometric, authBloc: authBloc);
      addTearDown(container.dispose);
      expect(container.read(appLockProvider).isLocked, isFalse);
    });

    test('onPaused + onResumed dentro do timeout não bloqueia', () {
      final container = buildContainer(biometric: biometric, authBloc: authBloc);
      addTearDown(container.dispose);

      container.read(appLockProvider.notifier).onAppPaused();
      container.read(appLockProvider.notifier).onAppResumed();

      expect(container.read(appLockProvider).isLocked, isFalse);
    });
  });

  group('AppLockNotifier — authenticate', () {
    test('biometria bem-sucedida desbloqueia', () async {
      when(() => biometric.authenticate())
          .thenAnswer((_) async => BiometricResult.success);

      final container = buildContainer(biometric: biometric, authBloc: authBloc);
      addTearDown(container.dispose);

      final notifier = container.read(appLockProvider.notifier);
      notifier.state = notifier.state.copyWith(isLocked: true);

      await notifier.authenticate();

      expect(container.read(appLockProvider).isLocked, isFalse);
      expect(container.read(appLockProvider).failures, 0);
    });

    test('3 falhas consecutivas fazem logout e desbloqueiam', () async {
      when(() => biometric.authenticate())
          .thenAnswer((_) async => BiometricResult.failed);

      final container = buildContainer(biometric: biometric, authBloc: authBloc);
      addTearDown(container.dispose);

      final notifier = container.read(appLockProvider.notifier);
      notifier.state = notifier.state.copyWith(isLocked: true);

      await notifier.authenticate(); // failures = 1
      await notifier.authenticate(); // failures = 2
      await notifier.authenticate(); // failures = 3 → logout

      verify(() => authBloc.add(const AuthEvent.logoutRequested())).called(1);
      expect(container.read(appLockProvider).isLocked, isFalse);
    });
  });
}
