import 'package:cadife_smart_travel/features/agency/leads/data/models/lead_api_model.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/client/historico/domain/entities/interacao.dart';

abstract class ILeadsDatasource {
  Future<List<LeadApiModel>> getLeads({LeadStatus? status, LeadScore? score});
  Future<LeadApiModel> getLeadById(String id);
  Future<LeadApiModel?> getMyLead();
  Future<LeadApiModel> updateLeadStatus(String id, LeadStatus newStatus);
  Future<Briefing> getBriefing(String leadId);
  Future<List<Interacao>> getInteractions(String leadId);
  Future<LeadApiModel> createLead(CreateLeadRequest request);
}
