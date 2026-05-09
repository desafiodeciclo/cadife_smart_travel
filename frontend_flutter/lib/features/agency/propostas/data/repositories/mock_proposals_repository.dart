import 'package:cadife_smart_travel/features/agency/propostas/domain/entities/proposta.dart';
import 'package:cadife_smart_travel/features/agency/propostas/domain/repositories/i_proposals_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:cadife_smart_travel/core/error/failures.dart';

class MockProposalsRepository implements IProposalsRepository {
  @override
  Future<Either<Failure, List<Proposta>>> getProposals({
    String? leadId,
    ProposalStatus? status,
  }) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, Proposta>> getProposalById(String id) async {
    return Left(ServerFailure('Not implemented in mock'));
  }

  @override
  Future<Either<Failure, Proposta>> createProposal(CreateProposalRequest request) async {
    return Left(ServerFailure('Not implemented in mock'));
  }

  @override
  Future<Either<Failure, Proposta>> updateProposal(
    String id,
    UpdateProposalRequest request,
  ) async {
    return Left(ServerFailure('Not implemented in mock'));
  }

  @override
  Future<Either<Failure, void>> deleteProposal(String id) async {
    return const Right(null);
  }
}
