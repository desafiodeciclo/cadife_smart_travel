import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/client/historico/domain/entities/interacao.dart';

abstract class ILeadsRepository {
  Future<List<Lead>> getLeads({LeadStatus? status, LeadScore? score});
  Future<Lead> getLeadById(String id);
  Future<Lead?> getMyLead();
  Future<Lead> updateLeadStatus(String id, LeadStatus newStatus);
  Future<Briefing> getBriefing(String leadId);
  Future<List<Interacao>> getInteractions(String leadId);
  Future<Lead> createLead(CreateLeadRequest request);
}
