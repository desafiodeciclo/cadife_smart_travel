import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/repositories/i_agenda_repository.dart';
import 'package:cadife_smart_travel/features/agency/agenda/presentation/providers/agenda_provider.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScheduleAppointmentState extends Equatable {
  final DateTime selectedDate;
  final List<TimeSlotModel> availableSlots;
  final TimeSlotModel? selectedSlot;
  final bool isLoading;
  final String? error;

  const ScheduleAppointmentState({
    required this.selectedDate,
    this.availableSlots = const [],
    this.selectedSlot,
    this.isLoading = false,
    this.error,
  });

  ScheduleAppointmentState copyWith({
    DateTime? selectedDate,
    List<TimeSlotModel>? availableSlots,
    TimeSlotModel? selectedSlot,
    bool? isLoading,
    String? error,
  }) {
    return ScheduleAppointmentState(
      selectedDate: selectedDate ?? this.selectedDate,
      availableSlots: availableSlots ?? this.availableSlots,
      selectedSlot: selectedSlot ?? this.selectedSlot,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        selectedDate,
        availableSlots,
        selectedSlot,
        isLoading,
        error,
      ];
}

final scheduleAppointmentProvider = StateNotifierProvider.autoDispose<
    ScheduleAppointmentNotifier, ScheduleAppointmentState>((ref) {
  final IAgendaRepository = ref.watch(IAgendaRepositoryProvider);
  return ScheduleAppointmentNotifier(IAgendaRepository);
});

class ScheduleAppointmentNotifier
    extends StateNotifier<ScheduleAppointmentState> {
  final IAgendaRepository _IAgendaRepository;

  ScheduleAppointmentNotifier(this._IAgendaRepository)
      : super(ScheduleAppointmentState(
            selectedDate: DateTime.now().copyWith(
                hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0))) {
    _fetchSlots(state.selectedDate);
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date, selectedSlot: null);
    _fetchSlots(date);
  }

  void selectSlot(TimeSlotModel slot) {
    if (slot.available) {
      state = state.copyWith(selectedSlot: slot);
    }
  }

  Future<void> _fetchSlots(DateTime date) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final slots = await _IAgendaRepository.getAvailableSlots(date);
      state = state.copyWith(isLoading: false, availableSlots: slots);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> confirmAppointment(String leadId, {String? notes}) async {
    if (state.selectedSlot == null) return false;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final request = CreateAgendaRequest(
        leadId: leadId,
        dateTime: state.selectedSlot!.startTime,
        durationMinutes: 60, // De acordo com a resposta do usuário
        notes: notes,
      );
      await _IAgendaRepository.createAgenda(request);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

