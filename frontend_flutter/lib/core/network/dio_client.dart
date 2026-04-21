import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/core/constants/app_constants.dart';
import 'package:cadife_smart_travel/core/security/certificate_pinning_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Factory para criar instância Dio configurada com:
/// - Base URL, timeouts
/// - Certificate pinning (SHA-256)
/// - Auth interceptor (JWT Bearer)
/// - Logging em debug
class DioClientFactory {
  DioClientFactory._();

  /// Cria Dio com certificate pinning nativo.
  ///
  /// [pinnedSha256] — lista de hashes SHA-256 em Base64 dos certificados confiáveis.
  /// [backupPinnedSha256] — pins de backup para rotação sem downtime.
  /// [tokenProvider] — função que retorna o access token atual (para refresh automático).
  static Dio createPinned({
    required List<String> pinnedSha256,
    List<String>? backupPinnedSha256,
    Future<String?> Function()? tokenProvider,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(
          milliseconds: AppConstants.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: AppConstants.receiveTimeout,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Certificate pinning via HttpClient nativo
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () =>
          CertificatePinningInterceptor.createPinnedHttpClient(
            pinnedSha256: pinnedSha256,
            backupPinnedSha256: backupPinnedSha256,
          ),
    );

    // Auth interceptor: injeta Bearer token
    if (tokenProvider != null) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final token = await tokenProvider();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
          },
          onError: (error, handler) {
            handler.next(error);
          },
        ),
      );
    }

    return dio;
  }

  /// Cria Dio sem pinning (apenas para desenvolvimento local).
  static Dio createUnpinned() {
    return Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(
          milliseconds: AppConstants.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: AppConstants.receiveTimeout,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }
}
