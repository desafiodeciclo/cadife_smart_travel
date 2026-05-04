import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/lead_port.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final leadDetailProvider =
    AsyncNotifierProvider.family<LeadDetailNotifier, Lead?, String>(
      LeadDetailNotifier.new,
    );

class LeadDetailNotifier extends FamilyAsyncNotifier<Lead?, String> {
  @override
  Future<Lead?> build(String arg) async {
    final leadPort = ref.watch(leadPortProvider);
    return leadPort.getLeadById(arg);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final leadPort = ref.read(leadPortProvider);
      return leadPort.getLeadById(arg);
    });
  }

  Future<void> updateStatus(LeadStatus newStatus) async {
    final leadPort = ref.read(leadPortProvider);
    await leadPort.updateLeadStatus(arg, newStatus);
    await refresh();
  }
}

final leadPortProvider = Provider<LeadPort>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});




