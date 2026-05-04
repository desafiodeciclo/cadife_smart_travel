import 'dart:async';
import 'package:cadife_smart_travel/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_event.dart';
import 'package:cadife_smart_travel/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthForgotPasswordRequested>(_onForgotPasswordRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final isLoggedIn = await _authRepository.isLoggedIn();
    if (isLoggedIn) {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.login(
        event.email,
        event.password,
        profileHint: event.profileHint,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.forgotPassword(event.email);
    } catch (_) {
      // For now, silent fail as it doesn't affect global auth state
    }
  }
}
