import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';
import 'package:fpdart/fpdart.dart';

class UpdateLeadUseCase {
  final ILeadsRepository _repository;

  UpdateLeadUseCase(this._repository);

  Future<Either<Failure, Lead>> call({
    required String id,
    String? name,
    String? phone,
    String? email,
    LeadStatus? status,
    LeadScore? score,
  }) {
    return _repository.updateLead(
      id: id,
      name: name,
      phone: phone,
      email: email,
      status: status,
      score: score,
    );
  }
}
