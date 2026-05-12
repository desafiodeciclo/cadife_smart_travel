import 'package:cadife_smart_travel/features/agency/propostas/domain/entities/proposta.dart';
import 'package:cadife_smart_travel/features/agency/propostas/presentation/providers/proposals_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AutoSaveStatus { idle, saving, saved, error }

class ProposalFormSaveState {
  const ProposalFormSaveState({
    this.proposalId,
    this.autoSaveStatus = AutoSaveStatus.idle,
    this.isSending = false,
    this.proposalStatus = ProposalStatus.rascunho,
    this.errorMessage,
  });

  final String? proposalId;
  final AutoSaveStatus autoSaveStatus;
  final bool isSending;
  final ProposalStatus proposalStatus;
  final String? errorMessage;

  bool get isEnviada => proposalStatus == ProposalStatus.enviada;

  ProposalFormSaveState copyWith({
    String? proposalId,
    AutoSaveStatus? autoSaveStatus,
    bool? isSending,
    ProposalStatus? proposalStatus,
    String? errorMessage,
    bool clearError = false,
  }) =>
      ProposalFormSaveState(
        proposalId: proposalId ?? this.proposalId,
        autoSaveStatus: autoSaveStatus ?? this.autoSaveStatus,
        isSending: isSending ?? this.isSending,
        proposalStatus: proposalStatus ?? this.proposalStatus,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

// Keyed by leadId — one form state per lead
final proposalFormSaveProvider = NotifierProvider.family<
    ProposalFormSaveNotifier, ProposalFormSaveState, String>(
  ProposalFormSaveNotifier.new,
);

class ProposalFormSaveNotifier
    extends FamilyNotifier<ProposalFormSaveState, String> {
  @override
  ProposalFormSaveState build(String arg) => const ProposalFormSaveState();

  Future<bool> save({
    required String titulo,
    required List<String> destinos,
    required DateTime? dataSaida,
    required DateTime? dataRetorno,
    required int numAdultos,
    required int numCriancas,
    required List<ServicoIncluso> servicosInclusos,
    required double valorTotal,
    required String condicoesPagamento,
    required DateTime? validadeProposta,
    required String observacoesGerais,
    required String htmlContent,
    AssinaturaDigital? assinatura,
    String? consultorId,
  }) async {
    state = state.copyWith(autoSaveStatus: AutoSaveStatus.saving, clearError: true);

    try {
      final repo = ref.read(iProposalsRepositoryProvider);

      if (state.proposalId == null) {
        final request = CreateProposalRequest(
          leadId: arg,
          consultorId: consultorId ?? '',
          titulo: titulo,
          destinos: destinos.isNotEmpty ? destinos : null,
          dataIda: dataSaida,
          dataVolta: dataRetorno,
          numAdultos: numAdultos,
          numCriancas: numCriancas,
          servicosInclusos: servicosInclusos.isNotEmpty ? servicosInclusos : null,
          totalValue: valorTotal,
          condicoesPagamento: condicoesPagamento.isNotEmpty ? condicoesPagamento : null,
          validadeProposta: validadeProposta,
          observacoesGerais: observacoesGerais.isNotEmpty ? observacoesGerais : null,
          assinatura: assinatura,
          htmlContent: htmlContent,
        );
        final result = await repo.createProposal(request);
        return result.fold(
          (failure) {
            state = state.copyWith(
              autoSaveStatus: AutoSaveStatus.error,
              errorMessage: failure.message,
            );
            return false;
          },
          (proposal) {
            state = state.copyWith(
              proposalId: proposal.id,
              autoSaveStatus: AutoSaveStatus.saved,
              clearError: true,
            );
            return true;
          },
        );
      } else {
        final request = UpdateProposalRequest(
          titulo: titulo,
          servicosInclusos: servicosInclusos.isNotEmpty ? servicosInclusos : null,
          totalValue: valorTotal,
          condicoesPagamento: condicoesPagamento.isNotEmpty ? condicoesPagamento : null,
          observacoesGerais: observacoesGerais.isNotEmpty ? observacoesGerais : null,
          assinatura: assinatura,
          htmlContent: htmlContent,
        );
        final result = await repo.updateProposal(state.proposalId!, request);
        return result.fold(
          (failure) {
            state = state.copyWith(
              autoSaveStatus: AutoSaveStatus.error,
              errorMessage: failure.message,
            );
            return false;
          },
          (_) {
            state = state.copyWith(
              autoSaveStatus: AutoSaveStatus.saved,
              clearError: true,
            );
            return true;
          },
        );
      }
    } on Exception catch (e) {
      state = state.copyWith(
        autoSaveStatus: AutoSaveStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> sendProposal() async {
    if (state.proposalId == null) return false;

    state = state.copyWith(isSending: true, clearError: true);
    try {
      final repo = ref.read(iProposalsRepositoryProvider);
      final result = await repo.sendProposal(state.proposalId!);
      return result.fold(
        (failure) {
          state = state.copyWith(
            isSending: false,
            errorMessage: failure.message,
          );
          return false;
        },
        (_) {
          state = state.copyWith(
            isSending: false,
            proposalStatus: ProposalStatus.enviada,
          );
          return true;
        },
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isSending: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void resetStatus() {
    state = state.copyWith(autoSaveStatus: AutoSaveStatus.idle, clearError: true);
  }
}
