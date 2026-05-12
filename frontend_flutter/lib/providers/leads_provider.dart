import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/core/offline/offline_manager.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/datasources/i_leads_datasource.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/datasources/leads_remote_api_datasource.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/datasources/leads_remote_mock_datasource.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/repositories/leads_repository_impl.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Este Ã© o provider central que controla se usamos Mock ou API real
final leadsDatasourceProvider = Provider<ILeadsDatasource>((ref) {
  // Mudamos para FALSE aqui para que o teste use o BACKEND REAL
  const useMock = false; 
  
  if (useMock) {
    return LeadsRemoteMockDatasource();
  } else {
    return LeadsRemoteApiDatasource(
      dio: sl<Dio>(),
      offlineManager: sl<OfflineManager>(),
    );
  }
});

final leadsRepositoryProvider = Provider<ILeadsRepository>((ref) {
  final datasource = ref.watch(leadsDatasourceProvider);
  return LeadsRepositoryImpl(remoteDatasource: datasource);
});
