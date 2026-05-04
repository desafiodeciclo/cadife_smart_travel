import 'package:cadife_smart_travel/features/agency/propostas/domain/entities/proposta.dart';
import 'package:cadife_smart_travel/features/agency/propostas/domain/repositories/i_proposals_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final iProposalsRepositoryProvider = Provider<IProposalsRepository>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

final proposalsProvider =
    AsyncNotifierProvider<ProposalsNotifier, List<Proposta>>(
      ProposalsNotifier.new,
    );

class ProposalsNotifier extends AsyncNotifier<List<Proposta>> {
  @override
  Future<List<Proposta>> build() async {
    final repo = ref.watch(iProposalsRepositoryProvider);
    final result = await repo.getProposals();
    return result.fold<List<Proposta>>(
      (failure) => throw failure,
      (proposals) => proposals,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final repo = ref.read(iProposalsRepositoryProvider);
    final result = await repo.getProposals();
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      AsyncData.new,
    );
  }

  Future<void> filterByLeadId(String leadId) async {
    state = const AsyncLoading();
    final repo = ref.read(iProposalsRepositoryProvider);
    final result = await repo.getProposals(leadId: leadId);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      AsyncData.new,
    );
  }

  Future<void> createProposal(CreateProposalRequest request) async {
    final repo = ref.read(iProposalsRepositoryProvider);
    final result = await repo.createProposal(request);
    
    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (_) => refresh(),
    );
  }
}





