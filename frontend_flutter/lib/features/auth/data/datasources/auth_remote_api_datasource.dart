import 'dart:developer' as developer;

import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/features/auth/data/datasources/i_auth_datasource.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:dio/dio.dart';

class AuthRemoteApiDatasource implements IAuthDatasource {
  AuthRemoteApiDatasource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> login(String email, String password, {UserRole? profileHint}) async {
    const url = ApiConstants.login;
    developer.log('LOGIN REQUEST: POST $url', name: 'AuthRemote');
    try {
      final response = await _dio.post(
        url,
        data: {
          'email': email,
          'password': password,
          if (profileHint != null) 'role': profileHint.name,
        },
      );
      developer.log('LOGIN SUCCESS: status=${response.statusCode}', name: 'AuthRemote');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      developer.log('LOGIN ERROR: ${e.type}', name: 'AuthRemote');
      developer.log('LOGIN ERROR MESSAGE: ${e.message}', name: 'AuthRemote');
      developer.log('LOGIN ERROR RESPONSE: ${e.response?.statusCode} - ${e.response?.data}', name: 'AuthRemote');
      if (e.response?.statusCode == 429) {
        throw Exception('Muitas tentativas. Por favor, aguarde um minuto e tente novamente.');
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {'name': name, 'email': email, 'password': password},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw Exception('Muitas tentativas. Por favor, aguarde um minuto e tente novamente.');
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _dio.post(ApiConstants.logout);
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile() async {
    final response = await _dio.get(ApiConstants.me);
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
    try {
      await _dio.post(ApiConstants.forgotPassword, data: {'email': email});
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw Exception('Muitas tentativas. Por favor, aguarde um minuto e tente novamente.');
      }
      rethrow;
    }
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _dio.post(
      ApiConstants.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  @override
  Future<void> resetPassword(String token, String newPassword) async {
    await _dio.post(
      ApiConstants.resetPassword,
      data: {
        'token': token,
        'new_password': newPassword,
      },
    );
  }

  @override
  Future<void> logoutAllDevices() async {
    await _dio.post(ApiConstants.logoutAllDevices);
  }
}
