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
    return repository.getLeadById(arg);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(leadsRepositoryProvider);
      return repository.getLeadById(arg);
    });
  }
}
