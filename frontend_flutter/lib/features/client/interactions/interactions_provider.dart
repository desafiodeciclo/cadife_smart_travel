import 'package:cadife_smart_travel/features/agency/leads/domain/entities/interacao.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/lead_port.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final interactionsPortProvider = Provider<LeadPort>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

final interactionsProvider =
    AsyncNotifierProvider.family<
      InteractionsNotifier,
      List<Interacao>,
      String
    >(InteractionsNotifier.new);

class InteractionsNotifier
    extends FamilyAsyncNotifier<List<Interacao>, String> {
  @override
  Future<List<Interacao>> build(String arg) async {
    final leadPort = ref.watch(interactionsPortProvider);
    return leadPort.getInteractions(arg);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final leadPort = ref.read(interactionsPortProvider);
      return leadPort.getInteractions(arg);
    });
  }
}

// Ã¢â€â‚¬Ã¢â€â‚¬ Client-facing provider Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
// Resolves the active lead automatically and fetches its interactions,
// so HistoricoScreen does not need to know the lead ID.

final clientInteractionsProvider = AsyncNotifierProvider<
    ClientInteractionsNotifier, List<Interacao>>(
  ClientInteractionsNotifier.new,
);

class ClientInteractionsNotifier
    extends AsyncNotifier<List<Interacao>> {
  @override
  Future<List<Interacao>> build() async {
    final leadPort = ref.watch(interactionsPortProvider);
    final lead = await leadPort.getMyLead();
    if (lead == null) return [];
    return leadPort.getInteractions(lead.id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final leadPort = ref.read(interactionsPortProvider);
      final lead = await leadPort.getMyLead();
      if (lead == null) return <Interacao>[];
      return leadPort.getInteractions(lead.id);
    });
  }
}




