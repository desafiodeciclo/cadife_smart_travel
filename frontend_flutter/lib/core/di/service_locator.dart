import 'package:cadife_smart_travel/core/network/dio_client.dart';
import 'package:cadife_smart_travel/core/network/network_info.dart';
import 'package:cadife_smart_travel/core/offline/offline_manager.dart';
import 'package:cadife_smart_travel/core/offline/offline_sync_queue.dart';
import 'package:cadife_smart_travel/core/ports/agenda_port.dart';
import 'package:cadife_smart_travel/core/ports/auth_port.dart';
import 'package:cadife_smart_travel/core/ports/lead_port.dart';
import 'package:cadife_smart_travel/core/ports/proposal_port.dart';
import 'package:cadife_smart_travel/core/security/biometric_service.dart';
import 'package:cadife_smart_travel/core/security/secure_config.dart';
import 'package:cadife_smart_travel/data/repositories/agenda_repository_impl.dart';
import 'package:cadife_smart_travel/data/repositories/auth_repository_impl.dart';
import 'package:cadife_smart_travel/data/repositories/lead_repository_impl.dart';
import 'package:cadife_smart_travel/data/repositories/proposal_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

/// Service Locator global — get_it com registro explícito e lifecycle controlado.
///
/// REGRA: Singletons APENAS para serviços performance-critical (network, DB, security).
/// Repositories são lazySingletons pois encapsulam Dio (singleton) — sem state próprio.
final sl = GetIt.instance;

/// Registra TODOS os serviços core e ports por módulo.
///
/// Chamado uma vez no `main()` antes de `runApp()`.
/// A ordem importa: camadas internas primeiro.
Future<void> setupServiceLocator({
  List<String>? pinnedCertificates,
  List<String>? backupCertificates,
}) async {
  // ── 1. Infra Layer (singletons — performance-critical) ──

  sl.registerLazySingleton<NetworkInfo>(NetworkInfo.new);
  sl.registerLazySingleton<SecureConfig>(SecureConfig.new);
  sl.registerLazySingleton<BiometricService>(BiometricService.new);
  sl.registerLazySingleton<OfflineManager>(
    () => OfflineManager(networkInfo: sl<NetworkInfo>()),
  );
  sl.registerLazySingleton<OfflineSyncQueue>(
    () => OfflineSyncQueue(networkInfo: sl<NetworkInfo>()),
  );

  // ── 2. Network Layer (singleton — reutiliza conexão) ──

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

  // ── 3. Ports (interfaces) → Implementations ──────────
  // Features importam apenas a PORT (interface), nunca a impl.

  _registerAuthModule();
  _registerLeadModule();
  _registerAgendaModule();
  _registerProposalModule();
}

void _registerAuthModule() {
  sl.registerLazySingleton<AuthPort>(
    () => AuthRepositoryImpl(
      dio: sl<Dio>(),
      secureConfig: sl<SecureConfig>(),
    ),
  );
}

void _registerLeadModule() {
  sl.registerLazySingleton<LeadPort>(
    () => LeadRepositoryImpl(
      dio: sl<Dio>(),
      offlineManager: sl<OfflineManager>(),
    ),
  );
}

void _registerAgendaModule() {
  sl.registerLazySingleton<AgendaPort>(
    () => AgendaRepositoryImpl(
      dio: sl<Dio>(),
      offlineManager: sl<OfflineManager>(),
    ),
  );
}

void _registerProposalModule() {
  sl.registerLazySingleton<ProposalPort>(
    () => ProposalRepositoryImpl(
      dio: sl<Dio>(),
      offlineManager: sl<OfflineManager>(),
    ),
  );
}

/// Inicializa infra offline (Hive + SyncQueue).
Future<void> initDependencies() async {
  await sl<OfflineManager>().initialize();
  await sl<OfflineSyncQueue>().initialize();
}

/// Limpa dados do usuário (logout). NÃO descarta infra singletons.
Future<void> resetDependencies() async {
  await sl<OfflineManager>().clearUserData();
  await sl<SecureConfig>().clearTokens();
  await sl<OfflineManager>().clearCache();
  await sl<OfflineSyncQueue>().clear();
}

/// Descarta completamente o DI (dispose).
Future<void> disposeDependencies() async {
  await sl<OfflineSyncQueue>().dispose();
  await sl<OfflineManager>().dispose();
  await sl.reset(dispose: true);
}