import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/repositories/agenda_port.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final agendaPortProvider = Provider<AgendaPort>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

/// 0 = visão mensal  |  1 = visão diária
final agendaViewModeProvider = StateProvider<int>((ref) => 0);

/// Data selecionada — controla o mês exibido no calendário e o dia na timeline.
final selectedAgendaDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final agendaProvider = AsyncNotifierProvider<AgendaNotifier, List<Agendamento>>(
  AgendaNotifier.new,
);

class AgendaNotifier extends AsyncNotifier<List<Agendamento>> {
  @override
  Future<List<Agendamento>> build() async {
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

  Future<void> blockSlot(DateTime slotDateTime, {String? notes}) async {
    state = await AsyncValue.guard(() async {
      final agendaPort = ref.read(agendaPortProvider);
      await agendaPort.createAgenda(
        CreateAgendaRequest(
          leadId: 'blocked',
          dateTime: slotDateTime,
          durationMinutes: 60,
          notes: notes,
        ),
      );
      return agendaPort.getAgenda();
    });
  }

  Future<void> unblockSlot(String id) async {
    state = await AsyncValue.guard(() async {
      final agendaPort = ref.read(agendaPortProvider);
      await agendaPort.deleteAgenda(id);
      return agendaPort.getAgenda();
    });
  }
}
