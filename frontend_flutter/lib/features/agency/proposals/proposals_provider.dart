import 'package:cadife_smart_travel/core/ports/proposal_port.dart';
import 'package:cadife_smart_travel/shared/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final proposalPortProvider = Provider<ProposalPort>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

final proposalsProvider = AsyncNotifierProvider<ProposalsNotifier, List<ProposalModel>>(
  ProposalsNotifier.new,
);

class ProposalsNotifier extends AsyncNotifier<List<ProposalModel>> {
  @override
  Future<List<ProposalModel>> build() async {
    final proposalPort = ref.watch(proposalPortProvider);
    return proposalPort.getProposals();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final proposalPort = ref.read(proposalPortProvider);
      return proposalPort.getProposals();
    });
  }

  Future<void> filterByLeadId(String leadId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final proposalPort = ref.read(proposalPortProvider);
      return proposalPort.getProposals(leadId: leadId);
    });
  }

  Future<void> createProposal(CreateProposalRequest request) async {
    final proposalPort = ref.read(proposalPortProvider);
    await proposalPort.createProposal(request);
    await refresh();
  }
}