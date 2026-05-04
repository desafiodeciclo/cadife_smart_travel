import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/repositories/agenda_port.dart';

class MockAgendaRepository implements AgendaPort {
  final List<Agendamento> _agendas = [];

  @override
  Future<List<Agendamento>> getAgenda({DateTime? date}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (date == null) return List.unmodifiable(_agendas);
    return _agendas
        .where(
          (a) =>
              a.dateTime.year == date.year &&
              a.dateTime.month == date.month &&
              a.dateTime.day == date.day,
        )
        .toList();
  }

  @override
  Future<Agendamento> getAgendaById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _agendas.firstWhere(
      (a) => a.id == id,
      orElse: () => throw Exception('Agenda nÃƒÂ£o encontrada: $id'),
    );
  }

  @override
  Future<Agendamento> createAgenda(CreateAgendaRequest request) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final agenda = Agendamento(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      leadId: request.leadId,
      consultorId: 'mock-consultor-id',
      dateTime: request.dateTime,
      durationMinutes: request.durationMinutes,
      status: 'agendado',
      notes: request.notes,
      createdAt: DateTime.now(),
    );
    _agendas.add(agenda);
    return agenda;
  }

  @override
  Future<Agendamento> updateAgenda(String id, UpdateAgendaRequest request) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _agendas.indexWhere((a) => a.id == id);
    if (index == -1) throw Exception('Agenda nÃƒÂ£o encontrada: $id');
    final old = _agendas[index];
    final updated = Agendamento(
      id: old.id,
      leadId: old.leadId,
      consultorId: old.consultorId,
      dateTime: request.dateTime ?? old.dateTime,
      durationMinutes: request.durationMinutes ?? old.durationMinutes,
      status: request.status ?? old.status,
      notes: request.notes ?? old.notes,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    _agendas[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteAgenda(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _agendas.removeWhere((a) => a.id == id);
  }

  @override
  Future<List<TimeSlotModel>> getAvailableSlots(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.generate(9, (i) {
      final hour = 9 + i;
      final start = DateTime(date.year, date.month, date.day, hour);
      final isBooked = _agendas.any(
        (a) =>
            a.dateTime.year == date.year &&
            a.dateTime.month == date.month &&
            a.dateTime.day == date.day &&
            a.dateTime.hour == hour,
      );
      return TimeSlotModel(
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
        available: !isBooked,
      );
    });
  }
}




