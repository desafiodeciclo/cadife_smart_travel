import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:cadife_smart_travel/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

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
        final userResult = await _repository.getUserProfile();
        return userResult.fold((_) => null, (user) => user);
      },
    );
  }

  Future<void> login(String email, String password) async {
    debugPrint('AUTH_NOTIFIER: Starting login for $email');
    state = const AsyncValue.loading();
    final result = await _repository.login(email, password);
    state = result.fold(
      (failure) {
        debugPrint('AUTH_NOTIFIER: Login FAILED: ${failure.message}');
        return AsyncValue.error(failure.message, StackTrace.current);
      },
      (user) {
        debugPrint('AUTH_NOTIFIER: Login SUCCESS: ${user.email} (Role: ${user.role})');
        return AsyncValue.data(user);
      },
    );
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _repository.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncValue.loading();
    final result = await _repository.register(name, email, password);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      AsyncValue.data,
    );
  }

  Future<Either<Failure, void>> forgotPassword(String email) {
    return _repository.forgotPassword(email);
  }
}
