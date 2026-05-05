import 'package:cadife_smart_travel/core/analytics/analytics_service.dart';
import 'package:cadife_smart_travel/core/cache/database_helper.dart';
import 'package:cadife_smart_travel/core/cache/isar_cache_manager.dart';
import 'package:cadife_smart_travel/core/config/env_config.dart';
import 'package:cadife_smart_travel/core/config/firebase_options_prod.dart';
import 'package:cadife_smart_travel/core/config/firebase_options_stg.dart';
import 'package:cadife_smart_travel/core/network/connectivity_service.dart';
import 'package:cadife_smart_travel/core/network/dio_client.dart';
import 'package:cadife_smart_travel/core/network/interceptors/auth_interceptor.dart';
import 'package:cadife_smart_travel/core/network/interceptors/error_interceptor.dart';
import 'package:cadife_smart_travel/core/network/network_info.dart';
import 'package:cadife_smart_travel/core/notifications/fcm_manager.dart';
import 'package:cadife_smart_travel/core/notifications/local_notification_manager.dart';
import 'package:cadife_smart_travel/core/offline/i_offline_event_repository.dart';
import 'package:cadife_smart_travel/core/offline/offline_event_repository_impl.dart';
import 'package:cadife_smart_travel/core/offline/offline_interceptor.dart';
import 'package:cadife_smart_travel/core/offline/offline_manager.dart';
import 'package:cadife_smart_travel/core/offline/offline_sync_queue.dart';
import 'package:cadife_smart_travel/core/offline/process_offline_queue_usecase.dart';
import 'package:cadife_smart_travel/core/security/secure_config.dart';
import 'package:cadife_smart_travel/features/agency/agenda/data/datasources/mock_agenda_repository.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/repositories/i_agenda_repository.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/datasources/leads_remote_mock_datasource.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/repositories/leads_repository_impl.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';
import 'package:cadife_smart_travel/features/agency/perfil/data/datasources/mock_consultor_repository.dart';
import 'package:cadife_smart_travel/features/agency/perfil/domain/repositories/i_consultor_repository.dart';
import 'package:cadife_smart_travel/features/agency/propostas/data/repositories/proposal_repository_impl.dart';
import 'package:cadife_smart_travel/features/agency/propostas/domain/repositories/i_proposals_repository.dart';
import 'package:cadife_smart_travel/features/agency/settings/data/datasources/mock_agency_settings_repository.dart';
import 'package:cadife_smart_travel/features/agency/settings/domain/repositories/i_agency_settings_repository.dart';
import 'package:cadife_smart_travel/features/auth/data/datasources/auth_remote_mock_datasource.dart';
import 'package:cadife_smart_travel/features/auth/data/datasources/i_auth_datasource.dart';
import 'package:cadife_smart_travel/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cadife_smart_travel/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:cadife_smart_travel/features/client/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:cadife_smart_travel/features/client/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:cadife_smart_travel/features/client/profile/data/datasources/mock_profile_repository.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/repositories/i_profile_repository.dart';
import 'package:cadife_smart_travel/features/client/status/data/datasources/status_datasource.dart';
import 'package:cadife_smart_travel/features/client/status/data/repositories/status_repository_impl.dart';
import 'package:cadife_smart_travel/features/client/status/domain/repositories/i_status_repository.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

/// Service Locator global — get_it com registro explícito e lifecycle controlado.
final sl = GetIt.instance;

/// Registra TODOS os serviços core e ports por módulo.
Future<void> setupServiceLocator({
  EnvConfig? config,
  List<String>? pinnedCertificates,
  List<String>? backupCertificates,
  VoidCallback? onTokenExpired,
}) async {
  // Registrar o EnvConfig no Service Locator para uso global
  final env = config ?? EnvConfig.dev;
  sl.registerSingleton<EnvConfig>(env);
  
  sl.registerSingleton<AnalyticsService>(AnalyticsService());
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

  // ── 2. Network Layer ─────────────────────────────────

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

  sl.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(
      secureConfig: sl<SecureConfig>(),
      refreshDio: sl<Dio>(instanceName: 'refreshDio'),
      onTokenExpired: onTokenExpired ?? () {},
    ),
  );

  sl.registerLazySingleton<Dio>(() {
    const isRelease = bool.fromEnvironment('dart.vm.product');
    if (isRelease) {
      if (pinnedCertificates == null || pinnedCertificates.isEmpty) {
        throw StateError(
          'Certificate pinning é obrigatório em builds de release.',
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

  _registerAuthModule();
  _registerLeadModule();
  _registerAgendaModule();
  _registerProposalModule();
  _registerProfileModule();
  _registerNotificationsModule();
  _registerSettingsModule();
  _registerStatusModule();
}

void _registerStatusModule() {
  sl.registerLazySingleton<IStatusDatasource>(StatusMockDatasource.new);
  sl.registerLazySingleton<IStatusRepository>(
    () => StatusRepositoryImpl(sl<IStatusDatasource>()),
  );
}

void _registerAuthModule() {
  sl.registerLazySingleton<IAuthDatasource>(
    AuthRemoteMockDatasource.new,
  );

  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(
      remoteDatasource: sl<IAuthDatasource>(),
      secureConfig: sl<SecureConfig>(),
    ),
  );
}

void _registerLeadModule() {
  sl.registerLazySingleton<ILeadsRepository>(
    () => LeadsRepositoryImpl(
      remoteDatasource: LeadsRemoteMockDatasource(),
    ),
  );
}

void _registerAgendaModule() {
  sl.registerLazySingleton<IAgendaRepository>(MockAgendaRepository.new);
}

void _registerProposalModule() {
  sl.registerLazySingleton<IProposalsRepository>(
    () => ProposalRepositoryImpl(
      dio: sl<Dio>(),
      offlineManager: sl<OfflineManager>(),
    ),
  );
}

void _registerProfileModule() {
  sl.registerLazySingleton<IProfileRepository>(MockProfileRepository.new);
  sl.registerLazySingleton<IConsultorRepository>(MockConsultorRepository.new);
}

void _registerNotificationsModule() {
  sl.registerLazySingleton<INotificationsRepository>(NotificationsRepositoryImpl.new);
}

void _registerSettingsModule() {
  sl.registerLazySingleton<IAgencySettingsRepository>(MockAgencySettingsRepository.new);
}

Future<void> initDependencies() async {
  final env = sl<EnvConfig>().environment;
  
  FirebaseOptions? options;
  if (env == AppEnvironment.staging) {
    options = StagingFirebaseOptions.currentPlatform;
  } else if (env == AppEnvironment.prod) {
    options = ProdFirebaseOptions.currentPlatform;
  }
  // No dev, se options for null, ele tenta carregar os arquivos nativos padrão

  await Firebase.initializeApp(options: options);
  await sl<OfflineManager>().initialize();
  await sl<IsarCacheManager>().initialize();
  await sl<OfflineSyncQueue>().initialize();
  
  await sl<AnalyticsService>().init();
  
  await LocalNotificationManager.init();
  await FCMManager.init();
  ConnectivityService.init();
}

Future<void> resetDependencies() async {
  await sl<OfflineManager>().clearUserData();
  await sl<SecureConfig>().clearTokens();
  await sl<OfflineManager>().clearCache();
  await sl<OfflineSyncQueue>().clear();
}

Future<void> disposeDependencies() async {
  await sl<OfflineSyncQueue>().dispose();
  await sl<OfflineManager>().dispose();
  await sl<IsarCacheManager>().close();
  await sl<DatabaseHelper>().close();
  await sl.reset(dispose: true);
}

