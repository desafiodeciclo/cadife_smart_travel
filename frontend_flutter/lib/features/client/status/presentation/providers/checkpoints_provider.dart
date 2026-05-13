import 'package:cadife_smart_travel/core/network/dio_provider.dart';
import 'package:cadife_smart_travel/features/client/status/data/datasources/checkpoint_datasource.dart';
import 'package:cadife_smart_travel/features/client/status/domain/entities/checkpoint_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _checkpointDatasourceProvider = Provider<CheckpointDatasource>((ref) {
  return CheckpointDatasource(ref.watch(dioClientProvider));
});

/// Family provider: fetches checkpoints for a given leadId.
final checkpointsProvider = AsyncNotifierProvider.family<
    CheckpointsNotifier, List<CheckpointItem>, String>(
  CheckpointsNotifier.new,
);

class CheckpointsNotifier
    extends FamilyAsyncNotifier<List<CheckpointItem>, String> {
  @override
  Future<List<CheckpointItem>> build(String arg) async {
    final ds = ref.watch(_checkpointDatasourceProvider);
    return ds.getCheckpoints(arg);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final ds = ref.read(_checkpointDatasourceProvider);
    state = await AsyncValue.guard(() => ds.getCheckpoints(arg));
  }
}
