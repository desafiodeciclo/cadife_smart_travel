import 'package:cadife_smart_travel/features/agency/proposals/domain/entities/proposta.dart';

abstract class ProposalPort {
  Future<List<Proposta>> getProposals({
    String? leadId,
    ProposalStatus? status,
  });
  Future<Proposta> getProposalById(String id);
  Future<Proposta> createProposal(CreateProposalRequest request);
  Future<Proposta> updateProposal(
    String id,
    UpdateProposalRequest request,
  );
  Future<void> deleteProposal(String id);
}




