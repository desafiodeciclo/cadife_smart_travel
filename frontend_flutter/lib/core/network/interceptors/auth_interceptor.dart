import 'dart:async';

import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/core/security/secure_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureConfig secureConfig,
    required Dio refreshDio,
    required VoidCallback onTokenExpired,
  })  : _secureConfig = secureConfig,
        _refreshDio = refreshDio,
        _onTokenExpired = onTokenExpired;

  final SecureConfig _secureConfig;

  // Dedicated Dio without auth/error interceptors — prevents re-entry and infinite loops.
  final Dio _refreshDio;

  final VoidCallback _onTokenExpired;

  // null = no refresh in flight; non-null = refresh owned by another coroutine.
  Completer<bool>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureConfig.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Guard: never attempt refresh when the refresh endpoint itself returns 401,
    // or this interceptor would loop infinitely.
    if (err.requestOptions.path == ApiConstants.refresh) {
      handler.next(err);
      return;
    }

    if (_refreshCompleter != null) {
      // Another coroutine owns the refresh — wait for its result.
      final success = await _refreshCompleter!.future;
      if (success) {
        final newToken = await _secureConfig.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        try {
          final response = await _refreshDio.fetch(err.requestOptions);
          handler.resolve(response);
        } on DioException catch (e) {
          handler.reject(e);
        }
      } else {
        handler.next(err);
      }
      return;
    }

    // This coroutine owns the refresh cycle.
    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await _secureConfig.getRefreshToken();

      if (refreshToken == null) {
        _refreshCompleter!.complete(false);
        await _secureConfig.clearTokens();
        _onTokenExpired();
        handler.next(err);
        return;
      }

      final response = await _refreshDio.post(
        ApiConstants.refresh,
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['access_token'] as String;
      final newRefreshToken = response.data['refresh_token'] as String;

      await _secureConfig.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      // Signal success before retry so queued waiters read the updated token.
      _refreshCompleter!.complete(true);

      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _refreshDio.fetch(err.requestOptions);
      handler.resolve(retryResponse);
    } catch (e) {
      _refreshCompleter!.complete(false);
      await _secureConfig.clearTokens();
      _onTokenExpired();
      if (kDebugMode) {
        debugPrint('[AuthInterceptor] Token refresh failed: $e');
      }
      handler.next(err);
    } finally {
      _refreshCompleter = null;
    }
  }
}
