import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/datasources/i_leads_datasource.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/models/conversation_summary_api_model.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/models/lead_api_model.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/conversation_summary.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';
import 'package:cadife_smart_travel/features/client/historico/domain/entities/interacao.dart';
import 'package:fpdart/fpdart.dart';

// LeadsRemoteMockDatasource removido daqui pois agora possui arquivo próprio.

/// Adapts [ILeadsDatasource] to [ILeadsRepository].
class LeadsRepositoryImpl implements ILeadsRepository {
  final ILeadsDatasource remoteDatasource;

  LeadsRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, List<Lead>>> getLeads({LeadStatus? status, LeadScore? score}) async {
    try { return Right(await remoteDatasource.getLeads(status: status, score: score)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Lead>> getLeadById(String id) async {
    try { return Right(await remoteDatasource.getLeadById(id)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Lead?>> getMyLead() async {
    try { return Right(await remoteDatasource.getMyLead()); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Briefing>> getBriefing(String leadId) async {
    try { return Right(await remoteDatasource.getBriefing(leadId)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, List<Interacao>>> getInteractions(String leadId) async {
    try { return Right(await remoteDatasource.getInteractions(leadId)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Lead>> createLead(CreateLeadRequest request) async {
    try { return Right(await remoteDatasource.createLead(request)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Lead>> createManualLead(ManualLeadCreate request) async {
    try { return Right(await remoteDatasource.createManualLead(request)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Unit>> toggleAya(String leadId, {required bool ativo, String? motivo}) async {
    try { await remoteDatasource.toggleAya(leadId, ativo: ativo, motivo: motivo); return const Right(unit); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Lead>> updateLeadStatus(String id, LeadStatus newStatus) async {
    try { return Right(await remoteDatasource.updateLeadStatus(id, newStatus)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Lead>> updateLead({
    required String id, String? name, String? phone, String? email,
    LeadStatus? status, LeadScore? score,
  }) async {
    try {
      return Right(await remoteDatasource.updateLead(
        id: id, name: name, phone: phone, email: email, status: status, score: score,
      ));
    } catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, ConversationSummary?>> getConversationSummary(String leadId) async {
    try {
      final summary = await remoteDatasource.getConversationSummary(leadId);
      return Right(summary?.toDomain());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
