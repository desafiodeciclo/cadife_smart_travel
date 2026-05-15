import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CadifeLogInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!kDebugMode) {
      handler.next(options);
      return;
    }

    log(
      'Request: ${options.method} ${options.path}',
      name: 'Dio',
      level: 1000,
    );

    final headers = _sanitizeHeaders(options.headers);
    log('Headers: $headers', name: 'Dio', level: 1000);

    if (options.data != null) {
      final sanitized = _sanitizeBody(options.data);
      log('Body: $sanitized', name: 'Dio', level: 1000);
    }

    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    if (!kDebugMode) {
      handler.next(response);
      return;
    }

    log(
      'Response: ${response.statusCode} ${response.requestOptions.path}',
      name: 'Dio',
      level: 1000,
    );

    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (kDebugMode) {
      log(
        'Error: ${err.type} on ${err.requestOptions.path}',
        name: 'Dio',
        error: err,
        level: 1000,
      );
    }
    handler.next(err);
  }

  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    if (sanitized['Authorization'] != null) {
      sanitized['Authorization'] = _maskToken(sanitized['Authorization']);
    }
    return sanitized;
  }

  /// Mascarar JWT: 'Bearer xxxx...XXXXXXXX' (últimos 8 chars visíveis).
  @visibleForTesting
  static String maskToken(String? value) {
    if (value == null || value.isEmpty) return '***';
    if (!value.startsWith('Bearer ')) return '***';
    final token = value.substring(7);
    if (token.length <= 8) return 'Bearer ***';
    return 'Bearer xxxx...${token.substring(token.length - 8)}';
  }

  /// Remover campos sensíveis de request body.
  @visibleForTesting
  static dynamic sanitizeBody(dynamic data) {
    if (data == null) return null;
    if (data is! Map) return data;

    const sensitiveKeys = {
      'password',
      'token',
      'email',
      'access_token',
      'refresh_token',
    };

    final sanitized = <String, dynamic>{};
    (data as Map<String, dynamic>).forEach((key, value) {
      if (sensitiveKeys.contains(key.toLowerCase())) {
        sanitized[key] = '***';
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  dynamic _sanitizeBody(dynamic data) => sanitizeBody(data);

  String _maskToken(dynamic value) => maskToken(value.toString());
}
