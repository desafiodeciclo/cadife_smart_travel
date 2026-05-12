import 'package:cadife_smart_travel/features/agency/leads/data/datasources/i_leads_datasource.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/models/conversation_summary_api_model.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/models/lead_api_model.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/client/historico/domain/entities/interacao.dart';

class LeadsRemoteMockDatasource implements ILeadsDatasource {
  final List<LeadApiModel> _mockLeads = [
    // ... [Mantém os leads mockados do seu código original: Mariana Souza, Ricardo Fernandes, Camila Rocha]
  ];

  // --- MÉTODOS DE LEITURA (READ) ---

  @override
  Future<List<LeadApiModel>> getLeads({LeadStatus? status, LeadScore? score}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockLeads.where((l) {
      if (status != null && l.status != status) return false;
      if (score != null && l.score != score) return false;
      return true;
    }).toList();
  }

  @override
  Future<LeadApiModel> getLeadById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockLeads.firstWhere((l) => l.id == id);
  }

  @override
  Future<LeadApiModel?> getMyLead() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockLeads.isNotEmpty ? _mockLeads.first : null;
  }

  @override
  Future<Briefing> getBriefing(String leadId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final lead = _mockLeads.firstWhere((l) => l.id == leadId, orElse: () => _mockLeads.first);
    return Briefing(
      leadId: leadId,
      completudePct: lead.completudePct,
      destino: lead.destino,
      numPessoas: lead.numPessoas,
      perfil: lead.perfil,
      tipoViagem: lead.tipoViagem,
      preferencias: lead.preferencias,
      orcamentoFaixa: lead.orcamentoFaixa,
      resumoConversa: 'Resumo simulado para o lead ${lead.name}.',
    );
  }

  @override
  Future<List<Interacao>> getInteractions(String leadId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      Interacao(
        id: 'i1_$leadId',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'inbound',
        content: 'Olá! Gostaria de saber mais sobre pacotes de viagem.',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ];
  }

  @override
  Future<ConversationSummaryApiModel?> getConversationSummary(String leadId) async {
    // Implementação unificada: Retorna um resumo detalhado para apoiar o consultor
    await Future.delayed(const Duration(milliseconds: 300));
    return ConversationSummaryApiModel(
      id: 'mock-summary-$leadId',
      leadId: leadId,
      sessaoId: 'mock:20260510_1000',
      resumoPendente: false,
      geradoEm: DateTime.now().subtract(const Duration(hours: 2)),
      resumoJson: const ConversationSummaryTopicsApiModel(
        intencaoPrincipal: 'Viagem para Paris em família',
        datasEPassageiros: 'Julho 2026 · 4 pessoas (casal + 2 filhos)',
        orcamento: 'Médio — aprox. R\$ 20.000',
        restricoesEPreferencias: 'Hotel próximo a pontos turísticos, voos diretos preferidos',
        decisõesTomadas: 'Interesse confirmado, aguardando proposta',
        proximosPassos: 'Consultor irá enviar proposta de pacote completo',
      ),
      tokensUtilizados: 312,
    );
  }

  // --- MÉTODOS DE CRIAÇÃO (CREATE) ---

  @override
  Future<LeadApiModel> createLead(CreateLeadRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newLead = LeadApiModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: request.name, phone: request.phone, email: request.email,
      status: LeadStatus.novo, score: LeadScore.frio,
      completudePct: 10, destino: request.destino, createdAt: DateTime.now(),
    );
    _mockLeads.insert(0, newLead);
    return newLead;
  }

  @override
  Future<LeadApiModel> createManualLead(ManualLeadCreate request) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final newLead = LeadApiModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: request.name, phone: request.phone, email: request.email,
      status: LeadStatus.novo, score: LeadScore.morno,
      completudePct: 15, destino: request.destino, dataIda: request.dataIda,
      numPessoas: request.numPessoas, orcamentoFaixa: request.orcamentoFaixa,
      preferencias: request.preferencias, consultorNome: 'Você', createdAt: DateTime.now(),
    );
    _mockLeads.insert(0, newLead);
    return newLead;
  }

  // --- MÉTODOS DE CONTROLE E ATUALIZAÇÃO (UPDATE) ---

  @override
  Future<void> toggleAya(String leadId, {required bool ativo, String? motivo}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Simula o log de desativação da IA no console para debug
    print('DEBUG: AYA ${ativo ? 'ativada' : 'desativada'} para lead $leadId. Motivo: $motivo');
  }

  @override
  Future<LeadApiModel> updateLeadStatus(String id, LeadStatus newStatus) async {
    return updateLead(id: id, status: newStatus);
  }

  @override
  Future<LeadApiModel> reassignLead(String id, String consultorNome) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockLeads.indexWhere((l) => l.id == id);
    if (index == -1) throw Exception('Lead não encontrado');
    
    final updated = _mockLeads[index].copyWith(
      consultorNome: consultorNome,
      updatedAt: DateTime.now(),
    );
    _mockLeads[index] = updated;
    return updated;
  }

  @override
  Future<LeadApiModel> updateLead({
    required String id,
    String? name,
    String? phone,
    String? email,
    LeadStatus? status,
    LeadScore? score,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final index = _mockLeads.indexWhere((l) => l.id == id);
    if (index == -1) throw Exception('Lead não encontrado');
    
    final old = _mockLeads[index];
    final updated = old.copyWith(
      name: name ?? old.name,
      phone: phone ?? old.phone,
      email: email ?? old.email,
      status: status ?? old.status,
      score: score ?? old.score,
      updatedAt: DateTime.now(),
    );
    _mockLeads[index] = updated;
    return updated;
  }
}