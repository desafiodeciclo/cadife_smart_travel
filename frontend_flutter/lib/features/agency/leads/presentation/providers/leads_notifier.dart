import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/leads_usecases_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeadsNotifier extends AsyncNotifier<List<Lead>> {
  @override
  Future<List<Lead>> build() async {
    return ref.watch(getLeadsUseCaseProvider).call();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(getLeadsUseCaseProvider).call();
    });
  }

  Future<void> filterByStatus(LeadStatus? status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(getLeadsUseCaseProvider).call(status: status);
    });
  }

  Future<void> filterByScore(LeadScore? score) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(getLeadsUseCaseProvider).call(score: score);
    });
  }

  Future<void> updateStatus(String id, LeadStatus newStatus) async {
    await ref.read(updateLeadStatusUseCaseProvider).call(id, newStatus);
    await refresh();
  }
}

final leadsNotifierProvider = AsyncNotifierProvider<LeadsNotifier, List<Lead>>(
  LeadsNotifier.new,
);
