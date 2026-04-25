import 'package:cadife_smart_travel/core/security/biometric_service.dart';
import 'package:cadife_smart_travel/core/security/security_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────

class MockBiometricService extends Mock implements BiometricService {}

// ── Subclasse auxiliar: expõe setter de estado para injetar timestamps ────────

class _TestableSecurityNotifier extends SecurityNotifier {
  _TestableSecurityNotifier(super.biometricService);

  void setLastActive(DateTime time) {
    state = state.copyWith(lastActive: time);
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // Necessário porque SecurityNotifier chama WidgetsBinding.instance.addObserver()
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBiometricService mockBiometric;

  setUp(() {
    mockBiometric = MockBiometricService();
  });

  group('SecurityNotifier — lifecycle e timeout', () {
    test('1. App paused → lastActive é definido com timestamp atual', () {
      final notifier = SecurityNotifier(mockBiometric);
      addTearDown(notifier.dispose);

      expect(notifier.state.lastActive, isNull);

      notifier.didChangeAppLifecycleState(AppLifecycleState.paused);

      expect(notifier.state.lastActive, isNotNull);
      final diff = DateTime.now().difference(notifier.state.lastActive!);
      expect(diff.inSeconds, lessThan(2));
    });

    test('2. App paused → resumed imediatamente → isLocked permanece false', () {
      final notifier = SecurityNotifier(mockBiometric);
      addTearDown(notifier.dispose);

      notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(notifier.state.isLocked, isFalse);
    });

    test('3. lastActive com 6 minutos atrás → resumed → isLocked: true', () {
      final notifier = _TestableSecurityNotifier(mockBiometric);
      addTearDown(notifier.dispose);

      notifier.setLastActive(DateTime.now().subtract(const Duration(minutes: 6)));
      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(notifier.state.isLocked, isTrue);
    });

    test('4. unlock() com biometria bem-sucedida → isLocked: false', () async {
      final notifier = _TestableSecurityNotifier(mockBiometric);
      addTearDown(notifier.dispose);

      notifier.setLastActive(DateTime.now().subtract(const Duration(minutes: 6)));
      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(notifier.state.isLocked, isTrue);

      when(() => mockBiometric.authenticate()).thenAnswer((_) async => true);

      final result = await notifier.unlock();

      expect(result, isTrue);
      expect(notifier.state.isLocked, isFalse);
    });

    test('5. unlock() com biometria recusada → isLocked permanece true', () async {
      final notifier = _TestableSecurityNotifier(mockBiometric);
      addTearDown(notifier.dispose);

      notifier.setLastActive(DateTime.now().subtract(const Duration(minutes: 6)));
      notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(notifier.state.isLocked, isTrue);

      when(() => mockBiometric.authenticate()).thenAnswer((_) async => false);

      final result = await notifier.unlock();

      expect(result, isFalse);
      expect(notifier.state.isLocked, isTrue);
    });
  });
}
