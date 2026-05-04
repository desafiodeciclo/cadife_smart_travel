import 'package:cadife_smart_travel/features/agency/leads/data/providers/leads_data_providers.dart';
import 'package:cadife_smart_travel/features/client/historico/domain/entities/interacao.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Usamos o leadsRepositoryProvider da feature agency/leads

/// Provider que gerencia a lista de interações do cliente.
/// Resolve automaticamente o lead ativo do usuário logado.
final historicoProvider = AsyncNotifierProvider<HistoricoNotifier, List<Interacao>>(
  HistoricoNotifier.new,
);

class HistoricoNotifier extends AsyncNotifier<List<Interacao>> {
  @override
  Future<List<Interacao>> build() async {
    final repository = ref.watch(leadsRepositoryProvider);
    final lead = await repository.getMyLead();
    if (lead == null) return [];
    return repository.getInteractions(lead.id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(leadsRepositoryProvider);
      final lead = await repository.getMyLead();
      if (lead == null) return <Interacao>[];
      return repository.getInteractions(lead.id);
    });
  }
}
