import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/core/constants/app_constants.dart';
import 'package:cadife_smart_travel/core/network/interceptors/auth_interceptor.dart';
import 'package:cadife_smart_travel/core/network/interceptors/error_interceptor.dart';
import 'package:cadife_smart_travel/core/offline/offline_interceptor.dart';
import 'package:cadife_smart_travel/core/security/certificate_pinning_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class DioClientFactory {
  DioClientFactory._();

  static BaseOptions _baseOptions() => BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

  /// Main authenticated Dio: cert pinning + auth + error + offline interceptors.
  ///
  /// Interceptor registration order (Dio processes errors LIFO — last added fires first):
  ///   errorInterceptor    → runs LAST:   maps residual DioExceptions to typed ApiExceptions
  ///   authInterceptor     → runs MIDDLE: handles 401 with token refresh + retry
  ///   offlineInterceptor  → runs FIRST:  on network error for GETs, resolves from cache
  static Dio createPinned({
    required List<String> pinnedSha256,
    List<String>? backupPinnedSha256,
    required AuthInterceptor authInterceptor,
    required ErrorInterceptor errorInterceptor,
    required OfflineInterceptor offlineInterceptor,
  }) {
    final dio = Dio(_baseOptions());

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () =>
          CertificatePinningInterceptor.createPinnedHttpClient(
        pinnedSha256: pinnedSha256,
        backupPinnedSha256: backupPinnedSha256,
      ),
    );

    dio.interceptors.add(errorInterceptor);
    dio.interceptors.add(authInterceptor);
    dio.interceptors.add(offlineInterceptor);

    return dio;
  }

  /// Lightweight Dio used exclusively by AuthInterceptor for:
  ///   1. Calling POST /auth/refresh
  ///   2. Retrying the original request after a successful refresh
  ///
  /// Has NO auth, error, or offline interceptors — prevents re-entry and infinite loops.
  static Dio createForRefresh({
    required List<String> pinnedSha256,
    List<String>? backupPinnedSha256,
  }) {
    final dio = Dio(_baseOptions());

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () =>
          CertificatePinningInterceptor.createPinnedHttpClient(
        pinnedSha256: pinnedSha256,
        backupPinnedSha256: backupPinnedSha256,
      ),
    );

    return dio;
  }

  /// Unpinned Dio for local development only (no certificate validation).
  static Dio createUnpinned() {
    return Dio(_baseOptions());
  }
}
