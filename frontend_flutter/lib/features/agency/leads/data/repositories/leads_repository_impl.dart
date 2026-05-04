import 'package:cadife_smart_travel/features/agency/leads/data/datasources/i_leads_datasource.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';
import 'package:cadife_smart_travel/features/client/historico/domain/entities/interacao.dart';

class LeadsRepositoryImpl implements ILeadsRepository {
  final ILeadsDatasource _remoteDatasource;

  LeadsRepositoryImpl({
    required ILeadsDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  @override
  Future<List<Lead>> getLeads({LeadStatus? status, LeadScore? score}) {
    return _remoteDatasource.getLeads(status: status, score: score);
  }

  @override
  Future<Lead> getLeadById(String id) {
    return _remoteDatasource.getLeadById(id);
  }

  @override
  Future<Lead?> getMyLead() {
    return _remoteDatasource.getMyLead();
  }

  @override
  Future<Lead> updateLeadStatus(String id, LeadStatus newStatus) {
    return _remoteDatasource.updateLeadStatus(id, newStatus);
  }

  @override
  Future<Briefing> getBriefing(String leadId) {
    return _remoteDatasource.getBriefing(leadId);
  }

  @override
  Future<List<Interacao>> getInteractions(String leadId) {
    return _remoteDatasource.getInteractions(leadId);
  }

  @override
  Future<Lead> createLead(CreateLeadRequest request) {
    return _remoteDatasource.createLead(request);
  }
}
