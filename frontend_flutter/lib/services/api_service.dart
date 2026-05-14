import 'package:cadife_smart_travel/core/security/secure_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

/// Service wrapper around the project's Dio client.
///
/// Uses the shared [Dio] instance from [GetIt] (already configured with
/// certificate pinning, auth interceptor, error interceptor and offline
/// interceptor via the Dio client factory).
///
/// Token persistence is delegated to [SecureConfig].
class ApiService {
  ApiService({
    Dio? dio,
    SecureConfig? secureConfig,
  })  : _dio = dio ?? GetIt.I<Dio>(),
        _secureConfig = secureConfig ?? GetIt.I<SecureConfig>();

  final Dio _dio;
  final SecureConfig _secureConfig;

  /// Clear all stored tokens.
  Future<void> clearToken() => _secureConfig.clearTokens();

  /// Generic HTTP GET.
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(endpoint);
      return response.data ?? {};
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearToken();
        throw Exception('Unauthorized - token invalid');
      }
      debugPrint('GET Error: $e');
      rethrow;
    }
  }

  /// Generic HTTP POST.
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        endpoint,
        data: data,
      );
      return response.data ?? {};
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearToken();
        throw Exception('Unauthorized - token invalid');
      }
      debugPrint('POST Error: $e');
      rethrow;
    }
  }

  /// Generic HTTP PATCH.
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        endpoint,
        data: data,
      );
      return response.data ?? {};
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearToken();
        throw Exception('Unauthorized - token invalid');
      }
      debugPrint('PATCH Error: $e');
      rethrow;
    }
  }

  /// Generic HTTP DELETE.
  Future<Map<String, dynamic>?> delete(String endpoint) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(endpoint);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearToken();
        throw Exception('Unauthorized - token invalid');
      }
      debugPrint('DELETE Error: $e');
      rethrow;
    }
  }
}

// Riverpod provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
