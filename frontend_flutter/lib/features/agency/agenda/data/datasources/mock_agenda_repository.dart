import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/repositories/i_agenda_repository.dart';
import 'package:fpdart/fpdart.dart';

class MockAgendaRepository implements IAgendaRepository {
  final List<Agendamento> _agendas = [];

  @override
  Future<Either<Failure, List<Agendamento>>> getAgenda({DateTime? date}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (date == null) return Right(List.unmodifiable(_agendas));
    final items = _agendas
        .where(
          (a) =>
              a.dateTime.year == date.year &&
              a.dateTime.month == date.month &&
              a.dateTime.day == date.day,
        )
        .toList();
    return Right(items);
  }

  @override
  Future<Either<Failure, Agendamento>> getAgendaById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final agenda = _agendas.firstWhere(
        (a) => a.id == id,
      );
      return Right(agenda);
    } on Exception catch (_) {
      return Left(ServerFailure('Agenda não encontrada: $id'));
    }
  }

  @override
  Future<Either<Failure, Agendamento>> createAgenda(CreateAgendaRequest request) async {
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
    return Right(agenda);
  }

  @override
  Future<Either<Failure, Agendamento>> updateAgenda(String id, UpdateAgendaRequest request) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _agendas.indexWhere((a) => a.id == id);
    if (index == -1) return Left(ServerFailure('Agenda não encontrada: $id'));
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
    return Right(updated);
  }

  @override
  Future<Either<Failure, void>> deleteAgenda(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _agendas.removeWhere((a) => a.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<TimeSlotModel>>> getAvailableSlots(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final slots = List.generate(9, (i) {
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
    return Right(slots);
  }
}





