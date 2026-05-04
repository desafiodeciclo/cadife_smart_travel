import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/repositories/i_agenda_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final IAgendaRepositoryProvider = Provider<IAgendaRepository>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

/// 0 = visÃ£o mensal  |  1 = visÃ£o diÃ¡ria
final agendaViewModeProvider = StateProvider<int>((ref) => 0);

/// Data selecionada â€” controla o mÃªs exibido no calendÃ¡rio e o dia na timeline.
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
    final IAgendaRepository = ref.watch(IAgendaRepositoryProvider);
    return IAgendaRepository.getAgenda();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final IAgendaRepository = ref.read(IAgendaRepositoryProvider);
      return IAgendaRepository.getAgenda();
    });
  }

  Future<void> filterByDate(DateTime date) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final IAgendaRepository = ref.read(IAgendaRepositoryProvider);
      return IAgendaRepository.getAgenda(date: date);
    });
  }

  Future<void> blockSlot(DateTime slotDateTime, {String? notes}) async {
    state = await AsyncValue.guard(() async {
      final IAgendaRepository = ref.read(IAgendaRepositoryProvider);
      await IAgendaRepository.createAgenda(
        CreateAgendaRequest(
          leadId: 'blocked',
          dateTime: slotDateTime,
          durationMinutes: 60,
          notes: notes,
        ),
      );
      return IAgendaRepository.getAgenda();
    });
  }

  Future<void> unblockSlot(String id) async {
    state = await AsyncValue.guard(() async {
      final IAgendaRepository = ref.read(IAgendaRepositoryProvider);
      await IAgendaRepository.deleteAgenda(id);
      return IAgendaRepository.getAgenda();
    });
  }
}





