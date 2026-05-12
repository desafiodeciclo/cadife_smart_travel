import 'package:cadife_smart_travel/features/agency/leads/data/providers/leads_data_providers.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/usecases/create_manual_lead_usecase.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/usecases/get_briefing_usecase.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/usecases/get_conversation_summary_usecase.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/usecases/get_lead_by_id_usecase.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/usecases/get_leads_usecase.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/usecases/toggle_aya_usecase.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/usecases/update_lead_status_usecase.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/usecases/update_lead_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final getLeadsUseCaseProvider = Provider<GetLeadsUseCase>((ref) {
  final repository = ref.watch(leadsRepositoryProvider);
  return GetLeadsUseCase(repository);
});

final getLeadByIdUseCaseProvider = Provider<GetLeadByIdUseCase>((ref) {
  final repository = ref.watch(leadsRepositoryProvider);
  return GetLeadByIdUseCase(repository);
});

final getBriefingUseCaseProvider = Provider<GetBriefingUseCase>((ref) {
  final repository = ref.watch(leadsRepositoryProvider);
  return GetBriefingUseCase(repository);
});

final getConversationSummaryUseCaseProvider = Provider<GetConversationSummaryUseCase>((ref) {
  final repository = ref.watch(leadsRepositoryProvider);
  return GetConversationSummaryUseCase(repository);
});

final createManualLeadUseCaseProvider = Provider<CreateManualLeadUseCase>((ref) {
  final repository = ref.watch(leadsRepositoryProvider);
  return CreateManualLeadUseCase(repository);
});

final toggleAyaUseCaseProvider = Provider<ToggleAyaUseCase>((ref) {
  final repository = ref.watch(leadsRepositoryProvider);
  return ToggleAyaUseCase(repository);
});

final updateLeadStatusUseCaseProvider = Provider<UpdateLeadStatusUseCase>((ref) {
  final repository = ref.watch(leadsRepositoryProvider);
  return UpdateLeadStatusUseCase(repository);
});

final updateLeadUseCaseProvider = Provider<UpdateLeadUseCase>((ref) {
  final repository = ref.watch(leadsRepositoryProvider);
  return UpdateLeadUseCase(repository);
});