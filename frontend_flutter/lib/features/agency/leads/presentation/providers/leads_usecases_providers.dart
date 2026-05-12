import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/datasources/leads_remote_datasource.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/conversation_summary.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/leads_repository.dart';
import 'package:dartz/dartz.dart';

class LeadsRepositoryImpl implements LeadsRepository {
  final LeadsRemoteDataSource remoteDataSource;

  LeadsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Lead>> getLeadById(String id) async {
    try {
      final model = await remoteDataSource.getLeadById(id);
      return Right(model);
    } catch (e) {
      return Left(ServerFailure(message: 'Não foi possível carregar os detalhes do lead.'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleAya(String leadId, {required bool ativo, String? motivo}) async {
    try {
      await remoteDataSource.toggleAya(leadId, ativo: ativo, motivo: motivo);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Falha ao alterar o estado da AYA.'));
    }
  }

  @override
  Future<Either<Failure, ConversationSummary?>> getConversationSummary(String leadId) async {
    try {
      final summary = await remoteDataSource.getConversationSummary(leadId);
      return Right(summary);
    } catch (e) {
      // Retornamos null em vez de erro para não quebrar a UI de briefing
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, Lead>> updateLeadStatus(String id, LeadStatus status) async {
    try {
      final updatedModel = await remoteDataSource.updateLeadStatus(id, status.name);
      return Right(updatedModel);
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao atualizar status.'));
    }
  }
  
  // ... demais implementações (getLeads, createManualLead, etc)
}