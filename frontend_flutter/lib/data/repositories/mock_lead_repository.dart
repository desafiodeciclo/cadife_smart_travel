import 'package:cadife_smart_travel/core/ports/lead_port.dart';
import 'package:cadife_smart_travel/shared/models/briefing_model.dart';
import 'package:cadife_smart_travel/shared/models/interaction_model.dart';
import 'package:cadife_smart_travel/shared/models/lead_model.dart';

class MockLeadRepository implements LeadPort {
  final List<LeadModel> _mockLeads = [
    LeadModel(
      id: '1',
      name: 'João Silva',
      phone: '11999999999',
      status: LeadStatus.emAtendimento,
      score: LeadScore.quente,
      completudePct: 85,
      destino: 'Paris, França',
      dataIda: DateTime.now().add(const Duration(days: 45)),
      dataVolta: DateTime.now().add(const Duration(days: 55)),
      numPessoas: 2,
      perfil: 'Casal',
      tipoViagem: 'Lazer',
      consultorNome: 'Ricardo Silva',
      consultorAvatar: 'https://i.pravatar.cc/150?u=ricardo',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    LeadModel(
      id: '2',
      name: 'Maria Oliveira',
      phone: '11888888888',
      status: LeadStatus.proposta,
      score: LeadScore.morno,
      completudePct: 60,
      destino: 'Roma, Itália',
      dataIda: DateTime.now().add(const Duration(days: 60)),
      dataVolta: DateTime.now().add(const Duration(days: 70)),
      numPessoas: 1,
      perfil: 'Individual',
      tipoViagem: 'Cultura',
      consultorNome: 'Ana Clara',
      consultorAvatar: 'https://i.pravatar.cc/150?u=ana',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  @override
  Future<List<LeadModel>> getLeads({LeadStatus? status, LeadScore? score}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockLeads.where((l) {
      if (status != null && l.status != status) return false;
      if (score != null && l.score != score) return false;
      return true;
    }).toList();
  }

  @override
  Future<LeadModel> getLeadById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockLeads.firstWhere((l) => l.id == id);
  }

  @override
  Future<LeadModel?> getMyLead() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Retorna o primeiro lead como sendo o do usuário logado (mock)
    return _mockLeads.first;
  }

  @override
  Future<LeadModel> updateLeadStatus(String id, LeadStatus newStatus) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockLeads.indexWhere((l) => l.id == id);
    if (index != -1) {
      final updated = LeadModel(
        id: _mockLeads[index].id,
        name: _mockLeads[index].name,
        phone: _mockLeads[index].phone,
        status: newStatus,
        score: _mockLeads[index].score,
        completudePct: _mockLeads[index].completudePct,
        destino: _mockLeads[index].destino,
        dataIda: _mockLeads[index].dataIda,
        dataVolta: _mockLeads[index].dataVolta,
        numPessoas: _mockLeads[index].numPessoas,
        perfil: _mockLeads[index].perfil,
        tipoViagem: _mockLeads[index].tipoViagem,
        consultorNome: _mockLeads[index].consultorNome,
        consultorAvatar: _mockLeads[index].consultorAvatar,
        createdAt: _mockLeads[index].createdAt,
      );
      _mockLeads[index] = updated;
      return updated;
    }
    throw Exception('Lead not found');
  }

  @override
  Future<BriefingModel> getBriefing(String leadId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return BriefingModel(
      leadId: leadId,
      completudePct: 85,
      destino: 'Paris, França',
      numPessoas: 2,
      perfil: 'Casal',
      tipoViagem: 'Lazer',
      preferencias: 'Hotel 5 estrelas, passeios gastronômicos',
      orcamentoFaixa: '20k - 50k',
      resumoConversa: 'Cliente busca uma viagem romântica para comemorar aniversário de casamento.',
    );
  }

  @override
  Future<List<InteractionModel>> getInteractions(String leadId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return [
      InteractionModel(
        id: 'i1',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'inbound',
        content: 'Olá, gostaria de saber mais sobre pacotes para Paris. Somos um casal comemorando aniversário de casamento.',
        timestamp: now.subtract(const Duration(days: 3, hours: 2)),
      ),
      InteractionModel(
        id: 'i2',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'outbound',
        content: 'Que lindo! Parabéns pelo aniversário de casamento! 🎉 Paris é um destino perfeito para esse momento especial. Para te ajudar melhor, qual seria o período de viagem pretendido?',
        timestamp: now.subtract(const Duration(days: 3, hours: 1, minutes: 55)),
      ),
      InteractionModel(
        id: 'i3',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'inbound',
        content: 'Pensamos em ir em julho, por uns 10 dias.',
        timestamp: now.subtract(const Duration(days: 3, hours: 1, minutes: 30)),
      ),
      InteractionModel(
        id: 'i4',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'outbound',
        content: 'Julho em Paris é maravilhoso! Dias longos e o clima perfeito para passear pelos bairros. Vocês têm alguma preferência de hospedagem? Hotel boutique, hotel de luxo ou apartamento?',
        timestamp: now.subtract(const Duration(days: 3, hours: 1, minutes: 20)),
      ),
      InteractionModel(
        id: 'i5',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'inbound',
        content: 'Prefiro hotel mesmo, algo próximo ao centro ou à Torre Eiffel.',
        timestamp: now.subtract(const Duration(days: 2, hours: 10)),
      ),
      InteractionModel(
        id: 'i6',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'outbound',
        content: 'Ótima escolha! Temos opções incríveis no 7º arrondissement, bem pertinho da Torre Eiffel. Nosso consultor vai montar uma curadoria especial para vocês. Tem alguma restrição alimentar ou preferência de passeio?',
        timestamp: now.subtract(const Duration(days: 2, hours: 9, minutes: 50)),
      ),
      InteractionModel(
        id: 'i7',
        leadId: leadId,
        channel: 'consultor',
        direction: 'outbound',
        content: 'Olá! Sou o Ricardo, consultor da Cadife Tour. Acabei de analisar seu perfil e já tenho algumas sugestões maravilhosas para sua lua de mel em Paris. Posso entrar em contato por aqui para alinhar os detalhes?',
        timestamp: now.subtract(const Duration(days: 1, hours: 14)),
      ),
      InteractionModel(
        id: 'i8',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'inbound',
        content: 'Claro! Adoraria ouvir as sugestões.',
        timestamp: now.subtract(const Duration(days: 1, hours: 13, minutes: 45)),
      ),
      InteractionModel(
        id: 'i9',
        leadId: leadId,
        channel: 'consultor',
        direction: 'outbound',
        content: 'Perfeito! Vou preparar uma proposta completa com roteiro, hospedagem e experiências gastronômicas exclusivas. Você recebe ainda hoje.',
        timestamp: now.subtract(const Duration(days: 1, hours: 13, minutes: 30)),
      ),
      InteractionModel(
        id: 'i10',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'outbound',
        content: 'Seu briefing está completo! 🎯 Nosso consultor Ricardo já está preparando uma proposta personalizada para a sua viagem a Paris. Em breve você receberá todos os detalhes.',
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
    ];
  }

  @override
  Future<LeadModel> createLead(CreateLeadRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newLead = LeadModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: request.name,
      phone: request.phone,
      email: request.email,
      status: LeadStatus.novo,
      score: LeadScore.frio,
      completudePct: 10,
      destino: request.destino,
      createdAt: DateTime.now(),
    );
    _mockLeads.add(newLead);
    return newLead;
  }
}
