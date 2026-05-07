import 'package:cadife_smart_travel/core/analytics/analytics_service.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (newValue is AsyncError) {
      final error = newValue.error;
      final stack = newValue.stackTrace;
      
      _handleError(error, stack, provider.name ?? provider.runtimeType.toString());
    }
  }

  void _handleError(Object error, StackTrace stack, String providerName) {
    final analytics = sl<AnalyticsService>();
    
    bool isUnexpected = true;
    
    if (error is DioException) {
      // Erros de rede esperados (ex: 401, 403, 404)
      if (error.response?.statusCode != null && error.response!.statusCode! < 500) {
        isUnexpected = false;
      }
      // Sem internet é esperado
      if (error.type == DioExceptionType.connectionError || error.type == DioExceptionType.unknown) {
        isUnexpected = false;
      }
    }
    
    // Erros de validação (se houver uma classe específica, adicione aqui)
    // if (error is ValidationError) isUnexpected = false;

    if (isUnexpected) {
      analytics.logError(
        'Provider Error [$providerName]: $error',
        stack,
        fatal: false,
      );
    } else {
      analytics.logBreadcrumb('Expected Provider Error [$providerName]: $error');
    }
  }
}
