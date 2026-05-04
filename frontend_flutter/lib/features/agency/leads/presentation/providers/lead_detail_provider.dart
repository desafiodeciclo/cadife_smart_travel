import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/leads_usecases_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final leadDetailProvider =
    AsyncNotifierProvider.family<LeadDetailNotifier, Lead?, String>(
      LeadDetailNotifier.new,
    );

class LeadDetailNotifier extends FamilyAsyncNotifier<Lead?, String> {
  @override
  Future<Lead?> build(String arg) async {
    return ref.watch(getLeadByIdUseCaseProvider).call(arg);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(getLeadByIdUseCaseProvider).call(arg);
    });
  }

  Future<void> updateStatus(LeadStatus newStatus) async {
    await ref.read(updateLeadStatusUseCaseProvider).call(arg, newStatus);
    await refresh();
  }
}
