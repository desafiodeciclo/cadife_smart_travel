import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/datasources/i_leads_datasource.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/conversation_summary.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';
import 'package:cadife_smart_travel/shared/domain/entities/interacao.dart';
import 'package:fpdart/fpdart.dart';

/// Adapts [ILeadsDatasource] to [ILeadsRepository].
class LeadsRepositoryImpl implements ILeadsRepository {
  final ILeadsDatasource _datasource;

  LeadsRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<Lead>>> getLeads({LeadStatus? status, LeadScore? score}) async {
    try {
      final result = await _datasource.getLeads(status: status, score: score);
      return Right(result);
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lead>> getLeadById(String id) async {
    try {
      final result = await _datasource.getLeadById(id);
      return Right(result);
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lead?>> getMyLead() async {
    try {
      final result = await _datasource.getMyLead();
      return Right(result);
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Briefing>> getBriefing(String leadId) async {
    try {
      final result = await _datasource.getBriefing(leadId);
      return Right(result);
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Interacao>>> getInteractions(String leadId) async {
    try {
      final result = await _datasource.getInteractions(leadId);
      return Right(result);
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ConversationSummary?>> getConversationSummary(String leadId) async {
    try {
      final result = await _datasource.getConversationSummary(leadId);
      return Right(result?.toDomain());
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lead>> createLead(CreateLeadRequest request) async {
    try {
      final result = await _datasource.createLead(request);
      return Right(result);
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lead>> createManualLead(ManualLeadCreate request) async {
    try {
      final result = await _datasource.createManualLead(request);
      return Right(result);
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleAya(String leadId, {required bool ativo, String? motivo}) async {
    try {
      await _datasource.toggleAya(leadId, ativo: ativo, motivo: motivo);
      return const Right(unit);
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lead>> updateLeadStatus(String id, LeadStatus newStatus) async {
    try {
      final result = await _datasource.updateLeadStatus(id, newStatus);
      return Right(result);
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lead>> updateLead({
    required String id,
    String? name,
    String? phone,
    String? email,
    LeadStatus? status,
    LeadScore? score,
  }) async {
    try {
      final result = await _datasource.updateLead(
        id: id,
        name: name,
        phone: phone,
        email: email,
        status: status,
        score: score,
      );
      return Right(result);
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lead>> reassignLead(String id, String consultorNome) async {
    try {
      final result = await _datasource.reassignLead(id, consultorNome);
      return Right(result);
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
