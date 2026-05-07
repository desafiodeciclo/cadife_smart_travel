import 'package:cadife_smart_travel/features/agency/leads/data/datasources/i_leads_datasource.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/models/lead_api_model.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/client/historico/domain/entities/interacao.dart';

class LeadsRemoteMockDatasource implements ILeadsDatasource {
  final List<LeadApiModel> _mockLeads = [
    LeadApiModel(
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
    LeadApiModel(
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
    LeadApiModel(
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
    LeadApiModel(
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
    LeadApiModel(
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
    LeadApiModel(
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
}
