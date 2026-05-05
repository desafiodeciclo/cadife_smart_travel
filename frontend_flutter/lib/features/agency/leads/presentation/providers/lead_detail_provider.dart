import 'package:cadife_smart_travel/core/analytics/analytics_service.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
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
    final result = await ref.watch(getLeadByIdUseCaseProvider).call(arg);
    return result.fold(
      (failure) => throw failure,
      (lead) => lead,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await ref.read(getLeadByIdUseCaseProvider).call(arg);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      AsyncData.new,
    );
  }

  Future<void> updateStatus(LeadStatus newStatus) async {
    final result = await ref.read(updateLeadStatusUseCaseProvider).call(arg, newStatus);
    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (_) {
        final analytics = sl<AnalyticsService>();
        analytics.logEvent('lead_status_updated', parameters: {
          'lead_id': arg,
          'new_status': newStatus.name,
        });

        if (newStatus == LeadStatus.qualificado) {
          final lead = state.value;
          analytics.logEvent('lead_qualified', parameters: {
            'lead_id': arg,
            'score': lead?.score.name,
            'time_to_qualify_seconds': lead?.createdAt != null 
                ? DateTime.now().difference(lead!.createdAt!).inSeconds 
                : null,
          });
        }

        refresh();
      },
    );
  }
}
