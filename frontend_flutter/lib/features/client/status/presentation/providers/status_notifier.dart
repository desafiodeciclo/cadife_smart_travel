import 'package:cadife_smart_travel/features/agency/leads/data/providers/leads_data_providers.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Usamos o leadsRepositoryProvider da feature agency/leads

/// Provider que gerencia o status da viagem do cliente.
/// Recebe o [leadId] como argumento.
final statusProvider =
    AsyncNotifierProvider.family<StatusNotifier, Lead?, String>(
  StatusNotifier.new,
);

class StatusNotifier extends FamilyAsyncNotifier<Lead?, String> {
  @override
  Future<Lead?> build(String arg) async {
    final repository = ref.watch(leadsRepositoryProvider);
    final result = await repository.getLeadById(arg);
    return result.fold(
      (failure) => throw failure,
      (lead) => lead,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final repository = ref.read(leadsRepositoryProvider);
    final result = await repository.getLeadById(arg);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (lead) => AsyncData(lead),
    );
  }
}
