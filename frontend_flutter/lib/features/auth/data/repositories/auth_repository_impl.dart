import 'package:cadife_smart_travel/core/security/jwt_utils.dart';
import 'package:cadife_smart_travel/core/security/secure_config.dart';
import 'package:cadife_smart_travel/features/auth/data/datasources/i_auth_datasource.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/auth/domain/repositories/i_auth_repository.dart';

class AuthRepositoryImpl implements IAuthRepository {
  AuthRepositoryImpl({
    required IAuthDatasource remoteDatasource,
    required SecureConfig secureConfig,
  })  : _remoteDatasource = remoteDatasource,
        _secureConfig = secureConfig;

  final IAuthDatasource _remoteDatasource;
  final SecureConfig _secureConfig;

  @override
  Future<AuthUser> login(String email, String password, {UserRole? profileHint}) async {
    final data = await _remoteDatasource.login(email, password, profileHint: profileHint);
    
    final tokenData = data['token'] as Map<String, dynamic>;
    await _secureConfig.saveTokens(
      accessToken: tokenData['access_token'] as String,
      refreshToken: tokenData['refresh_token'] as String,
    );
    
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  @override
  Future<AuthUser> register(String name, String email, String password) async {
    final data = await _remoteDatasource.register(name, email, password);
    return AuthUser.fromJson(data);
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDatasource.logout();
    } catch (_) {
      // Ignore logout errors, continue to clear local tokens
    } finally {
      await _secureConfig.clearTokens();
    }
  }

  @override
  Future<TokenModel> refreshToken(String refreshToken) async {
    final data = await _remoteDatasource.refreshToken(refreshToken);
    
    await _secureConfig.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    
    return TokenModel.fromJson(data);
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    try {
      final data = await _remoteDatasource.getCurrentUser();
      if (data != null) {
        return AuthUser.fromJson(data);
      }
      return _getUserFromStoredToken();
    } catch (_) {
      return _getUserFromStoredToken();
    }
  }

  Future<AuthUser?> _getUserFromStoredToken() async {
    final token = await _secureConfig.getAccessToken();
    if (token == null) return null;
    
    final payload = JwtUtils.decodePayload(token);
    if (payload == null) return null;
    
    return AuthUser(
      id: payload['sub'] as String? ?? '',
      name: payload['name'] as String? ?? payload['email'] as String? ?? 'Usuário',
      email: payload['email'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == (payload['role'] as String?),
        orElse: () => UserRole.cliente,
      ),
    );
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _secureConfig.getAccessToken();
    return token != null;
  }

  @override
  Future<void> saveFcmToken(String token) async {
    await _remoteDatasource.saveFcmToken(token);
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _remoteDatasource.forgotPassword(email);
  }
}
