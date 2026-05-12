import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';
import 'package:fpdart/fpdart.dart';

class ToggleAyaUseCase {
  final ILeadsRepository _repository;

  ToggleAyaUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String leadId, {required bool ativo, String? motivo}) {
    return _repository.toggleAya(leadId, ativo: ativo, motivo: motivo);
  }
}
