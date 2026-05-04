import 'package:fpdart/fpdart.dart';
import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';

class UpdateLeadStatusUseCase {
  final ILeadsRepository _repository;

  UpdateLeadStatusUseCase(this._repository);

  Future<Either<Failure, Lead>> call(String id, LeadStatus newStatus) {
    return _repository.updateLeadStatus(id, newStatus);
  }
}
