import 'dart:convert';

import 'package:cadife_smart_travel/core/ports/auth_port.dart';
import 'package:cadife_smart_travel/core/security/jwt_validator.dart';
import 'package:cadife_smart_travel/core/security/secure_config.dart';
import 'package:cadife_smart_travel/shared/models/user_model.dart';

/// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
/// AVISO: ESTE REPOSITÓRIO É APENAS PARA DESENVOLVIMENTO (MOCK).
/// DEVE SER REMOVIDO OU SUBSTITUÍDO PELO AuthRepositoryImpl EM PRODUÇÃO.
/// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
class MockAuthRepository implements AuthPort {
  MockAuthRepository({required SecureConfig secureConfig})
      : _secureConfig = secureConfig;

  final SecureConfig _secureConfig;
  UserModel? _currentUser;

  @override
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final role =
        email.contains('agencia') ? UserRole.consultor : UserRole.cliente;

    _currentUser = UserModel(
      id: 'mock-id-123',
      name: role == UserRole.consultor ? 'Consultor de Teste' : 'Cliente de Teste',
      email: email,
      role: role,
    );

    await _secureConfig.saveTokens(
      accessToken: _buildMockJwt(_currentUser!.id, role),
      refreshToken: _buildMockJwt(_currentUser!.id, role, hours: 168),
    );

    return _currentUser!;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    final token = await _secureConfig.getAccessToken();
    if (token != null && JwtValidator.isTokenValid(token)) {
      _currentUser = const UserModel(
        id: 'mock-id-123',
        name: 'Usuário Restaurado',
        email: 'restored@mock.com',
        role: UserRole.cliente,
      );
    }
    return _currentUser;
  }

  @override
  Future<bool> isLoggedIn() async {
    if (_currentUser != null) return true;
    final token = await _secureConfig.getAccessToken();
    return JwtValidator.isTokenValid(token);
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    await _secureConfig.clearTokens();
  }

  @override
  Future<TokenModel> refreshToken(String refreshToken) async {
    final newToken = _buildMockJwt('mock-id-123', UserRole.cliente);
    return TokenModel(
      accessToken: newToken,
      refreshToken: _buildMockJwt('mock-id-123', UserRole.cliente, hours: 168),
      expiresIn: 3600,
    );
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    return login(email, password);
  }

  @override
  Future<void> saveFcmToken(String token) async {}

  /// Constrói um JWT com payload base64url válido (sem verificação de assinatura).
  /// Necessário para que JwtValidator.isTokenValid() funcione corretamente em dev.
  String _buildMockJwt(String userId, UserRole role, {int hours = 24}) {
    final header = base64Url
        .encode(utf8.encode('{"alg":"none","typ":"JWT"}'))
        .replaceAll('=', '');

    final exp =
        DateTime.now().add(Duration(hours: hours)).millisecondsSinceEpoch ~/
            1000;
    final payloadMap = {
      'sub': userId,
      'exp': exp,
      'role': role.name,
      'iss': 'cadife-mock',
    };
    final payload =
        base64Url.encode(utf8.encode(jsonEncode(payloadMap))).replaceAll('=', '');

    return '$header.$payload.mock-signature';
  }
}
