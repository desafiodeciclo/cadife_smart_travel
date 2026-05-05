import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/repositories/i_agenda_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final agendaRepositoryProvider = Provider<IAgendaRepository>((ref) {
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
    final agendaRepository = ref.watch(agendaRepositoryProvider);
    final result = await agendaRepository.getAgenda();
    return result.fold(
      (failure) => throw failure, // ignore: only_throw_errors
      (agenda) => agenda,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final agendaRepository = ref.read(agendaRepositoryProvider);
    final result = await agendaRepository.getAgenda();
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      AsyncData.new,
    );
  }

  Future<void> filterByDate(DateTime date) async {
    state = const AsyncLoading();
    final agendaRepository = ref.read(agendaRepositoryProvider);
    final result = await agendaRepository.getAgenda(date: date);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      AsyncData.new,
    );
  }

  Future<void> blockSlot(DateTime slotDateTime, {String? notes}) async {
    final agendaRepository = ref.read(agendaRepositoryProvider);
    final result = await agendaRepository.createAgenda(
      CreateAgendaRequest(
        leadId: 'blocked',
        dateTime: slotDateTime,
        durationMinutes: 60,
        notes: notes,
      ),
    );
    
    state = await result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) async {
        final refreshResult = await agendaRepository.getAgenda();
        return refreshResult.fold(
          (f) => AsyncError(f, StackTrace.current),
          AsyncData.new,
        );
      },
    );
  }

  Future<void> unblockSlot(String id) async {
    final agendaRepository = ref.read(agendaRepositoryProvider);
    final result = await agendaRepository.deleteAgenda(id);
    
    state = await result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) async {
        final refreshResult = await agendaRepository.getAgenda();
        return refreshResult.fold(
          (f) => AsyncError(f, StackTrace.current),
          AsyncData.new,
        );
      },
    );
  }
}
