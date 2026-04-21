import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

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

  AuthNotifier(this._api) : super(const AuthState()) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;
    try {
      final response = await _api.get('/users/me');
      state = state.copyWith(
        isLoggedIn: true,
        userPerfil: response.data['perfil'],
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
