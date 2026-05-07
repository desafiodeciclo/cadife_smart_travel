import 'package:cadife_smart_travel/features/client/status/data/providers/status_data_providers.dart';
import 'package:cadife_smart_travel/features/client/status/domain/entities/client_travel_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
/// Provider que gerencia o status da viagem do cliente.
/// Recebe o ID do lead como argumento.
final statusProvider =
    AsyncNotifierProvider.family<StatusNotifier, ClientTravelStatus?, String>(
  StatusNotifier.new,
);

class StatusNotifier extends FamilyAsyncNotifier<ClientTravelStatus?, String> {
  @override
  Future<ClientTravelStatus?> build(String arg) async {
    final repository = ref.watch(statusRepositoryProvider);
    final result = await repository.getStatusById(arg);
    return result.fold(
      (failure) => throw failure,
      (status) => status,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final repository = ref.read(statusRepositoryProvider);
    final result = await repository.getStatusById(arg);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      AsyncData.new,
    );
  }
}
