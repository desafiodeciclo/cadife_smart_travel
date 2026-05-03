import 'package:cadife_smart_travel/core/ports/agenda_port.dart';
import 'package:cadife_smart_travel/shared/models/agenda_model.dart';

class MockAgendaRepository implements AgendaPort {
  final List<AgendaModel> _agendas = [];

  @override
  Future<List<AgendaModel>> getAgenda({DateTime? date}) async {
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
  Future<AgendaModel> getAgendaById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _agendas.firstWhere(
      (a) => a.id == id,
      orElse: () => throw Exception('Agenda não encontrada: $id'),
    );
  }

  @override
  Future<AgendaModel> createAgenda(CreateAgendaRequest request) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final agenda = AgendaModel(
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
  Future<AgendaModel> updateAgenda(String id, UpdateAgendaRequest request) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _agendas.indexWhere((a) => a.id == id);
    if (index == -1) throw Exception('Agenda não encontrada: $id');
    final old = _agendas[index];
    final updated = AgendaModel(
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
