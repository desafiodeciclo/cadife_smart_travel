import 'package:cadife_smart_travel/core/network/dio_client.dart';
import 'package:cadife_smart_travel/core/network/network_info.dart';
import 'package:cadife_smart_travel/core/offline/offline_manager.dart';
import 'package:cadife_smart_travel/core/security/secure_config.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

/// Service Locator global — get_it com registro explícito e lifecycle controlado.
///
/// REGRA: Singletons APENAS para serviços performance-critical (network, DB, security).
/// Tudo else usa `factory` para evitar memory leaks.
final sl = GetIt.instance;

/// Registra todos os serviços core.
///
/// Chamado uma vez no `main()` antes de `runApp()`.
/// A ordem importa: dependências primeiro.
Future<void> setupServiceLocator({
  List<String>? pinnedCertificates,
  List<String>? backupCertificates,
}) async {
  // ── 1. Infra Layer (singletons — performance-critical) ──

  // Network Info (conectividade)
  sl.registerLazySingleton<NetworkInfo>(NetworkInfo.new);

  // Secure Config (credenciais, pins)
  sl.registerLazySingleton<SecureConfig>(SecureConfig.new);

  // Offline Manager (cache Hive + connectivity monitor)
  sl.registerLazySingleton<OfflineManager>(
    () => OfflineManager(networkInfo: sl<NetworkInfo>()),
  );

  // ── 2. Network Layer ───────────────────────────────────

  // Dio (HTTP client com certificate pinning)
  sl.registerLazySingleton<Dio>(() {
    const isDebug = bool.fromEnvironment('dart.vm.product');
    if (!isDebug &&
        (pinnedCertificates == null || pinnedCertificates.isEmpty)) {
      return DioClientFactory.createUnpinned();
    }
    return DioClientFactory.createPinned(
      pinnedSha256: pinnedCertificates ?? [],
      backupPinnedSha256: backupCertificates,
      tokenProvider: () => sl<SecureConfig>().getAccessToken(),
    );
  });

  // ── 3. Feature Layer ───────────────────────────────────
  // Repositories e Notifiers são registrados aqui por feature module.
}

/// Inicializa infra e registra dependências no DI.
///
/// Chamada única em `main()`.
Future<void> initDependencies() async {
  await sl<OfflineManager>().initialize();
}

/// Limpa dependências (logout, reset).
Future<void> resetDependencies() async {
  await sl<OfflineManager>().clearUserData();
  await sl<SecureConfig>().clearTokens();
}

/// Descarta completamente o DI (dispose).
Future<void> disposeDependencies() async {
  await sl<OfflineManager>().dispose();
  await sl.reset(dispose: true);
}
