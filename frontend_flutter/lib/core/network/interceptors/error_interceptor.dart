import 'package:cadife_smart_travel/core/network/exceptions/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[ErrorInterceptor] ${err.type} — '
        '${err.response?.statusCode} — ${err.message}',
      );
    }

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: _mapError(err),
        stackTrace: err.stackTrace,
        message: err.message,
      ),
    );
  }

  ApiException _mapError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();

      case DioExceptionType.badResponse:
        final status = err.response?.statusCode;
        final message =
            err.response?.data is Map ? err.response?.data['message'] as String? : null;

        return switch (status) {
          401 => const UnauthorizedException(),
          403 => const ForbiddenException(),
          409 => ConflictException(message),
          _ when status != null && status >= 500 => ServerException(status, message),
          _ => UnknownApiException(err),
        };

      default:
        return UnknownApiException(err);
    }
  }
}
