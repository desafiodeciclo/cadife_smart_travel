import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/lead_port.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para o repositório de leads no contexto do cliente.
/// Deve ser sobrescrito no ProviderScope com a implementação real.
final statusRepositoryProvider = Provider<LeadPort>((ref) {
  throw UnimplementedError('Override statusRepositoryProvider em ProviderScope');
});

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
    return repository.getLeadById(arg);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(statusRepositoryProvider);
      return repository.getLeadById(arg);
    });
  }
}
