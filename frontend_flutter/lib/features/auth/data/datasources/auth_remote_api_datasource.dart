import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/features/auth/data/datasources/i_auth_datasource.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:dio/dio.dart';

class AuthRemoteApiDatasource implements IAuthDatasource {
  AuthRemoteApiDatasource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> login(String email, String password, {UserRole? profileHint}) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
        if (profileHint != null) 'role': profileHint.name,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await _dio.post(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final response = await _dio.get('/users/me');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      ApiConstants.refresh,
      data: {'refresh_token': refreshToken},
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> saveFcmToken(String token) async {
    await _dio.post(ApiConstants.registerFcmToken, data: {'fcm_token': token});
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _dio.post(ApiConstants.forgotPassword, data: {'email': email});
  }
}
