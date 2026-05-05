import 'package:cadife_smart_travel/core/constants/app_constants.dart';
import 'package:cadife_smart_travel/core/security/biometric_service.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_event.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_bloc_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final biometricServiceProvider = Provider<BiometricService>(
  (_) => BiometricService(),
);

final appLockProvider =
    NotifierProvider<AppLockNotifier, AppLockState>(AppLockNotifier.new);

class AppLockState {
  const AppLockState({
    this.isLocked = false,
    this.failures = 0,
    this.isLockedOut = false,
  });

  final bool isLocked;
  final int failures;
  final bool isLockedOut;

  AppLockState copyWith({bool? isLocked, int? failures, bool? isLockedOut}) {
    return AppLockState(
      isLocked: isLocked ?? this.isLocked,
      failures: failures ?? this.failures,
      isLockedOut: isLockedOut ?? this.isLockedOut,
    );
  }
}

class AppLockNotifier extends Notifier<AppLockState> {
  DateTime? _pausedAt;

  @override
  AppLockState build() => const AppLockState();

  void onAppPaused() {
    _pausedAt = DateTime.now();
  }

  void onAppResumed() {
    final paused = _pausedAt;
    _pausedAt = null;
    if (paused == null) return;

    final elapsed = DateTime.now().difference(paused);
    if (elapsed >= AppConstants.appLockTimeout) {
      state = state.copyWith(isLocked: true, failures: 0);
    }
  }

  /// Desbloqueia imediatamente (ex: após logout bem-sucedido).
  void unlock() {
    state = const AppLockState();
  }

  Future<void> authenticate() async {
    final biometric = ref.read(biometricServiceProvider);
    final result = await biometric.authenticate();

    switch (result) {
      case BiometricResult.success:
        state = const AppLockState();

      case BiometricResult.lockedOut:
        state = state.copyWith(isLockedOut: true);

      case BiometricResult.notAvailable:
        // Dispositivo sem nenhum mecanismo de segurança — desbloqueia com aviso
        state = const AppLockState();

      case BiometricResult.failed:
        final newFailures = state.failures + 1;
        if (newFailures >= AppConstants.appLockMaxFailures) {
          // Máximo de tentativas atingido — logout forçado por segurança
          ref.read(authBlocProvider).add(const AuthEvent.logoutRequested());
          state = const AppLockState();
        } else {
          state = state.copyWith(failures: newFailures);
        }
    }
  }
}
