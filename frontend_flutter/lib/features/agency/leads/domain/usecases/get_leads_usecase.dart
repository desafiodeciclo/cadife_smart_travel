import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/leads_list_response.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetLeadsUseCase {
  final ILeadsRepository _repository;
  GetLeadsUseCase(this._repository);

  Future<Either<Failure, LeadsListResponse>> call({
    int? page,
    int? size,
    String? status,
    String? score,
    String? search,
  }) async {
    return await _repository.getLeads(
      page: page,
      size: size,
      status: status,
      score: score,
      search: search,
    );
  }
}
