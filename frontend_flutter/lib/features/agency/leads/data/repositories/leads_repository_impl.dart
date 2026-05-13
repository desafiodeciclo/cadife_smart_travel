import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/datasources/i_leads_datasource.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/conversation_summary.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';
import 'package:cadife_smart_travel/shared/domain/entities/interacao.dart';
import 'package:fpdart/fpdart.dart';

class LeadsRepositoryImpl implements ILeadsRepository {
  final ILeadsDatasource remoteDatasource;

  LeadsRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, List<Lead>>> getLeads({LeadStatus? status, LeadScore? score}) async {
    try {
      final models = await remoteDatasource.getLeads(status: status, score: score);
      return Right(models);
    } catch (e) {
      return const Left(ServerFailure('Erro ao carregar leads.'));
    }
  }

  @override
  Future<Either<Failure, Lead>> getLeadById(String id) async {
    try {
      final model = await remoteDatasource.getLeadById(id);
      return Right(model);
    } catch (e) {
      return const Left(ServerFailure('Não foi possível carregar os detalhes do lead.'));
    }
  }

  @override
  Future<Either<Failure, Lead?>> getMyLead() async {
    try {
      final model = await remoteDatasource.getMyLead();
      return Right(model);
    } catch (e) {
      return const Left(ServerFailure('Erro ao carregar lead do cliente.'));
    }
  }

  @override
  Future<Either<Failure, Briefing>> getBriefing(String leadId) async {
    try {
      final briefing = await remoteDatasource.getBriefing(leadId);
      return Right(briefing);
    } catch (e) {
      return const Left(ServerFailure('Erro ao carregar briefing.'));
    }
  }

  @override
  Future<Either<Failure, List<Interacao>>> getInteractions(String leadId) async {
    try {
      final interactions = await remoteDatasource.getInteractions(leadId);
      return Right(interactions);
    } catch (e) {
      return const Left(ServerFailure('Erro ao carregar interações.'));
    }
  }

  @override
  Future<Either<Failure, ConversationSummary?>> getConversationSummary(String leadId) async {
    try {
      final model = await remoteDatasource.getConversationSummary(leadId);
      return Right(model?.toDomain());
    } catch (e) {
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, Lead>> createLead(CreateLeadRequest request) async {
    try {
      final model = await remoteDatasource.createLead(request);
      return Right(model);
    } catch (e) {
      return const Left(ServerFailure('Erro ao criar lead.'));
    }
  }

  @override
  Future<Either<Failure, Lead>> createManualLead(ManualLeadCreate request) async {
    try {
      final model = await remoteDatasource.createManualLead(request);
      return Right(model);
    } catch (e) {
      return const Left(ServerFailure('Erro ao criar lead manualmente.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleAya(String leadId, {required bool ativo, String? motivo}) async {
    try {
      await remoteDatasource.toggleAya(leadId, ativo: ativo, motivo: motivo);
      return const Right(unit);
    } catch (e) {
      return const Left(ServerFailure('Falha ao alterar o estado da AYA.'));
    }
  }

  @override
  Future<Either<Failure, Lead>> updateLeadStatus(String id, LeadStatus newStatus) async {
    try {
      final model = await remoteDatasource.updateLeadStatus(id, newStatus);
      return Right(model);
    } catch (e) {
      return const Left(ServerFailure('Erro ao atualizar status.'));
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
      final model = await remoteDatasource.updateLead(
        id: id,
        name: name,
        phone: phone,
        email: email,
        status: status,
        score: score,
      );
      return Right(model);
    } catch (e) {
      return const Left(ServerFailure('Erro ao atualizar lead.'));
    }
  }
}
