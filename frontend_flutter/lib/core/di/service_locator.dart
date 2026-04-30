import 'package:cadife_smart_travel/core/cache/isar_cache_manager.dart';
import 'package:cadife_smart_travel/core/network/connectivity_service.dart';
import 'package:cadife_smart_travel/core/network/dio_client.dart';
import 'package:cadife_smart_travel/core/network/interceptors/auth_interceptor.dart';
import 'package:cadife_smart_travel/core/network/interceptors/error_interceptor.dart';
import 'package:cadife_smart_travel/core/network/network_info.dart';
import 'package:cadife_smart_travel/core/notifications/fcm_manager.dart';
import 'package:cadife_smart_travel/core/notifications/local_notification_manager.dart';
import 'package:cadife_smart_travel/core/offline/offline_interceptor.dart';
import 'package:cadife_smart_travel/core/offline/offline_manager.dart';
import 'package:cadife_smart_travel/core/offline/offline_sync_queue.dart';
import 'package:cadife_smart_travel/core/ports/agenda_port.dart';
import 'package:cadife_smart_travel/core/ports/auth_port.dart';
import 'package:cadife_smart_travel/core/ports/lead_port.dart';
import 'package:cadife_smart_travel/core/ports/profile_port.dart';
import 'package:cadife_smart_travel/core/ports/proposal_port.dart';
import 'package:cadife_smart_travel/core/security/secure_config.dart';
import 'package:cadife_smart_travel/data/local/database_helper.dart';
import 'package:cadife_smart_travel/data/repositories/agenda_repository_impl.dart';
import 'package:cadife_smart_travel/data/repositories/mock_agenda_repository.dart';
import 'package:cadife_smart_travel/data/repositories/mock_auth_repository.dart';
import 'package:cadife_smart_travel/data/repositories/mock_lead_repository.dart';
import 'package:cadife_smart_travel/data/repositories/mock_profile_repository.dart';
import 'package:cadife_smart_travel/data/repositories/offline_event_repository_impl.dart';
import 'package:cadife_smart_travel/data/repositories/proposal_repository_impl.dart';
import 'package:cadife_smart_travel/domain/repositories/i_offline_event_repository.dart';
import 'package:cadife_smart_travel/domain/usecases/process_offline_queue_usecase.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

/// Service Locator global — get_it com registro explícito e lifecycle controlado.
///
/// REGRA: Singletons APENAS para serviços performance-critical (network, DB, security).
/// Repositories são lazySingletons pois encapsulam Dio (singleton) — sem state próprio.
final sl = GetIt.instance;

/// Registra TODOS os serviços core e ports por módulo.
///
/// [onTokenExpired] — callback acionado quando o refresh de token falha.
/// Tipicamente chama `authProvider.notifier.logout()` para disparar o redirect do GoRouter.
/// Chamado uma vez no `main()` antes de `runApp()`.
Future<void> setupServiceLocator({
  List<String>? pinnedCertificates,
  List<String>? backupCertificates,
  VoidCallback? onTokenExpired,
}) async {
  // ── 1. Infra Layer (singletons — performance-critical) ──

  sl.registerLazySingleton<NetworkInfo>(NetworkInfo.new);
  sl.registerLazySingleton<SecureConfig>(SecureConfig.new);
  sl.registerLazySingleton<OfflineManager>(
    () => OfflineManager(networkInfo: sl<NetworkInfo>()),
  );
  sl.registerLazySingleton<OfflineSyncQueue>(
    () => OfflineSyncQueue(networkInfo: sl<NetworkInfo>()),
  );
  sl.registerLazySingleton<IsarCacheManager>(IsarCacheManager.new);
  
  sl.registerLazySingleton<DatabaseHelper>(DatabaseHelper.new);
  sl.registerLazySingleton<IOfflineEventRepository>(
    () => OfflineEventRepositoryImpl(sl<DatabaseHelper>()),
  );
  sl.registerLazySingleton<ProcessOfflineQueueUseCase>(
    () => ProcessOfflineQueueUseCase(sl<IOfflineEventRepository>()),
  );

  // ── 2. Network Layer ──────────────────────────────────

  // Lightweight Dio used only by AuthInterceptor (no auth/error interceptors).
  // Named instance to avoid collision with the main Dio registration.
  sl.registerLazySingleton<Dio>(
    () => DioClientFactory.createForRefresh(
      pinnedSha256: pinnedCertificates ?? [],
      backupPinnedSha256: backupCertificates,
    ),
    instanceName: 'refreshDio',
  );

  sl.registerLazySingleton<ErrorInterceptor>(ErrorInterceptor.new);

  sl.registerLazySingleton<OfflineInterceptor>(
    () => OfflineInterceptor(sl<OfflineManager>()),
  );

  // AuthInterceptor must be a singleton — its Completer<bool> field deduplicates
  // concurrent 401s across the lifetime of the app.
  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(
      secureConfig: sl<SecureConfig>(),
      refreshDio: sl<Dio>(instanceName: 'refreshDio'),
      onTokenExpired: onTokenExpired ?? () {},
    ),
  );

  // Main authenticated Dio (unnamed — default instance used by all repositories).
  sl.registerLazySingleton<Dio>(() {
    const isRelease = bool.fromEnvironment('dart.vm.product');
    if (isRelease) {
      // Fail-closed: em release SEMPRE exige pinning configurado.
      if (pinnedCertificates == null || pinnedCertificates.isEmpty) {
        throw StateError(
          'Certificate pinning é obrigatório em builds de release. '
          'Forneça pinnedCertificates no setupServiceLocator().',
        );
      }
      return DioClientFactory.createPinned(
        pinnedSha256: pinnedCertificates,
        backupPinnedSha256: backupCertificates,
        authInterceptor: sl<AuthInterceptor>(),
        errorInterceptor: sl<ErrorInterceptor>(),
        offlineInterceptor: sl<OfflineInterceptor>(),
      );
    }
    // Debug/dev: permite unpinned para facilitar desenvolvimento local.
    if (pinnedCertificates == null || pinnedCertificates.isEmpty) {
      return DioClientFactory.createUnpinned();
    }
    return DioClientFactory.createPinned(
      pinnedSha256: pinnedCertificates,
      backupPinnedSha256: backupCertificates,
      authInterceptor: sl<AuthInterceptor>(),
      errorInterceptor: sl<ErrorInterceptor>(),
      offlineInterceptor: sl<OfflineInterceptor>(),
    );
  });

  // ── 3. Ports (interfaces) → Implementations ──────────
  // Features importam apenas a PORT (interface), nunca a impl.

  _registerAuthModule();
  _registerLeadModule();
  _registerAgendaModule();
  _registerProposalModule();
  _registerProfileModule();
}

void _registerAuthModule() {
  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  // MOCK LOGIN ATIVADO — COMENTE A LINHA ABAIXO E DESCOMENTE A SEGUINTE PARA PROD
  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  sl.registerLazySingleton<AuthPort>(() => MockAuthRepository(secureConfig: sl<SecureConfig>()));
  // sl.registerLazySingleton<AuthPort>(
  //   () => AuthRepositoryImpl(dio: sl<Dio>(), secureConfig: sl<SecureConfig>()),
  // );
}

void _registerLeadModule() {
  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  // MOCK LEAD ATIVADO — COMENTE A LINHA ABAIXO E DESCOMENTE A SEGUINTE PARA PROD
  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  sl.registerLazySingleton<LeadPort>(MockLeadRepository.new);
  // sl.registerLazySingleton<LeadPort>(
  //   () => LeadRepositoryImpl(
  //     dio: sl<Dio>(),
  //     offlineManager: sl<OfflineManager>(),
  //   ),
  // );
}

void _registerAgendaModule() {
  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  // MOCK AGENDA ATIVADO — COMENTE A LINHA ABAIXO E DESCOMENTE A SEGUINTE PARA PROD
  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  sl.registerLazySingleton<AgendaPort>(MockAgendaRepository.new);
  // sl.registerLazySingleton<AgendaPort>(
  //   () => AgendaRepositoryImpl(
  //     dio: sl<Dio>(),
  //     offlineManager: sl<OfflineManager>(),
  //   ),
  // );
}

void _registerProposalModule() {
  sl.registerLazySingleton<ProposalPort>(
    () => ProposalRepositoryImpl(
      dio: sl<Dio>(),
      offlineManager: sl<OfflineManager>(),
    ),
  );
}

void _registerProfileModule() {
  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  // MOCK PROFILE ATIVADO — COMENTE A LINHA ABAIXO E DESCOMENTE A SEGUINTE PARA PROD
  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  sl.registerLazySingleton<ProfilePort>(MockProfileRepository.new);
  // sl.registerLazySingleton<ProfilePort>(
  //   () => ProfileRepositoryImpl(
  //     dio: sl<Dio>(),
  //     offlineManager: sl<OfflineManager>(),
  //   ),
  // );
}

/// Inicializa infra offline (Hive + Isar + SyncQueue).
Future<void> initDependencies() async {
  await Firebase.initializeApp();
  await sl<OfflineManager>().initialize();
  await sl<IsarCacheManager>().initialize();
  await sl<OfflineSyncQueue>().initialize();
  
  await LocalNotificationManager.init();
  await FCMManager.init();
  ConnectivityService.init();
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
  await sl<IsarCacheManager>().close();
  await sl<DatabaseHelper>().close();
  await sl.reset(dispose: true);
}
