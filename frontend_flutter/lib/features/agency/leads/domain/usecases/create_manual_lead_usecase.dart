import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';
import 'package:fpdart/fpdart.dart';

class CreateManualLeadUseCase {
  final ILeadsRepository _repository;

  CreateManualLeadUseCase(this._repository);

  Future<Either<Failure, Lead>> call(ManualLeadCreate request) async {
    return await _repository.createManualLead(request);
  }
}
