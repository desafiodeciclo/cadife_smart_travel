import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';

class GetLeadByIdUseCase {
  final ILeadsRepository _repository;

  GetLeadByIdUseCase(this._repository);

  Future<Lead> call(String id) {
    return _repository.getLeadById(id);
  }
}
