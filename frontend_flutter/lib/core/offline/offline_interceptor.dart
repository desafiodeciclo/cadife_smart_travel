import 'package:cadife_smart_travel/core/offline/offline_manager.dart';
import 'package:dio/dio.dart';

/// Interceptor Dio que salva automaticamente respostas bem-sucedidas no cache
/// e retorna dados offline quando o device perde conectividade.
class OfflineInterceptor extends Interceptor {
  OfflineInterceptor(this._offlineManager);

  final OfflineManager _offlineManager;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method == 'GET' && response.statusCode == 200) {
      final cacheKey = _cacheKey(response.requestOptions);
      _offlineManager.saveToCache(cacheKey, response.data);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_isNetworkError(err) && err.requestOptions.method == 'GET') {
      final cacheKey = _cacheKey(err.requestOptions);
      final cached = _offlineManager.getFromCacheOffline(cacheKey);

      if (cached != null) {
        handler.resolve(
          Response(
            data: cached,
            statusCode: 200,
            requestOptions: err.requestOptions,
            extra: {'from_cache': true},
          ),
        );
        return;
      }
    }
    handler.next(err);
  }

  String _cacheKey(RequestOptions options) {
    final uri = options.uri.toString();
    final query = options.queryParameters.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return '${options.method}:$uri:$query';
  }

  bool _isNetworkError(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
