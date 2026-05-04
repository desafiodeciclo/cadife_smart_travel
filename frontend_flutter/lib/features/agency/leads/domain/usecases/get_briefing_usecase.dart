import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';

class GetBriefingUseCase {
  final ILeadsRepository _repository;

  GetBriefingUseCase(this._repository);

  Future<Briefing> call(String leadId) {
    return _repository.getBriefing(leadId);
  }
}
