import 'package:cadife_smart_travel/features/agency/leads/data/providers/leads_data_providers.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/usecases/get_briefing_usecase.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/usecases/get_lead_by_id_usecase.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/usecases/get_leads_usecase.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/usecases/update_lead_status_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final getLeadsUseCaseProvider = Provider<GetLeadsUseCase>((ref) {
  return GetLeadsUseCase(ref.watch(leadsRepositoryProvider));
});

final getLeadByIdUseCaseProvider = Provider<GetLeadByIdUseCase>((ref) {
  return GetLeadByIdUseCase(ref.watch(leadsRepositoryProvider));
});

final updateLeadStatusUseCaseProvider = Provider<UpdateLeadStatusUseCase>((ref) {
  return UpdateLeadStatusUseCase(ref.watch(leadsRepositoryProvider));
});

final getBriefingUseCaseProvider = Provider<GetBriefingUseCase>((ref) {
  return GetBriefingUseCase(ref.watch(leadsRepositoryProvider));
});
