import 'package:cadife_smart_travel/core/security/biometric_service.dart';
import 'package:cadife_smart_travel/features/auth/providers/app_lock_provider.dart';
import 'package:cadife_smart_travel/features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBiometricService extends Mock implements BiometricService {}

class FakeAuthNotifier extends AuthNotifier {
  bool logoutCalled = false;

  @override
  Future<AuthState> build() async => const AuthState.unauthenticated();

  @override
  Future<void> logout() async {
    logoutCalled = true;
    state = const AsyncData(AuthState.unauthenticated());
  }
}

ProviderContainer buildContainer({
  required MockBiometricService biometric,
  FakeAuthNotifier? fakeAuth,
}) {
  final authNotifier = fakeAuth ?? FakeAuthNotifier();
  return ProviderContainer(
    overrides: [
      biometricServiceProvider.overrideWithValue(biometric),
      authPortProvider.overrideWith((_) => throw UnimplementedError()),
      authProvider.overrideWith(() => authNotifier),
    ],
  );
}

void main() {
  late MockBiometricService biometric;

  setUp(() {
    biometric = MockBiometricService();
    when(() => biometric.isAvailable()).thenAnswer((_) async => true);
  });

  group('AppLockNotifier — lifecycle', () {
    test('estado inicial não está bloqueado', () {
      final container = buildContainer(biometric: biometric);
      addTearDown(container.dispose);
      expect(container.read(appLockProvider).isLocked, isFalse);
    });

    test('onPaused + onResumed dentro do timeout não bloqueia', () {
      final container = buildContainer(biometric: biometric);
      addTearDown(container.dispose);

      container.read(appLockProvider.notifier).onAppPaused();
      // Simula resume imediato (< 3 min)
      container.read(appLockProvider.notifier).onAppResumed();

      expect(container.read(appLockProvider).isLocked, isFalse);
    });

    test('onResumed sem onPaused prévio não bloqueia', () {
      final container = buildContainer(biometric: biometric);
      addTearDown(container.dispose);

      container.read(appLockProvider.notifier).onAppResumed();

      expect(container.read(appLockProvider).isLocked, isFalse);
    });
  });

  group('AppLockNotifier — authenticate', () {
    test('biometria bem-sucedida desbloqueia', () async {
      when(() => biometric.authenticate())
          .thenAnswer((_) async => BiometricResult.success);

      final container = buildContainer(biometric: biometric);
      addTearDown(container.dispose);

      // Forçar bloqueio manualmente
      final notifier = container.read(appLockProvider.notifier);
      notifier.state = notifier.state.copyWith(isLocked: true);

      await notifier.authenticate();

      expect(container.read(appLockProvider).isLocked, isFalse);
      expect(container.read(appLockProvider).failures, 0);
    });

    test('1 falha incrementa contador sem bloquear', () async {
      when(() => biometric.authenticate())
          .thenAnswer((_) async => BiometricResult.failed);

      final container = buildContainer(biometric: biometric);
      addTearDown(container.dispose);

      final notifier = container.read(appLockProvider.notifier);
      notifier.state = notifier.state.copyWith(isLocked: true);

      await notifier.authenticate();

      expect(container.read(appLockProvider).failures, 1);
      expect(container.read(appLockProvider).isLocked, isTrue);
    });

    test('3 falhas consecutivas fazem logout e desbloqueiam', () async {
      when(() => biometric.authenticate())
          .thenAnswer((_) async => BiometricResult.failed);

      final fakeAuth = FakeAuthNotifier();
      final container = buildContainer(biometric: biometric, fakeAuth: fakeAuth);
      addTearDown(container.dispose);

      final notifier = container.read(appLockProvider.notifier);
      notifier.state = notifier.state.copyWith(isLocked: true);

      await notifier.authenticate(); // failures = 1
      await notifier.authenticate(); // failures = 2
      await notifier.authenticate(); // failures = 3 → logout

      expect(fakeAuth.logoutCalled, isTrue);
      expect(container.read(appLockProvider).isLocked, isFalse);
    });

    test('lockedOut seta flag isLockedOut', () async {
      when(() => biometric.authenticate())
          .thenAnswer((_) async => BiometricResult.lockedOut);

      final container = buildContainer(biometric: biometric);
      addTearDown(container.dispose);

      final notifier = container.read(appLockProvider.notifier);
      notifier.state = notifier.state.copyWith(isLocked: true);

      await notifier.authenticate();

      expect(container.read(appLockProvider).isLockedOut, isTrue);
    });

    test('notAvailable desbloqueia automaticamente', () async {
      when(() => biometric.authenticate())
          .thenAnswer((_) async => BiometricResult.notAvailable);

      final container = buildContainer(biometric: biometric);
      addTearDown(container.dispose);

      final notifier = container.read(appLockProvider.notifier);
      notifier.state = notifier.state.copyWith(isLocked: true);

      await notifier.authenticate();

      expect(container.read(appLockProvider).isLocked, isFalse);
    });
  });

  group('AppLockNotifier — unlock', () {
    test('unlock reseta estado completamente', () async {
      final container = buildContainer(biometric: biometric);
      addTearDown(container.dispose);

      final notifier = container.read(appLockProvider.notifier);
      notifier.state = const AppLockState(isLocked: true, failures: 2);

      notifier.unlock();

      final state = container.read(appLockProvider);
      expect(state.isLocked, isFalse);
      expect(state.failures, 0);
    });
  });
}
