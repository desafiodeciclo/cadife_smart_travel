import 'package:cadife_smart_travel/core/ports/lead_port.dart';
import 'package:cadife_smart_travel/shared/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final interactionsPortProvider = Provider<LeadPort>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

final interactionsProvider =
    AsyncNotifierProvider.family<
      InteractionsNotifier,
      List<InteractionModel>,
      String
    >(InteractionsNotifier.new);

class InteractionsNotifier
    extends FamilyAsyncNotifier<List<InteractionModel>, String> {
  @override
  Future<List<InteractionModel>> build(String arg) async {
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
