import 'package:fpdart/fpdart.dart';
import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/client/historico/domain/entities/interacao.dart';

abstract class ILeadsRepository {
  Future<Either<Failure, List<Lead>>> getLeads({LeadStatus? status, LeadScore? score});
  Future<Either<Failure, Lead>> getLeadById(String id);
  Future<Either<Failure, Lead?>> getMyLead();
  Future<Either<Failure, Lead>> updateLeadStatus(String id, LeadStatus newStatus);
  Future<Either<Failure, Briefing>> getBriefing(String leadId);
  Future<Either<Failure, List<Interacao>>> getInteractions(String leadId);
  Future<Either<Failure, Lead>> createLead(CreateLeadRequest request);
}
