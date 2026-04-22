import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/core/ports/auth_port.dart';
import 'package:cadife_smart_travel/core/security/secure_config.dart';
import 'package:cadife_smart_travel/shared/models/models.dart';
import 'package:dio/dio.dart';

class AuthRepositoryImpl implements AuthPort {
  AuthRepositoryImpl({required Dio dio, required SecureConfig secureConfig})
      : _dio = dio,
        _secureConfig = secureConfig;

  final Dio _dio;
  final SecureConfig _secureConfig;

  @override
  Future<UserModel> login(String email, String password) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    final tokenData = response.data['token'] as Map<String, dynamic>;
    await _secureConfig.saveTokens(
      accessToken: tokenData['access_token'] as String,
      refreshToken: tokenData['refresh_token'] as String,
    );
    return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    final response = await _dio.post(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
    } finally {
      await _secureConfig.clearTokens();
    }
  }

  @override
  Future<TokenModel> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      ApiConstants.refresh,
      data: {'refresh_token': refreshToken},
    );
    final tokenData = response.data as Map<String, dynamic>;
    await _secureConfig.saveTokens(
      accessToken: tokenData['access_token'] as String,
      refreshToken: tokenData['refresh_token'] as String,
    );
    return TokenModel.fromJson(tokenData);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _dio.get('/users/me');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _secureConfig.getAccessToken();
    return token != null;
  }

  @override
  Future<void> saveFcmToken(String token) async {
    await _dio.post(ApiConstants.registerFcmToken, data: {'fcm_token': token});
  }
}