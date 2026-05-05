import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/features/client/status/data/datasources/status_datasource.dart';
import 'package:cadife_smart_travel/features/client/status/data/repositories/status_repository_impl.dart';
import 'package:cadife_smart_travel/features/client/status/domain/repositories/i_status_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final statusDatasourceProvider = Provider<IStatusDatasource>((ref) {
  return StatusMockDatasource();
});

final statusRepositoryProvider = Provider<IStatusRepository>((ref) {
  return StatusRepositoryImpl(ref.watch(statusDatasourceProvider));
});

/// Provider para o Service Locator (caso precise fora do Riverpod)
final slStatusRepositoryProvider = Provider<IStatusRepository>((ref) {
  return sl<IStatusRepository>();
});
