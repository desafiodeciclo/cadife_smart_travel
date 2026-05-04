import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/repositories/i_agenda_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final IAgendaRepositoryProvider = Provider<IAgendaRepository>((ref) {
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
    final repo = ref.watch(IAgendaRepositoryProvider);
    final result = await repo.getAgenda();
    return result.fold(
      (failure) => throw failure,
      (agenda) => agenda,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final repo = ref.read(IAgendaRepositoryProvider);
    final result = await repo.getAgenda();
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (agenda) => AsyncData(agenda),
    );
  }

  Future<void> filterByDate(DateTime date) async {
    state = const AsyncLoading();
    final repo = ref.read(IAgendaRepositoryProvider);
    final result = await repo.getAgenda(date: date);
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (agenda) => AsyncData(agenda),
    );
  }

  Future<void> blockSlot(DateTime slotDateTime, {String? notes}) async {
    final repo = ref.read(IAgendaRepositoryProvider);
    final result = await repo.createAgenda(
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
        final refreshResult = await repo.getAgenda();
        return refreshResult.fold(
          (f) => AsyncError(f, StackTrace.current),
          (a) => AsyncData(a),
        );
      },
    );
  }

  Future<void> unblockSlot(String id) async {
    final repo = ref.read(IAgendaRepositoryProvider);
    final result = await repo.deleteAgenda(id);
    
    state = await result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) async {
        final refreshResult = await repo.getAgenda();
        return refreshResult.fold(
          (f) => AsyncError(f, StackTrace.current),
          (a) => AsyncData(a),
        );
      },
    );
  }
}

