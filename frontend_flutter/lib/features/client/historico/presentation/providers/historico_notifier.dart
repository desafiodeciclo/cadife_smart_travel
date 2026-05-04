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
    final leadResult = await repository.getMyLead();
    
    return await leadResult.fold(
      (failure) => throw failure,
      (lead) async {
        if (lead == null) return [];
        final interactionsResult = await repository.getInteractions(lead.id);
        return interactionsResult.fold(
          (f) => throw f,
          (list) => list,
        );
      },
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final repository = ref.read(leadsRepositoryProvider);
    final leadResult = await repository.getMyLead();
    
    state = await leadResult.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (lead) async {
        if (lead == null) return const AsyncData(<Interacao>[]);
        final interactionsResult = await repository.getInteractions(lead.id);
        return interactionsResult.fold(
          (f) => AsyncError(f, StackTrace.current),
          AsyncData.new,
        );
      },
    );
  }
}
