import 'package:cadife_smart_travel/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

// ── Value object retornado pelo isolate background ────────────────────────────

class _JwtCheckResult {
  const _JwtCheckResult({required this.isExpired, required this.payload});
  final bool isExpired;
  final Map<String, dynamic> payload;
}

// Top-level obrigatório para compute() — não pode ser closure ou método de instância
_JwtCheckResult _validateJwtInBackground(String token) {
  try {
    if (JwtDecoder.isExpired(token)) {
      return const _JwtCheckResult(isExpired: true, payload: {});
    }
    return _JwtCheckResult(isExpired: false, payload: JwtDecoder.decode(token));
  } catch (_) {
    return const _JwtCheckResult(isExpired: true, payload: {});
  }
}

// ── AuthState ─────────────────────────────────────────────────────────────────

class AuthState {
  final bool isLoggedIn;
  final String? userPerfil;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isLoggedIn = false,
    this.userPerfil,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userPerfil,
    bool? isLoading,
    String? error,
  }) => AuthState(
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    userPerfil: userPerfil ?? this.userPerfil,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

// ── AuthNotifier ──────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;

  AuthNotifier(this._api) : super(const AuthState());

  Future<void> checkSession() async {
    // Platform channel (flutter_secure_storage) — deve ficar na main isolate
    final token = await _api.getAccessToken();
    if (token == null) return;

    // CPU-bound (base64 decode) — offloadado para isolate separado via compute()
    final result = await compute(_validateJwtInBackground, token);

    if (result.isExpired) {
      // Platform channel — deve ficar na main isolate
      await _api.clearTokens();
      return;
    }

    // StateNotifier.state — deve ficar na main isolate
    state = state.copyWith(
      isLoggedIn: true,
      userPerfil: result.payload['perfil'] as String? ?? result.payload['role'] as String?,
    );
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      await _api.saveTokens(
        response.data['access_token'],
        response.data['refresh_token'],
      );
      final me = await _api.get('/users/me');
      state = state.copyWith(
        isLoggedIn: true,
        userPerfil: me.data['perfil'],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Credenciais inválidas. Verifique e-mail e senha.',
      );
    }
  }

  Future<void> logout() async {
    await _api.clearTokens();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(apiServiceProvider)),
);
