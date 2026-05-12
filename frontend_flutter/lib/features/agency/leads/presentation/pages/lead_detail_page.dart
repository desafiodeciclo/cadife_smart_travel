import 'dart:async';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/leads_usecases_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeadDetailNotifier extends FamilyAsyncNotifier<Lead?, String> {
  @override
  FutureOr<Lead?> build(String arg) async {
    final getLead = ref.watch(getLeadByIdUseCaseProvider);
    final result = await getLead(arg);

    return result.fold(
      (failure) => throw failure,
      (lead) => lead,
    );
  }

  /// Gerencia o estado da IA Aya (Ação do Switch na AppBar)
  Future<void> toggleAya({required bool ativo, String? motivo}) async {
    final leadId = arg;
    final toggleUseCase = ref.read(toggleAyaUseCaseProvider);

    // Otimismo na UI: Atualiza o estado local antes da resposta do servidor
    final previousState = state.value;
    if (previousState != null) {
      state = AsyncData(previousState.copyWith(ayaAtivo: ativo));
    }

    final result = await toggleUseCase(leadId, ativo: ativo, motivo: motivo);

    result.fold(
      (failure) {
        // Rollback em caso de erro
        state = AsyncData(previousState);
      },
      (_) => ref.invalidateSelf(), // Recarrega para garantir sincronia
    );
  }

  /// Atualiza o status do lead (Ação de Aprovar/Agendar)
  Future<void> updateStatus(LeadStatus newStatus) async {
    final updateUseCase = ref.read(updateLeadStatusUseCaseProvider);
    
    final result = await updateUseCase(arg, newStatus);
    
    result.fold(
      (failure) => null, // O Toaster na UI tratará o feedback
      (updatedLead) => state = AsyncData(updatedLead),
    );
  }
}