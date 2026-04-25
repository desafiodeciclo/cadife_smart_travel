import 'package:cadife_smart_travel/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

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

  AuthState copyWith({bool? isLoggedIn, String? userPerfil, bool? isLoading, String? error}) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        userPerfil: userPerfil ?? this.userPerfil,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;

  AuthNotifier(this._api) : super(const AuthState());

  Future<void> checkSession() async {
    final token = await _api.getAccessToken();
    if (token == null) return;
    
    try {
      if (JwtDecoder.isExpired(token)) {
        await _api.clearTokens();
        return;
      }
      
      final payload = JwtDecoder.decode(token);
      state = state.copyWith(
        isLoggedIn: true,
        userPerfil: payload['perfil'] ?? payload['role'], // Map payload to userPerfil
      );
    } catch (_) {
      await _api.clearTokens();
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
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
