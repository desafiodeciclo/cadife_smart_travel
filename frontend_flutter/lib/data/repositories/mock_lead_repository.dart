import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/interacao.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/lead_port.dart';

class MockLeadRepository implements LeadPort {
  final List<Lead> _mockLeads = [
    Lead(
      id: '1',
      name: 'Mariana Souza',
      phone: '+55 11 99999-0001',
      email: 'mariana.souza@gmail.com',
      status: LeadStatus.novo,
      score: LeadScore.quente,
      completudePct: 20,
      destino: 'Paris, FranÃƒÂ§a',
      numPessoas: 2,
      perfil: 'Casal',
      tipoViagem: 'Lua de mel',
      orcamentoFaixa: '30k - 50k',
      passaporteValido: true,
      experienciaInternacional: true,
      consultorNome: 'Jakeline Lima',
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    Lead(
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
      perfil: 'FamÃƒÂ­lia',
      tipoViagem: 'Lazer',
      orcamentoFaixa: '50k - 80k',
      passaporteValido: true,
      experienciaInternacional: true,
      preferencias: 'Hotel no centro, parques temÃƒÂ¡ticos',
      consultorNome: 'Jakeline Lima',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Lead(
      id: '3',
      name: 'Camila Rocha',
      phone: '+55 21 97777-0003',
      email: 'camila.r@hotmail.com',
      status: LeadStatus.qualificado,
      score: LeadScore.quente,
      completudePct: 80,
      destino: 'TÃƒÂ³quio, JapÃƒÂ£o',
      dataIda: DateTime(2025, 10, 5),
      dataVolta: DateTime(2025, 10, 18),
      numPessoas: 2,
      perfil: 'Casal',
      tipoViagem: 'Cultura e Gastronomia',
      orcamentoFaixa: '40k - 60k',
      passaporteValido: true,
      experienciaInternacional: false,
      preferencias: 'Ryokan tradicional, tour de culinÃƒÂ¡ria',
      consultorNome: 'Diego Costa',
      createdAt: DateTime.now().subtract(const Duration(hours: 18)),
    ),
    Lead(
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
      perfil: 'FamÃƒÂ­lia',
      tipoViagem: 'Lazer',
      orcamentoFaixa: '20k - 35k',
      passaporteValido: true,
      experienciaInternacional: true,
      preferencias: 'Apartamento, aluguel de carro',
      consultorNome: 'Jakeline Lima',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Lead(
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
    Lead(
      id: '6',
      name: 'Thiago Mendes',
      phone: '+55 62 94444-0006',
      status: LeadStatus.fechado,
      score: LeadScore.quente,
      completudePct: 100,
      destino: 'Roma + Amalfi, ItÃƒÂ¡lia',
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
    Lead(
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
    Lead(
      id: '8',
      name: 'Henrique Barbosa',
      phone: '+55 51 92222-0008',
      status: LeadStatus.novo,
      score: LeadScore.frio,
      completudePct: 10,
      consultorNome: 'Diego Costa',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    Lead(
      id: '9',
      name: 'PatrÃƒÂ­cia Nunes',
      phone: '+55 71 91111-0009',
      email: 'patricias@empresa.com.br',
      status: LeadStatus.qualificado,
      score: LeadScore.morno,
      completudePct: 70,
      destino: 'CancÃƒÂºn, MÃƒÂ©xico',
      dataIda: DateTime(2025, 11, 1),
      dataVolta: DateTime(2025, 11, 10),
      numPessoas: 5,
      perfil: 'FamÃƒÂ­lia',
      tipoViagem: 'Praia e Lazer',
      orcamentoFaixa: '35k - 50k',
      passaporteValido: true,
      experienciaInternacional: false,
      consultorNome: 'Jakeline Lima',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Lead(
      id: '10',
      name: 'Eduardo GonÃƒÂ§alves',
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
    Lead(
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
      tipoViagem: 'RÃƒÂ©veillon',
      orcamentoFaixa: '80k - 120k',
      passaporteValido: true,
      experienciaInternacional: true,
      preferencias: 'Hotel de luxo, experiÃƒÂªncias VIP',
      consultorNome: 'Diego Costa',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Lead(
      id: '12',
      name: 'Gustavo Teixeira',
      phone: '+55 34 97766-0012',
      status: LeadStatus.proposta,
      score: LeadScore.morno,
      completudePct: 75,
      destino: 'AmsterdÃƒÂ£, Holanda',
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
  Future<List<Lead>> getLeads({LeadStatus? status, LeadScore? score}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockLeads.where((l) {
      if (status != null && l.status != status) return false;
      if (score != null && l.score != score) return false;
      return true;
    }).toList();
  }

  @override
  Future<Lead> getLeadById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockLeads.firstWhere((l) => l.id == id);
  }

  @override
  Future<Lead?> getMyLead() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockLeads.first;
  }

  @override
  Future<Lead> updateLeadStatus(String id, LeadStatus newStatus) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockLeads.indexWhere((l) => l.id == id);
    if (index == -1) throw Exception('Lead nÃƒÂ£o encontrado: $id');
    final old = _mockLeads[index];
    final updated = Lead(
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
  Future<Briefing> getBriefing(String leadId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final lead = _mockLeads.firstWhere(
      (l) => l.id == leadId,
      orElse: () => _mockLeads.first,
    );
    return Briefing(
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
          'Perfil: ${lead.perfil ?? "nÃƒÂ£o identificado"}. '
          'Aguardando curadoria do consultor.',
    );
  }

  @override
  Future<List<Interacao>> getInteractions(String leadId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return [
      Interacao(
        id: 'i1_$leadId',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'inbound',
        content: 'OlÃƒÂ¡! Gostaria de saber mais sobre pacotes de viagem.',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      Interacao(
        id: 'i2_$leadId',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'outbound',
        content:
            'OlÃƒÂ¡! Que ÃƒÂ³timo ter vocÃƒÂª aqui. Sou a AYA, assistente da Cadife Tour. '
            'Para te ajudar melhor, pode me contar um pouco mais sobre a viagem que vocÃƒÂª sonha?',
        timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 55)),
      ),
      Interacao(
        id: 'i3_$leadId',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'inbound',
        content:
            'Quero viajar com minha famÃƒÂ­lia em julho. Somos 4 pessoas e queremos algo especial!',
        timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 50)),
      ),
      Interacao(
        id: 'i4_$leadId',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'outbound',
        content: 'Que lindo! ParabÃƒÂ©ns pelo aniversÃƒÂ¡rio de casamento! Ã°Å¸Å½â€° Paris ÃƒÂ© um destino perfeito para esse momento especial. Para te ajudar melhor, qual seria o perÃƒÂ­odo de viagem pretendido?',
        timestamp: now.subtract(const Duration(days: 3, hours: 1, minutes: 55)),
      ),
      Interacao(
        id: 'i3',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'inbound',
        content: 'Pensamos em ir em julho, por uns 10 dias.',
        timestamp: now.subtract(const Duration(days: 3, hours: 1, minutes: 30)),
      ),
      Interacao(
        id: 'i4',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'outbound',
        content: 'Julho em Paris ÃƒÂ© maravilhoso! Dias longos e o clima perfeito para passear pelos bairros. VocÃƒÂªs tÃƒÂªm alguma preferÃƒÂªncia de hospedagem? Hotel boutique, hotel de luxo ou apartamento?',
        timestamp: now.subtract(const Duration(days: 3, hours: 1, minutes: 20)),
      ),
      Interacao(
        id: 'i5',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'inbound',
        content: 'Prefiro hotel mesmo, algo prÃƒÂ³ximo ao centro ou ÃƒÂ  Torre Eiffel.',
        timestamp: now.subtract(const Duration(days: 2, hours: 10)),
      ),
      Interacao(
        id: 'i6',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'outbound',
        content: 'Ãƒâ€œtima escolha! Temos opÃƒÂ§ÃƒÂµes incrÃƒÂ­veis no 7Ã‚Âº arrondissement, bem pertinho da Torre Eiffel. Nosso consultor vai montar uma curadoria especial para vocÃƒÂªs. Tem alguma restriÃƒÂ§ÃƒÂ£o alimentar ou preferÃƒÂªncia de passeio?',
        timestamp: now.subtract(const Duration(days: 2, hours: 9, minutes: 50)),
      ),
      Interacao(
        id: 'i7',
        leadId: leadId,
        channel: 'consultor',
        direction: 'outbound',
        content: 'OlÃƒÂ¡! Sou o Ricardo, consultor da Cadife Tour. Acabei de analisar seu perfil e jÃƒÂ¡ tenho algumas sugestÃƒÂµes maravilhosas para sua lua de mel em Paris. Posso entrar em contato por aqui para alinhar os detalhes?',
        timestamp: now.subtract(const Duration(days: 1, hours: 14)),
      ),
      Interacao(
        id: 'i8',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'inbound',
        content: 'Claro! Adoraria ouvir as sugestÃƒÂµes.',
        timestamp: now.subtract(const Duration(days: 1, hours: 13, minutes: 45)),
      ),
      Interacao(
        id: 'i9',
        leadId: leadId,
        channel: 'consultor',
        direction: 'outbound',
        content: 'Perfeito! Vou preparar uma proposta completa com roteiro, hospedagem e experiÃƒÂªncias gastronÃƒÂ´micas exclusivas. VocÃƒÂª recebe ainda hoje.',
        timestamp: now.subtract(const Duration(days: 1, hours: 13, minutes: 30)),
      ),
      Interacao(
        id: 'i10',
        leadId: leadId,
        channel: 'whatsapp',
        direction: 'outbound',
        content: 'Seu briefing estÃƒÂ¡ completo! Ã°Å¸Å½Â¯ Nosso consultor Ricardo jÃƒÂ¡ estÃƒÂ¡ preparando uma proposta personalizada para a sua viagem a Paris. Em breve vocÃƒÂª receberÃƒÂ¡ todos os detalhes.',
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
    ];
  }

  @override
  Future<Lead> createLead(CreateLeadRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newLead = Lead(
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




