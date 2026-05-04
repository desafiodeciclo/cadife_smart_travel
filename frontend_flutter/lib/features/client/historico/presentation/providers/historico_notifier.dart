import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/lead_port.dart';
import 'package:cadife_smart_travel/features/client/historico/domain/entities/interacao.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para o repositório de interações/histórico no contexto do cliente.
final historicoRepositoryProvider = Provider<LeadPort>((ref) {
  throw UnimplementedError('Override historicoRepositoryProvider em ProviderScope');
});

/// Provider que gerencia a lista de interações do cliente.
/// Resolve automaticamente o lead ativo do usuário logado.
final historicoProvider = AsyncNotifierProvider<HistoricoNotifier, List<Interacao>>(
  HistoricoNotifier.new,
);

class HistoricoNotifier extends AsyncNotifier<List<Interacao>> {
  @override
  Future<List<Interacao>> build() async {
    final repository = ref.watch(historicoRepositoryProvider);
    final lead = await repository.getMyLead();
    if (lead == null) return [];
    return repository.getInteractions(lead.id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(historicoRepositoryProvider);
      final lead = await repository.getMyLead();
      if (lead == null) return <Interacao>[];
      return repository.getInteractions(lead.id);
    });
  }
}
