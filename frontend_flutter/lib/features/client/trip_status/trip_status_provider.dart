import 'package:cadife_smart_travel/core/ports/lead_port.dart';
import 'package:cadife_smart_travel/shared/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clientLeadPortProvider = Provider<LeadPort>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

final clientTripStatusProvider =
    AsyncNotifierProvider.family<ClientTripStatusNotifier, LeadModel?, String>(
  ClientTripStatusNotifier.new,
);

class ClientTripStatusNotifier extends FamilyAsyncNotifier<LeadModel?, String> {
  @override
  Future<LeadModel?> build(String arg) async {
    final leadPort = ref.watch(clientLeadPortProvider);
    return leadPort.getLeadById(arg);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final leadPort = ref.read(clientLeadPortProvider);
      return leadPort.getLeadById(arg);
    });
  }
}