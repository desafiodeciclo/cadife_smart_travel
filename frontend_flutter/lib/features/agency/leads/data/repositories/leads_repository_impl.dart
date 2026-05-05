import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/datasources/i_leads_datasource.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';
import 'package:cadife_smart_travel/features/client/historico/domain/entities/interacao.dart';
import 'package:fpdart/fpdart.dart';

class LeadsRepositoryImpl implements ILeadsRepository {
  final ILeadsDatasource _remoteDatasource;

  LeadsRepositoryImpl({
    required ILeadsDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  @override
  Future<Either<Failure, List<Lead>>> getLeads({LeadStatus? status, LeadScore? score}) async {
    try {
      final leads = await _remoteDatasource.getLeads(status: status, score: score);
      return Right(leads);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Lead>> getLeadById(String id) async {
    try {
      final lead = await _remoteDatasource.getLeadById(id);
      return Right(lead);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Lead?>> getMyLead() async {
    try {
      final lead = await _remoteDatasource.getMyLead();
      return Right(lead);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Lead>> updateLeadStatus(String id, LeadStatus newStatus) async {
    try {
      final lead = await _remoteDatasource.updateLeadStatus(id, newStatus);
      return Right(lead);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Briefing>> getBriefing(String leadId) async {
    try {
      final briefing = await _remoteDatasource.getBriefing(leadId);
      return Right(briefing);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, List<Interacao>>> getInteractions(String leadId) async {
    try {
      final interactions = await _remoteDatasource.getInteractions(leadId);
      return Right(interactions);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, Lead>> createLead(CreateLeadRequest request) async {
    try {
      final lead = await _remoteDatasource.createLead(request);
      return Right(lead);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }
}
