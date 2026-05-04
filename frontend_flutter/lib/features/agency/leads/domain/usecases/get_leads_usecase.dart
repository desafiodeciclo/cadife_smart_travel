import 'package:fpdart/fpdart.dart';
import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';

class GetLeadsUseCase {
  final ILeadsRepository _repository;

  GetLeadsUseCase(this._repository);

  Future<Either<Failure, List<Lead>>> call({LeadStatus? status, LeadScore? score}) {
    return _repository.getLeads(status: status, score: score);
  }
}
