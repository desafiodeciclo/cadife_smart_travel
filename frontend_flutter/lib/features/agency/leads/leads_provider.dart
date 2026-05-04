import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/lead_port.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final leadPortProvider = Provider<LeadPort>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

final leadsProvider = AsyncNotifierProvider<LeadsNotifier, List<Lead>>(
  LeadsNotifier.new,
);

class LeadsNotifier extends AsyncNotifier<List<Lead>> {
  @override
  Future<List<Lead>> build() async {
    final leadPort = ref.watch(leadPortProvider);
    return leadPort.getLeads();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final leadPort = ref.read(leadPortProvider);
      return leadPort.getLeads();
    });
  }

  Future<void> filterByStatus(LeadStatus? status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final leadPort = ref.read(leadPortProvider);
      return leadPort.getLeads(status: status);
    });
  }

  Future<void> filterByScore(LeadScore? score) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final leadPort = ref.read(leadPortProvider);
      return leadPort.getLeads(score: score);
    });
  }

  Future<void> updateStatus(String id, LeadStatus newStatus) async {
    final leadPort = ref.read(leadPortProvider);
    await leadPort.updateLeadStatus(id, newStatus);
    await refresh();
  }
}




