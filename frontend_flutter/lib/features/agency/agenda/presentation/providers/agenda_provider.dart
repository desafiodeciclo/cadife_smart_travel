import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/repositories/i_agenda_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Override registrado em: lib/core/di/provider_overrides.dart
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
      (failure) => throw failure,
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

  Future<void> blockSlot(
    DateTime slotDateTime, {
    String? notes,
    MotivoBloqueio? motivoBloqueio,
  }) async {
    final agendaRepository = ref.read(agendaRepositoryProvider);
    final result = await agendaRepository.createAgenda(
      CreateAgendaRequest(
        leadId: 'blocked',
        dateTime: slotDateTime,
        durationMinutes: 60,
        notes: notes,
        motivoBloqueio: motivoBloqueio,
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

  Future<bool> editSlot(String id, UpdateAgendaRequest request) async {
    final agendaRepository = ref.read(agendaRepositoryProvider);
    final result = await agendaRepository.updateAgenda(id, request);

    return result.fold(
      (failure) => false,
      (updated) {
        final current = state.whenData((list) => list).valueOrNull ?? [];
        state = AsyncData(
          current.map((a) => a.id == id ? updated : a).toList(),
        );
        return true;
      },
    );
  }

  Future<bool> cancelSlot(String id) async {
    return editSlot(id, const UpdateAgendaRequest(status: 'cancelado'));
  }

  Future<bool> scheduleSlot({
    required String leadId,
    required DateTime dateTime,
    int durationMinutes = 60,
    String? notes,
    String? nomeCliente,
    String? destinoViagem,
  }) async {
    final agendaRepository = ref.read(agendaRepositoryProvider);
    final result = await agendaRepository.createAgenda(
      CreateAgendaRequest(
        leadId: leadId,
        dateTime: dateTime,
        durationMinutes: durationMinutes,
        notes: notes,
        nomeCliente: nomeCliente,
        destinoViagem: destinoViagem,
      ),
    );

    return result.fold(
      (failure) => false,
      (created) {
        final current = state.whenData((list) => list).valueOrNull ?? [];
        state = AsyncData([...current, created]);
        return true;
      },
    );
  }
}
