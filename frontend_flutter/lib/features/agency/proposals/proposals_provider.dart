import 'package:cadife_smart_travel/features/agency/proposals/domain/entities/proposta.dart';
import 'package:cadife_smart_travel/features/agency/proposals/domain/repositories/i_proposals_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final IProposalsRepositoryProvider = Provider<IProposalsRepository>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

final proposalsProvider =
    AsyncNotifierProvider<ProposalsNotifier, List<Proposta>>(
      ProposalsNotifier.new,
    );

class ProposalsNotifier extends AsyncNotifier<List<Proposta>> {
  @override
  Future<List<Proposta>> build() async {
    final repo = ref.watch(IProposalsRepositoryProvider);
    final result = await repo.getProposals();
    return result.fold(
      (failure) => throw failure,
      (proposals) => proposals,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final repo = ref.read(IProposalsRepositoryProvider);
    final result = await repo.getProposals();
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (proposals) => AsyncData(proposals),
    );
  }

  Future<void> filterByLeadId(String leadId) async {
    state = const AsyncLoading();
    final repo = ref.read(IProposalsRepositoryProvider);
    final result = await repo.getProposals(leadId: leadId);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (proposals) => AsyncData(proposals),
    );
  }

  Future<void> createProposal(CreateProposalRequest request) async {
    final repo = ref.read(IProposalsRepositoryProvider);
    final result = await repo.createProposal(request);
    
    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (_) => refresh(),
    );
  }
}





