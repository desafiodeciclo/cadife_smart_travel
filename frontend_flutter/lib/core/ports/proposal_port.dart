import 'package:cadife_smart_travel/shared/models/models.dart';
import 'package:cadife_smart_travel/shared/models/proposal_model.dart';

abstract class ProposalPort {
  Future<List<ProposalModel>> getProposals({
    String? leadId,
    ProposalStatus? status,
  });
  Future<ProposalModel> getProposalById(String id);
  Future<ProposalModel> createProposal(CreateProposalRequest request);
  Future<ProposalModel> updateProposal(
    String id,
    UpdateProposalRequest request,
  );
  Future<void> deleteProposal(String id);
}
