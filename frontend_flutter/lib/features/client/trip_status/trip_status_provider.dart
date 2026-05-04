import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/lead_port.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clientLeadPortProvider = Provider<LeadPort>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

final clientTripStatusProvider =
    AsyncNotifierProvider.family<ClientTripStatusNotifier, Lead?, String>(
      ClientTripStatusNotifier.new,
    );

class ClientTripStatusNotifier extends FamilyAsyncNotifier<Lead?, String> {
  @override
  Future<Lead?> build(String arg) async {
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




