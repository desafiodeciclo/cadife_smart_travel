import 'package:cadife_smart_travel/core/notifications/fcm_manager.dart';
import 'package:cadife_smart_travel/core/ports/auth_port.dart';
import 'package:cadife_smart_travel/shared/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authPortProvider = Provider<AuthPort>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final authPort = ref.watch(authPortProvider);
    final isLoggedIn = await authPort.isLoggedIn();
    if (!isLoggedIn) return const AuthState.unauthenticated();
    final user = await authPort.getCurrentUser();
    if (user == null) return const AuthState.unauthenticated();
    return AuthState.authenticated(user);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final authPort = ref.read(authPortProvider);
      final user = await authPort.login(email, password);
      // Envia o token FCM para o backend assim que o usuário está autenticado.
      await FCMManager.sendTokenToBackend();
      return AuthState.authenticated(user);
    });
  }

  Future<void> logout() async {
    final authPort = ref.read(authPortProvider);
    await authPort.logout();
    state = const AsyncData(AuthState.unauthenticated());
  }

  /// Valida o JWT armazenado localmente (decode offline do claim `exp`).
  ///
  /// Chamado pela SplashScreen durante a animação — evita round-trip ao backend.
  /// Se o token for válido, restaura a sessão; se inválido/ausente, faz logout.
  Future<void> validateLocalToken() async {
    state = const AsyncLoading();
    try {
      final authPort = ref.read(authPortProvider);
      final isLoggedIn = await authPort.isLoggedIn();
      if (!isLoggedIn) {
        await authPort.logout();
        state = const AsyncData(AuthState.unauthenticated());
        return;
      }
      final user = await authPort.getCurrentUser();
      if (user == null) {
        await authPort.logout();
        state = const AsyncData(AuthState.unauthenticated());
        return;
      }
      state = AsyncData(AuthState.authenticated(user));
    } catch (_) {
      state = const AsyncData(AuthState.unauthenticated());
    }
  }
}

sealed class AuthState {
  const AuthState();
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.authenticated(UserModel user) = AuthAuthenticated;
  const factory AuthState.loading() = AuthLoading;
}

class AuthUnauthenticated implements AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticated implements AuthState {
  const AuthAuthenticated(this.user);
  final UserModel user;
}

class AuthLoading implements AuthState {
  const AuthLoading();
}

extension AuthStateX on AuthState {
  bool get isAuthenticated => this is AuthAuthenticated;
  String? get userPerfil => maybeWhen(
        authenticated: (u) => u.role == UserRole.cliente ? 'cliente' : 'agencia',
        orElse: () => null,
      );
  UserModel? get user => maybeWhen(authenticated: (u) => u, orElse: () => null);
  T maybeWhen<T>({
    T Function(UserModel user)? authenticated,
    T Function()? unauthenticated,
    T Function()? loading,
    required T Function() orElse,
  }) {
    return switch (this) {
      AuthAuthenticated(:final user) => authenticated?.call(user) ?? orElse(),
      AuthUnauthenticated() => unauthenticated?.call() ?? orElse(),
      AuthLoading() => loading?.call() ?? orElse(),
    };
  }
}
