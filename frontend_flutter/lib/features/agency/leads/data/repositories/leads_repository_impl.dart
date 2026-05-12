import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/datasources/i_leads_datasource.dart';
import 'package:cadife_smart_travel/features/agency/leads/data/models/lead_api_model.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';
import 'package:cadife_smart_travel/features/client/historico/domain/entities/interacao.dart';
import 'package:fpdart/fpdart.dart';

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
    return _mockLeads.firstWhere((l) => l.id == id, orElse: () => throw Exception('Lead não encontrado'));
  }

  @override
  Future<LeadApiModel?> getMyLead() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockLeads.isNotEmpty ? _mockLeads.first : null;
  }

  @override
  Future<LeadApiModel> updateLeadStatus(String id, LeadStatus newStatus) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockLeads.indexWhere((l) => l.id == id);
    if (index == -1) throw Exception('Lead não encontrado: $id');
    
    final updated = _mockLeads[index].copyWith(
      status: newStatus,
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
  Future<void> toggleAya(String leadId, {required bool ativo, String? motivo}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Simula a operação no backend imprimindo no console
    print('LOG: AYA ${ativo ? 'ATIVADA' : 'DESATIVADA'} para Lead $leadId. Motivo: $motivo');
  }

  @override
  Future<LeadApiModel> reassignLead(String id, String consultorNome) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockLeads.indexWhere((l) => l.id == id);
    if (index == -1) throw Exception('Lead não encontrado: $id');
    
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
    if (index == -1) throw Exception('Lead não encontrado: $id');
    
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

/// Adapts [ILeadsDatasource] to [ILeadsRepository].
class LeadsRepositoryImpl implements ILeadsRepository {
  final ILeadsDatasource remoteDatasource;

  LeadsRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, List<Lead>>> getLeads({LeadStatus? status, LeadScore? score}) async {
    try { return Right(await remoteDatasource.getLeads(status: status, score: score)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Lead>> getLeadById(String id) async {
    try { return Right(await remoteDatasource.getLeadById(id)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Lead?>> getMyLead() async {
    try { return Right(await remoteDatasource.getMyLead()); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Briefing>> getBriefing(String leadId) async {
    try { return Right(await remoteDatasource.getBriefing(leadId)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, List<Interacao>>> getInteractions(String leadId) async {
    try { return Right(await remoteDatasource.getInteractions(leadId)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Lead>> createLead(CreateLeadRequest request) async {
    try { return Right(await remoteDatasource.createLead(request)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Lead>> createManualLead(ManualLeadCreate request) async {
    try { return Right(await remoteDatasource.createManualLead(request)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Unit>> toggleAya(String leadId, {required bool ativo, String? motivo}) async {
    try { await remoteDatasource.toggleAya(leadId, ativo: ativo, motivo: motivo); return const Right(unit); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Lead>> updateLeadStatus(String id, LeadStatus newStatus) async {
    try { return Right(await remoteDatasource.updateLeadStatus(id, newStatus)); }
    catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, Lead>> updateLead({
    required String id, String? name, String? phone, String? email,
    LeadStatus? status, LeadScore? score,
  }) async {
    try {
      return Right(await remoteDatasource.updateLead(
        id: id, name: name, phone: phone, email: email, status: status, score: score,
      ));
    } catch (e) { return Left(ServerFailure(e.toString())); }
  }
}