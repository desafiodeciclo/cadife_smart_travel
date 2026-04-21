import 'package:cadife_smart_travel/core/ports/lead_port.dart';
import 'package:cadife_smart_travel/shared/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final leadDetailProvider =
    AsyncNotifierProvider.family<LeadDetailNotifier, LeadModel?, String>(
  LeadDetailNotifier.new,
);

class LeadDetailNotifier extends FamilyAsyncNotifier<LeadModel?, String> {
  @override
  Future<LeadModel?> build(String arg) async {
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