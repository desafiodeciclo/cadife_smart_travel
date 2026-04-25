import 'package:cadife_smart_travel/shared/models/briefing_model.dart';
import 'package:cadife_smart_travel/shared/models/interaction_model.dart';
import 'package:cadife_smart_travel/shared/models/lead_model.dart';

abstract class LeadPort {
  Future<List<LeadModel>> getLeads({LeadStatus? status, LeadScore? score});
  Future<LeadModel> getLeadById(String id);
  Future<LeadModel> updateLeadStatus(String id, LeadStatus newStatus);
  Future<BriefingModel> getBriefing(String leadId);
  Future<List<InteractionModel>> getInteractions(String leadId);
  Future<LeadModel> createLead(CreateLeadRequest request);
}
