import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/client/historico/domain/entities/interacao.dart';
import 'package:fpdart/fpdart.dart';

/// Contrato do Repositório de Leads.
/// Transforma os modelos da camada de Data em Entidades da camada de Domínio
/// e gerencia o tratamento de erros (Failures).
abstract class ILeadsRepository {
  // --- Consultas (Read) ---

  Future<Either<Failure, List<Lead>>> getLeads({LeadStatus? status, LeadScore? score});
  
  Future<Either<Failure, Lead>> getLeadById(String id);
  
  Future<Either<Failure, Lead?>> getMyLead();
  
  Future<Either<Failure, Briefing>> getBriefing(String leadId);
  
  Future<Either<Failure, List<Interacao>>> getInteractions(String leadId);

  // --- Criação (Create) ---

  Future<Either<Failure, Lead>> createLead(CreateLeadRequest request);
  
  Future<Either<Failure, Lead>> createManualLead(ManualLeadCreate request);

  // --- Operações e Controle (Update/Action) ---

  /// Ativa ou desativa o bot Aya para um lead específico.
  /// Retorna [Unit] em caso de sucesso.
  Future<Either<Failure, Unit>> toggleAya(String leadId, {required bool ativo, String? motivo});

  /// Atualiza o status do lead no pipeline.
  Future<Either<Failure, Lead>> updateLeadStatus(String id, LeadStatus newStatus);

  /// Atualiza múltiplos campos do lead (Nome, Telefone, Email, etc).
  Future<Either<Failure, Lead>> updateLead({
    required String id,
    String? name,
    String? phone,
    String? email,
    LeadStatus? status,
    LeadScore? score,
  });
  /// Reatribui um lead para outro consultor.
  Future<Either<Failure, Lead>> reassignLead(String id, String consultorNome);
}