import 'package:fpdart/fpdart.dart';
import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';

class GetBriefingUseCase {
  final ILeadsRepository _repository;

  GetBriefingUseCase(this._repository);

  Future<Either<Failure, Briefing>> call(String leadId) {
    return _repository.getBriefing(leadId);
  }
}
