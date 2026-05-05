import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para gerenciar o estado de autenticação global.
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthUser?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  late IAuthRepository _repository;

  @override
  Future<AuthUser?> build() async {
    _repository = ref.watch(authRepositoryProvider);
    final isLoggedIn = await _repository.isLoggedIn();
    
    return isLoggedIn.fold(
      (failure) => null,
      (logged) async {
        if (!logged) return null;
        final userResult = await _repository.getCurrentUser();
        return userResult.fold((_) => null, (user) => user);
      },
    );
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    final result = await _repository.login(email, password);
    state = await result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      AsyncValue.data,
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}
