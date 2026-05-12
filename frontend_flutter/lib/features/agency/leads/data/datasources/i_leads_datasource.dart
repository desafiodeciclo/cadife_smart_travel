import 'package:cadife_smart_travel/features/agency/leads/data/models/conversation_summary_api_model.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/models/lead_api_model.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/client/historico/domain/entities/interacao.dart';

/// Contrato de fonte de dados para a gestão de Leads.
/// Define as operações entre o App e o Backend da Cadife Smart Travel.
abstract class ILeadsDatasource {
  // --- Consultas (Read) ---
  
  /// Lista leads com filtros opcionais de status e pontuação.
  Future<List<LeadApiModel>> getLeads({LeadStatus? status, LeadScore? score});

  /// Busca os detalhes completos de um lead específico.
  Future<LeadApiModel> getLeadById(String id);

  /// Recupera o lead associado ao usuário logado (perfil cliente).
  Future<LeadApiModel?> getMyLead();

  /// Retorna o briefing estruturado (dados coletados pela IA) de um lead.
  Future<Briefing> getBriefing(String leadId);

  /// Retorna o histórico de mensagens e eventos de um lead.
  Future<List<Interacao>> getInteractions(String leadId);

  /// Recupera o resumo estruturado da última conversa gerado pela IA.
  /// (Funcionalidade vinda da branch feat/lead-database-registration-flow)
  Future<ConversationSummaryApiModel?> getConversationSummary(String leadId);

  // --- Criação (Create) ---

  /// Cria um lead a partir de uma requisição padrão (Upsert).
  Future<LeadApiModel> createLead(CreateLeadRequest request);

  /// Cria um lead manualmente via painel da agência.
  Future<LeadApiModel> createManualLead(ManualLeadCreate request);

  // --- Operações e Controle (Update/Action) ---

  /// Ativa ou desativa a inteligência artificial (Aya) para um atendimento específico.
  /// Registra o motivo no histórico caso um humano assuma o controle.
  Future<void> toggleAya(String leadId, {required bool ativo, String? motivo});

  /// Altera o status do lead no funil de vendas.
  Future<LeadApiModel> updateLeadStatus(String id, LeadStatus newStatus);

  /// Reatribui um lead para outro consultor.
  Future<LeadApiModel> reassignLead(String id, String consultorNome);

  /// Atualiza múltiplos campos cadastrais do lead de forma atômica.
  /// (Funcionalidade vinda da branch developer)
  Future<LeadApiModel> updateLead({
    required String id,
    String? name,
    String? phone,
    String? email,
    LeadStatus? status,
    LeadScore? score,
  });
}