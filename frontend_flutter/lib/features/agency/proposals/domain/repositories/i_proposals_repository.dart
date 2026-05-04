import 'package:fpdart/fpdart.dart';
import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/proposals/domain/entities/proposta.dart';

abstract class IProposalsRepository {
  Future<Either<Failure, List<Proposta>>> getProposals({
    String? leadId,
    ProposalStatus? status,
  });
  Future<Either<Failure, Proposta>> getProposalById(String id);
  Future<Either<Failure, Proposta>> createProposal(CreateProposalRequest request);
  Future<Either<Failure, Proposta>> updateProposal(
    String id,
    UpdateProposalRequest request,
  );
  Future<Either<Failure, void>> deleteProposal(String id);
}
