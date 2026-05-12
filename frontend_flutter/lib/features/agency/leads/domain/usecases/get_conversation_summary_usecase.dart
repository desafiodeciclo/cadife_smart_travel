import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/conversation_summary.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/i_leads_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetConversationSummaryUseCase {
  final ILeadsRepository _repository;

  GetConversationSummaryUseCase(this._repository);

  Future<Either<Failure, ConversationSummary?>> call(String leadId) {
    return _repository.getConversationSummary(leadId);
  }
}
