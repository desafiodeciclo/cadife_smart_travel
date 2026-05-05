import 'package:cadife_smart_travel/core/cache/isar_cache_manager.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

/// Provider que expõe a instância do Isar gerenciada pelo IsarCacheManager (GetIt).
final isarProvider = Provider<Isar?>((ref) {
  return sl<IsarCacheManager>().isar;
});
