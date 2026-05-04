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
import 'package:cadife_smart_travel/core/security/secure_config.dart';
import 'package:cadife_smart_travel/data/local/database_helper.dart';
import 'package:cadife_smart_travel/data/repositories/mock_agency_settings_repository.dart';
import 'package:cadife_smart_travel/features/agency/agenda/data/repositories/agenda_repository_impl.dart';
import 'package:cadife_smart_travel/features/agency/proposals/data/repositories/proposal_repository_impl.dart';
import 'package:cadife_smart_travel/features/client/profile/data/repositories/profile_repository_impl.dart';
import 'package:cadife_smart_travel/data/repositories/mock_agency_settings_repository.dart';
import 'package:cadife_smart_travel/data/repositories/mock_agenda_repository.dart';
import 'package:cadife_smart_travel/data/repositories/mock_consultor_repository.dart';
import 'package:cadife_smart_travel/data/repositories/mock_profile_repository.dart';
import 'package:cadife_smart_travel/data/repositories/offline_event_repository_impl.dart';
import 'package:cadife_smart_travel/domain/repositories/i_offline_event_repository.dart';
import 'package:cadife_smart_travel/domain/usecases/process_offline_queue_usecase.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/repositories/i_agenda_repository.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/datasources/leads_remote_mock_datasource.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/repositories/leads_repository_impl.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';
import 'package:cadife_smart_travel/features/agency/profile/domain/repositories/i_consultor_repository.dart';
import 'package:cadife_smart_travel/features/agency/settings/domain/repositories/i_agency_settings_repository.dart';
import 'package:cadife_smart_travel/features/agency/proposals/domain/repositories/i_proposals_repository.dart';
import 'package:cadife_smart_travel/features/auth/data/datasources/auth_remote_mock_datasource.dart';
import 'package:cadife_smart_travel/features/auth/data/datasources/i_auth_datasource.dart';
import 'package:cadife_smart_travel/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cadife_smart_travel/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:cadife_smart_travel/features/client/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:cadife_smart_travel/features/client/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/repositories/i_profile_repository.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

/// Service Locator global — get_it com registro explícito e lifecycle controlado.
final sl = GetIt.instance;

/// Registra TODOS os serviços core e ports por módulo.
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
  await Firebase.initializeApp();
  await sl<OfflineManager>().initialize();
  await sl<IsarCacheManager>().initialize();
  await sl<OfflineSyncQueue>().initialize();
  
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

