import 'package:cadife_smart_travel/core/config/env_config.dart';
import 'package:cadife_smart_travel/core/network/dio_client.dart';
import 'package:cadife_smart_travel/core/network/interceptors/auth_interceptor.dart';
import 'package:cadife_smart_travel/core/network/interceptors/error_interceptor.dart';
import 'package:cadife_smart_travel/core/offline/offline_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthInterceptor extends Mock implements AuthInterceptor {}
class MockErrorInterceptor extends Mock implements ErrorInterceptor {}
class MockOfflineInterceptor extends Mock implements OfflineInterceptor {}

void main() {
  final sl = GetIt.instance;

  setUpAll(() {
    // Registra o EnvConfig no GetIt para que o DioClientFactory possa acessá-lo via ApiConstants
    if (!sl.isRegistered<EnvConfig>()) {
      sl.registerSingleton<EnvConfig>(EnvConfig.dev);
    }
  });

  group('DioClientFactory Tests', () {
    test('createUnpinned creates a Dio instance with default options', () {
      final dio = DioClientFactory.createUnpinned();
      expect(dio, isA<Dio>());
      // Verifica se a baseUrl está correta (vem do EnvConfig.dev)
      expect(dio.options.baseUrl, EnvConfig.dev.apiBaseUrl);
    });

    test('createPinned creates a Dio instance with interceptors', () {
      final auth = MockAuthInterceptor();
      final error = MockErrorInterceptor();
      final offline = MockOfflineInterceptor();

      final dio = DioClientFactory.createPinned(
        pinnedSha256: ['some-pin'],
        authInterceptor: auth,
        errorInterceptor: error,
        offlineInterceptor: offline,
      );

      expect(dio, isA<Dio>());
      // No current implementation, interceptors are added in a specific order:
      // error, then auth, then offline.
      // We check if they are present.
      expect(dio.interceptors.contains(auth), isTrue);
      expect(dio.interceptors.contains(error), isTrue);
      expect(dio.interceptors.contains(offline), isTrue);
    });

    test('createForRefresh creates a lightweight Dio without auth interceptors', () {
      final dio = DioClientFactory.createForRefresh(
        pinnedSha256: ['some-pin'],
      );

      expect(dio, isA<Dio>());
      // Should not contain auth interceptors to prevent infinite loops during refresh
      final hasAuth = dio.interceptors.any((i) => i is AuthInterceptor);
      expect(hasAuth, isFalse);
    });
  });
}
