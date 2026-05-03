import 'package:cadife_smart_travel/core/ports/lead_port.dart';
import 'package:cadife_smart_travel/shared/models/briefing_model.dart';
import 'package:cadife_smart_travel/shared/models/interaction_model.dart';
import 'package:cadife_smart_travel/shared/models/lead_model.dart';

class MockLeadRepository implements LeadPort {
  final List<LeadModel> _mockLeads = [
    LeadModel(
      id: '1',
      name: 'Mariana Souza',
      phone: '+55 11 99999-0001',
      email: 'mariana.souza@gmail.com',
      status: LeadStatus.novo,
      score: LeadScore.quente,
      completudePct: 20,
      destino: 'Paris, França',
      numPessoas: 2,
      perfil: 'Casal',
      tipoViagem: 'Lua de mel',
      orcamentoFaixa: '30k - 50k',
      passaporteValido: true,
      experienciaInternacional: true,
      consultorNome: 'Jakeline Lima',
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    LeadModel(
      id: '2',
      name: 'Ricardo Fernandes',
      phone: '+55 11 98888-0002',
      email: 'rfernandes@empresa.com',
      status: LeadStatus.emAtendimento,
      score: LeadScore.quente,
      completudePct: 65,
      destino: 'Nova York, EUA',
      dataIda: DateTime(2025, 8, 10),
      dataVolta: DateTime(2025, 8, 22),
      numPessoas: 4,
      perfil: 'Família',
      tipoViagem: 'Lazer',
      orcamentoFaixa: '50k - 80k',
      passaporteValido: true,
      experienciaInternacional: true,
      preferencias: 'Hotel no centro, parques temáticos',
      consultorNome: 'Jakeline Lima',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    LeadModel(
      id: '3',
      name: 'Camila Rocha',
      phone: '+55 21 97777-0003',
      email: 'camila.r@hotmail.com',
      status: LeadStatus.qualificado,
      score: LeadScore.quente,
      completudePct: 80,
      destino: 'Tóquio, Japão',
      dataIda: DateTime(2025, 10, 5),
      dataVolta: DateTime(2025, 10, 18),
      numPessoas: 2,
      perfil: 'Casal',
      tipoViagem: 'Cultura e Gastronomia',
      orcamentoFaixa: '40k - 60k',
      passaporteValido: true,
      experienciaInternacional: false,
      preferencias: 'Ryokan tradicional, tour de culinária',
      consultorNome: 'Diego Costa',
      createdAt: DateTime.now().subtract(const Duration(hours: 18)),
    ),
    LeadModel(
      id: '4',
      name: 'Bruno Almeida',
      phone: '+55 31 96666-0004',
      status: LeadStatus.agendado,
      score: LeadScore.morno,
      completudePct: 72,
      destino: 'Lisboa + Porto, Portugal',
      dataIda: DateTime(2025, 9, 15),
      dataVolta: DateTime(2025, 9, 26),
      numPessoas: 3,
      perfil: 'Família',
      tipoViagem: 'Lazer',
      orcamentoFaixa: '20k - 35k',
      passaporteValido: true,
      experienciaInternacional: true,
      preferencias: 'Apartamento, aluguel de carro',
      consultorNome: 'Jakeline Lima',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    LeadModel(
      id: '5',
      name: 'Fernanda Castro',
      phone: '+55 41 95555-0005',
      email: 'fcastro@outlook.com',
      status: LeadStatus.proposta,
      score: LeadScore.quente,
      completudePct: 95,
      destino: 'Maldivas',
      dataIda: DateTime(2025, 7, 20),
      dataVolta: DateTime(2025, 7, 30),
      numPessoas: 2,
      perfil: 'Casal',
      tipoViagem: 'Lua de mel',
      orcamentoFaixa: '60k - 100k',
      passaporteValido: true,
      experienciaInternacional: true,
      preferencias: 'Over water bungalow, all inclusive',
      consultorNome: 'Diego Costa',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    LeadModel(
      id: '6',
      name: 'Thiago Mendes',
      phone: '+55 62 94444-0006',
      status: LeadStatus.fechado,
      score: LeadScore.quente,
      completudePct: 100,
      destino: 'Roma + Amalfi, Itália',
      dataIda: DateTime(2025, 6, 10),
      dataVolta: DateTime(2025, 6, 24),
      numPessoas: 2,
      perfil: 'Casal',
      tipoViagem: 'Lazer e Gastronomia',
      orcamentoFaixa: '45k - 65k',
      passaporteValido: true,
      experienciaInternacional: true,
      consultorNome: 'Diego Costa',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    LeadModel(
      id: '7',
      name: 'Larissa Pinto',
      phone: '+55 85 93333-0007',
      email: 'larissap@gmail.com',
      status: LeadStatus.emAtendimento,
      score: LeadScore.morno,
      completudePct: 45,
      destino: 'Buenos Aires, Argentina',
      numPessoas: 1,
      perfil: 'Solo',
      tipoViagem: 'Cultural',
      orcamentoFaixa: '8k - 15k',
      passaporteValido: false,
      experienciaInternacional: false,
      consultorNome: 'Jakeline Lima',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    LeadModel(
      id: '8',
      name: 'Henrique Barbosa',
      phone: '+55 51 92222-0008',
      status: LeadStatus.novo,
      score: LeadScore.frio,
      completudePct: 10,
      consultorNome: 'Diego Costa',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    LeadModel(
      id: '9',
      name: 'Patrícia Nunes',
      phone: '+55 71 91111-0009',
      email: 'patricias@empresa.com.br',
      status: LeadStatus.qualificado,
      score: LeadScore.morno,
      completudePct: 70,
      destino: 'Cancún, México',
      dataIda: DateTime(2025, 11, 1),
      dataVolta: DateTime(2025, 11, 10),
      numPessoas: 5,
      perfil: 'Família',
      tipoViagem: 'Praia e Lazer',
      orcamentoFaixa: '35k - 50k',
      passaporteValido: true,
      experienciaInternacional: false,
      consultorNome: 'Jakeline Lima',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    LeadModel(
      id: '10',
      name: 'Eduardo Gonçalves',
      phone: '+55 11 90000-0010',
      status: LeadStatus.perdido,
      score: LeadScore.frio,
      completudePct: 30,
      destino: 'Barcelona, Espanha',
      numPessoas: 2,
      perfil: 'Casal',
      tipoViagem: 'Lazer',
      orcamentoFaixa: '15k - 25k',
      passaporteValido: false,
      consultorNome: 'Diego Costa',
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
    ),
    LeadModel(
      id: '11',
      name: 'Amanda Silveira',
      phone: '+55 27 98877-0011',
      email: 'amanda.s@gmail.com',
      status: LeadStatus.agendado,
      score: LeadScore.quente,
      completudePct: 88,
      destino: 'Dubai, Emirados',
      dataIda: DateTime(2025, 12, 20),
      dataVolta: DateTime(2026, 1, 2),
      numPessoas: 2,
      perfil: 'Casal',
      tipoViagem: 'Réveillon',
      orcamentoFaixa: '80k - 120k',
      passaporteValido: true,
      experienciaInternacional: true,
      preferencias: 'Hotel de luxo, experiências VIP',
      consultorNome: 'Diego Costa',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    LeadModel(
      id: '12',
      name: 'Gustavo Teixeira',
      phone: '+55 34 97766-0012',
      status: LeadStatus.proposta,
      score: LeadScore.morno,
      completudePct: 75,
      destino: 'Amsterdã, Holanda',
      dataIda: DateTime(2025, 9, 5),
      dataVolta: DateTime(2025, 9, 14),
      numPessoas: 3,
      perfil: 'Amigos',
      tipoViagem: 'Lazer',
      orcamentoFaixa: '25k - 40k',
      passaporteValido: true,
      experienciaInternacional: true,
      consultorNome: 'Jakeline Lima',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
  ];

  @override
  Future<List<LeadModel>> getLeads({LeadStatus? status, LeadScore? score}) async {
    await Future.delayed(const Duration(milliseconds: 600));
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
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockLeads.first;
  }

  @override
  Future<LeadModel> updateLeadStatus(String id, LeadStatus newStatus) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockLeads.indexWhere((l) => l.id == id);
    if (index == -1) throw Exception('Lead não encontrado: $id');
    final old = _mockLeads[index];
    final updated = LeadModel(
      id: old.id,
      name: old.name,
      phone: old.phone,
      email: old.email,
      status: newStatus,
      score: old.score,
      completudePct: old.completudePct,
      destino: old.destino,
      dataIda: old.dataIda,
      dataVolta: old.dataVolta,
      numPessoas: old.numPessoas,
      perfil: old.perfil,
      tipoViagem: old.tipoViagem,
      preferencias: old.preferencias,
      orcamentoFaixa: old.orcamentoFaixa,
      passaporteValido: old.passaporteValido,
      experienciaInternacional: old.experienciaInternacional,
      assignedTo: old.assignedTo,
      consultorNome: old.consultorNome,
      consultorAvatar: old.consultorAvatar,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    _mockLeads[index] = updated;
    return updated;
  }

  @override
  Future<BriefingModel> getBriefing(String leadId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final lead = _mockLeads.firstWhere(
      (l) => l.id == leadId,
      orElse: () => _mockLeads.first,
    );
    return BriefingModel(
      leadId: leadId,
      completudePct: lead.completudePct,
      destino: lead.destino,
      numPessoas: lead.numPessoas,
      perfil: lead.perfil,
      tipoViagem: lead.tipoViagem,
      preferencias: lead.preferencias,
      orcamentoFaixa: lead.orcamentoFaixa,
      resumoConversa:
          'Cliente interessado em ${lead.destino ?? "destino a confirmar"}. '
          'Perfil: ${lead.perfil ?? "não identificado"}. '
          'Aguardando curadoria do consultor.',
    );
  }

  @override
  Future<List<InteractionModel>> getInteractions(String leadId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return [
      InteractionModel(
        id: 'i1_$leadId',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'inbound',
        content: 'Olá! Gostaria de saber mais sobre pacotes de viagem.',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      InteractionModel(
        id: 'i2_$leadId',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'outbound',
        content:
            'Olá! Que ótimo ter você aqui. Sou a AYA, assistente da Cadife Tour. '
            'Para te ajudar melhor, pode me contar um pouco mais sobre a viagem que você sonha?',
        timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 55)),
      ),
      InteractionModel(
        id: 'i3_$leadId',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'inbound',
        content:
            'Quero viajar com minha família em julho. Somos 4 pessoas e queremos algo especial!',
        timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 50)),
      ),
      InteractionModel(
        id: 'i4_$leadId',
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
    _mockLeads.insert(0, newLead);
    return newLead;
  }
}
