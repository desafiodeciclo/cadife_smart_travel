import 'package:cadife_smart_travel/features/agency/leads/domain/usecases/get_lead_by_id_usecase.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/usecases/update_lead_status_usecase.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/usecases/toggle_aya_usecase.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/usecases/update_lead_usecase.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/usecases/get_leads_usecase.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/usecases/create_manual_lead_usecase.dart';
import 'package:cadife_smart_travel/providers/leads_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final getLeadByIdUseCaseProvider = Provider((ref) {
  final repository = ref.watch(leadsRepositoryProvider);
  return GetLeadByIdUseCase(repository);
});

final updateLeadStatusUseCaseProvider = Provider((ref) {
  final repository = ref.watch(leadsRepositoryProvider);
  return UpdateLeadStatusUseCase(repository);
});

final toggleAyaUseCaseProvider = Provider((ref) {
  final repository = ref.watch(leadsRepositoryProvider);
  return ToggleAyaUseCase(repository);
});

final updateLeadUseCaseProvider = Provider((ref) {
  final repository = ref.watch(leadsRepositoryProvider);
  return UpdateLeadUseCase(repository);
});

final getLeadsUseCaseProvider = Provider((ref) {
  final repository = ref.watch(leadsRepositoryProvider);
  return GetLeadsUseCase(repository);
});

final createManualLeadUseCaseProvider = Provider((ref) {
  final repository = ref.watch(leadsRepositoryProvider);
  return CreateManualLeadUseCase(repository);
});