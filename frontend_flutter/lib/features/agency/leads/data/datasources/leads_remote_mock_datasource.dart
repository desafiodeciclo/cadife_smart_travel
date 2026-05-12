import 'package:cadife_smart_travel/features/agency/leads/data/datasources/i_leads_datasource.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/models/lead_api_model.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/client/historico/domain/entities/interacao.dart';

/// Dados alinhados com backend/scripts/db/seeds/02_leads.py e 03_briefings.py
class LeadsRemoteMockDatasource implements ILeadsDatasource {
  final List<LeadApiModel> _mockLeads = [
    // Daniela Costa — lead fechado (Otávio Grotto)
    LeadApiModel(
      id: 'otavio-grotto',
      name: 'Otávio Grotto',
      phone: '+55 11 96666-6666',
      email: 'otavio.grotto@gmail.com',
      status: LeadStatus.fechado,
      score: LeadScore.quente,
      completudePct: 100,
      destino: 'Paris, França',
      dataIda: DateTime(2026, 6, 15),
      dataVolta: DateTime(2026, 6, 22),
      numPessoas: 2,
      perfil: 'Casal',
      tipoViagem: 'Romântica / Luxo',
      orcamentoFaixa: 'Premium (acima de 25k)',
      passaporteValido: true,
      experienciaInternacional: true,
      preferencias: 'Monumentos, restaurantes estrelados, museus',
      consultorNome: 'Daniela Costa',
      createdAt: DateTime(2026, 1, 10),
    ),
    // Daniela Costa — lead proposta (Camila Santos)
    LeadApiModel(
      id: 'camila-santos',
      name: 'Camila Santos',
      phone: '+55 11 95555-5555',
      email: 'camila.santos@gmail.com',
      status: LeadStatus.proposta,
      score: LeadScore.morno,
      completudePct: 96,
      destino: 'Tóquio, Japão',
      dataIda: DateTime(2026, 8, 5),
      dataVolta: DateTime(2026, 8, 19),
      numPessoas: 4,
      perfil: 'Amigos',
      tipoViagem: 'Aventura / Gastronomia',
      orcamentoFaixa: 'Alto (15k–25k)',
      passaporteValido: true,
      experienciaInternacional: true,
      preferencias: 'Templos, culinária local, lojas de anime',
      consultorNome: 'Daniela Costa',
      createdAt: DateTime(2026, 2, 5),
    ),
    // Jakeline Lima — lead agendado (Rafael Mendes)
    LeadApiModel(
      id: 'rafael-mendes',
      name: 'Rafael Mendes',
      phone: '+55 11 94444-4444',
      email: 'rafael.mendes@gmail.com',
      status: LeadStatus.agendado,
      score: LeadScore.quente,
      completudePct: 92,
      destino: 'Nova York, EUA',
      dataIda: DateTime(2026, 7, 15),
      dataVolta: DateTime(2026, 7, 25),
      numPessoas: 4,
      perfil: 'Família',
      tipoViagem: 'Turismo / Compras',
      orcamentoFaixa: 'Alto (15k–25k)',
      passaporteValido: false,
      experienciaInternacional: false,
      preferencias: '2 adultos e 2 crianças (8 e 12 anos)',
      consultorNome: 'Jakeline Lima',
      createdAt: DateTime(2026, 3, 1),
    ),
    // Jakeline Lima — lead novo (João Silva)
    LeadApiModel(
      id: 'joao-silva',
      name: 'João Silva',
      phone: '+55 11 99999-9999',
      email: null,
      status: LeadStatus.novo,
      score: LeadScore.frio,
      completudePct: 15,
      destino: 'Europa',
      numPessoas: null,
      perfil: null,
      tipoViagem: null,
      orcamentoFaixa: null,
      passaporteValido: null,
      experienciaInternacional: null,
      preferencias: 'Ainda definindo roteiro. Interesse em Portugal ou Espanha.',
      consultorNome: 'Jakeline Lima',
      createdAt: DateTime(2026, 4, 20),
    ),
    // Diego Costa — lead em_atendimento (Maria Oliveira)
    LeadApiModel(
      id: 'maria-oliveira',
      name: 'Maria Oliveira',
      phone: '+55 11 88888-8888',
      email: null,
      status: LeadStatus.emAtendimento,
      score: LeadScore.morno,
      completudePct: 48,
      destino: 'Cancún, México',
      dataIda: DateTime(2026, 12, 20),
      dataVolta: null,
      numPessoas: 2,
      perfil: 'Casal',
      tipoViagem: 'Lazer',
      orcamentoFaixa: 'Médio (8k–15k)',
      passaporteValido: null,
      experienciaInternacional: null,
      consultorNome: 'Diego Costa',
      createdAt: DateTime(2026, 4, 28),
    ),
    // Marcos Andrade — lead qualificado (Ana Luiza Gomes)
    LeadApiModel(
      id: 'ana-luiza-gomes',
      name: 'Ana Luiza Gomes',
      phone: '+55 11 86666-6666',
      email: null,
      status: LeadStatus.qualificado,
      score: LeadScore.quente,
      completudePct: 82,
      destino: 'Maldivas',
      dataIda: DateTime(2026, 9, 5),
      dataVolta: DateTime(2026, 9, 15),
      numPessoas: 2,
      perfil: 'Casal',
      tipoViagem: 'Lua de mel',
      orcamentoFaixa: 'Alto (15k–25k)',
      passaporteValido: true,
      experienciaInternacional: true,
      preferencias: 'Villa overwater, tranquilidade',
      consultorNome: 'Marcos Andrade',
      createdAt: DateTime(2026, 5, 3),
    ),
  ];

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
    return _mockLeads.first;
  }

  @override
  Future<LeadApiModel> updateLeadStatus(String id, LeadStatus newStatus) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockLeads.indexWhere((l) => l.id == id);
    if (index == -1) throw Exception('Lead não encontrado: $id');
    final old = _mockLeads[index];
    final updated = LeadApiModel(
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
          'Perfil: ${lead.perfil ?? "não identificado"}. '
          'Aguardando curadoria do consultor.',
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
  Future<LeadApiModel> createLead(CreateLeadRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newLead = LeadApiModel(
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

  @override
  Future<LeadApiModel> reassignLead(String id, String consultorNome) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockLeads.indexWhere((l) => l.id == id);
    if (index == -1) throw Exception('Lead não encontrado: $id');
    final old = _mockLeads[index];
    final updated = LeadApiModel(
      id: old.id,
      name: old.name,
      phone: old.phone,
      email: old.email,
      status: old.status,
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
      consultorNome: consultorNome,
      consultorAvatar: old.consultorAvatar,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    _mockLeads[index] = updated;
    return updated;
  }

  @override
  Future<LeadApiModel> createManualLead(ManualLeadCreate request) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final newLead = LeadApiModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: request.name,
      phone: request.phone,
      email: request.email,
      status: LeadStatus.novo,
      score: LeadScore.morno,
      completudePct: 15,
      destino: request.destino,
      dataIda: request.dataIda,
      numPessoas: request.numPessoas,
      orcamentoFaixa: request.orcamentoFaixa,
      preferencias: request.preferencias,
      consultorNome: 'Você',
      createdAt: DateTime.now(),
    );
    _mockLeads.insert(0, newLead);
    return newLead;
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
    if (index == -1) throw Exception('Lead não encontrado: $id');
    final old = _mockLeads[index];
    final updated = LeadApiModel(
      id: old.id,
      name: name ?? old.name,
      phone: phone ?? old.phone,
      email: email ?? old.email,
      status: status ?? old.status,
      score: score ?? old.score,
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
}
