import 'package:cadife_smart_travel/core/ports/agenda_port.dart';
import 'package:cadife_smart_travel/shared/models/agenda_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final agendaPortProvider = Provider<AgendaPort>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

final agendaProvider = AsyncNotifierProvider<AgendaNotifier, List<AgendaModel>>(
  AgendaNotifier.new,
);

class AgendaNotifier extends AsyncNotifier<List<AgendaModel>> {
  @override
  Future<List<AgendaModel>> build() async {
    final agendaPort = ref.watch(agendaPortProvider);
    return agendaPort.getAgenda();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final agendaPort = ref.read(agendaPortProvider);
      return agendaPort.getAgenda();
    });
  }

  Future<void> filterByDate(DateTime date) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final agendaPort = ref.read(agendaPortProvider);
      return agendaPort.getAgenda(date: date);
    });
  }
}
