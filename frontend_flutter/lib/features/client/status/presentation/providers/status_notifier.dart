import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/client/status/data/providers/status_data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que gerencia o status da viagem do cliente.
/// Recebe o [leadId] como argumento.
final statusProvider =
    AsyncNotifierProvider.family<StatusNotifier, Lead?, String>(
  StatusNotifier.new,
);

class StatusNotifier extends FamilyAsyncNotifier<Lead?, String> {
  @override
  Future<Lead?> build(String arg) async {
    final repository = ref.watch(statusRepositoryProvider);
    final result = await repository.getStatusById(arg);
    return result.fold(
      (failure) => throw failure,
      (lead) => lead,
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
