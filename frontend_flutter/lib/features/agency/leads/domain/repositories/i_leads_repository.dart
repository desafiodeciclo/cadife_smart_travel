import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/conversation_summary.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/shared/domain/entities/interacao.dart';
import 'package:fpdart/fpdart.dart';

/// Contrato do Repositório de Leads.
/// Transforma os modelos da camada de Data em Entidades da camada de Domínio
/// e gerencia o tratamento de erros (Failures).
abstract class ILeadsRepository {
  // --- Consultas (Read) ---

  /// Lista leads com filtros, convertendo modelos da API para entidades de domínio.
  Future<Either<Failure, List<Lead>>> getLeads({LeadStatus? status, LeadScore? score});
  
  /// Busca detalhes de um lead por ID.
  Future<Either<Failure, Lead>> getLeadById(String id);
  
  /// Recupera o lead do usuário logado (Contexto do Cliente).
  Future<Either<Failure, Lead?>> getMyLead();
  
  /// Retorna o briefing consolidado da IA.
  Future<Either<Failure, Briefing>> getBriefing(String leadId);
  
  /// Retorna o histórico de interações mapeado para o domínio.
  Future<Either<Failure, List<Interacao>>> getInteractions(String leadId);

  /// Recupera o resumo estruturado da conversa gerado pela IA.
  /// (Funcionalidade: feat/lead-database-registration-flow)
  Future<Either<Failure, ConversationSummary?>> getConversationSummary(String leadId);

  // --- Criação (Create) ---

  /// Criação automática/upsert de lead.
  Future<Either<Failure, Lead>> createLead(CreateLeadRequest request);
  
  /// Criação manual de lead via painel.
  Future<Either<Failure, Lead>> createManualLead(ManualLeadCreate request);

  // --- Operações e Controle (Update/Action) ---

  /// Ativa ou desativa o bot Aya para um lead específico.
  /// Retorna [Unit] (vazio funcional) em caso de sucesso.
  /// (Funcionalidade: developer)
  Future<Either<Failure, Unit>> toggleAya(String leadId, {required bool ativo, String? motivo});

  /// Atualiza o status do lead no pipeline de vendas.
  Future<Either<Failure, Lead>> updateLeadStatus(String id, LeadStatus newStatus);

  /// Atualiza múltiplos campos do lead (Nome, Telefone, Email, etc).
  /// (Funcionalidade: developer)
  Future<Either<Failure, Lead>> updateLead({
    required String id,
    String? name,
    String? phone,
    String? email,
    LeadStatus? status,
    LeadScore? score,
  });
}