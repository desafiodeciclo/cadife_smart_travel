import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/repositories/i_agenda_repository.dart';
import 'package:fpdart/fpdart.dart';

class MockAgendaRepository implements IAgendaRepository {
  MockAgendaRepository() {
    _seedMockData();
  }

  final List<Agendamento> _agendas = [];

  void _seedMockData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _agendas.addAll([
      Agendamento(
        id: 'mock-1',
        leadId: 'lead-001',
        consultorId: 'consultor-1',
        dateTime: today.copyWith(hour: 9),
        durationMinutes: 60,
        status: 'agendado',
        nomeCliente: 'Ana Souza',
        destinoViagem: 'Cancún, México',
        notes: 'Família de 4 pessoas, viagem de férias',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Agendamento(
        id: 'mock-2',
        leadId: 'lead-002',
        consultorId: 'consultor-1',
        dateTime: today.copyWith(hour: 11),
        durationMinutes: 90,
        status: 'pendente',
        nomeCliente: 'Carlos Mendes',
        destinoViagem: 'Paris, França',
        notes: 'Lua de mel, busca experiências românticas',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Agendamento(
        id: 'mock-3',
        leadId: 'blocked',
        consultorId: 'consultor-1',
        dateTime: today.copyWith(hour: 13),
        durationMinutes: 60,
        status: 'bloqueado',
        motivoBloqueio: MotivoBloqueio.pausa,
        notes: 'Pausa para almoço',
        createdAt: now,
      ),
      Agendamento(
        id: 'mock-4',
        leadId: 'lead-003',
        consultorId: 'consultor-1',
        dateTime: today.copyWith(hour: 15),
        durationMinutes: 60,
        status: 'agendado',
        nomeCliente: 'Julia Ferreira',
        destinoViagem: 'Tóquio, Japão',
        notes: 'Grupo de amigos, 5 pessoas',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      // Yesterday
      Agendamento(
        id: 'mock-5',
        leadId: 'lead-004',
        consultorId: 'consultor-1',
        dateTime: today.subtract(const Duration(days: 1)).copyWith(hour: 10),
        durationMinutes: 60,
        status: 'realizado',
        nomeCliente: 'Pedro Alves',
        destinoViagem: 'Lisboa, Portugal',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      // Tomorrow
      Agendamento(
        id: 'mock-6',
        leadId: 'lead-005',
        consultorId: 'consultor-1',
        dateTime: today.add(const Duration(days: 1)).copyWith(hour: 10),
        durationMinutes: 60,
        status: 'agendado',
        nomeCliente: 'Mariana Costa',
        destinoViagem: 'Maldivas',
        createdAt: now,
      ),
      Agendamento(
        id: 'mock-7',
        leadId: 'lead-006',
        consultorId: 'consultor-1',
        dateTime: today.add(const Duration(days: 1)).copyWith(hour: 14),
        durationMinutes: 90,
        status: 'pendente',
        nomeCliente: 'Roberto Lima',
        destinoViagem: 'Nova York, EUA',
        createdAt: now,
      ),
      // Day after tomorrow
      Agendamento(
        id: 'mock-8',
        leadId: 'lead-007',
        consultorId: 'consultor-1',
        dateTime: today.add(const Duration(days: 2)).copyWith(hour: 9),
        durationMinutes: 60,
        status: 'agendado',
        nomeCliente: 'Fernanda Rocha',
        destinoViagem: 'Santorini, Grécia',
        createdAt: now,
      ),
      Agendamento(
        id: 'mock-9',
        leadId: 'lead-008',
        consultorId: 'consultor-1',
        dateTime: today.add(const Duration(days: 2)).copyWith(hour: 11),
        durationMinutes: 60,
        status: 'agendado',
        nomeCliente: 'Bruno Martins',
        destinoViagem: 'Buenos Aires, Argentina',
        createdAt: now,
      ),
      Agendamento(
        id: 'mock-10',
        leadId: 'lead-009',
        consultorId: 'consultor-1',
        dateTime: today.add(const Duration(days: 2)).copyWith(hour: 14),
        durationMinutes: 60,
        status: 'agendado',
        nomeCliente: 'Camila Santos',
        destinoViagem: 'Dubai, EAU',
        createdAt: now,
      ),
    ]);
  }

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
      final agenda = _agendas.firstWhere((a) => a.id == id);
      return Right(agenda);
    } on StateError catch (_) {
      return Left(ServerFailure('Agenda não encontrada: $id'));
    }
  }

  @override
  Future<Either<Failure, Agendamento>> createAgenda(
    CreateAgendaRequest request,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Validate time range 09:00–16:00
    final hour = request.dateTime.hour;
    if (hour < 9 || hour >= 16) {
      return const Left(
        ServerFailure('Agendamento fora do horário permitido (09:00–16:00)'),
      );
    }

    // Check max 6 per day
    final sameDay = _agendas
        .where(
          (a) =>
              a.dateTime.year == request.dateTime.year &&
              a.dateTime.month == request.dateTime.month &&
              a.dateTime.day == request.dateTime.day &&
              a.status != 'cancelado' &&
              a.status != 'bloqueado',
        )
        .length;
    if (sameDay >= 6) {
      return const Left(
        ServerFailure('Limite de 6 agendamentos por dia atingido'),
      );
    }

    // Check for slot conflict
    final conflict = _agendas.any(
      (a) =>
          a.dateTime.year == request.dateTime.year &&
          a.dateTime.month == request.dateTime.month &&
          a.dateTime.day == request.dateTime.day &&
          a.dateTime.hour == request.dateTime.hour &&
          a.status != 'cancelado',
    );
    if (conflict) {
      return const Left(ConflictFailure('Horário já ocupado'));
    }

    final isBloqueio = request.leadId == 'blocked';
    final agenda = Agendamento(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      leadId: request.leadId,
      consultorId: 'mock-consultor-id',
      dateTime: request.dateTime,
      durationMinutes: request.durationMinutes,
      status: isBloqueio ? 'bloqueado' : 'agendado',
      nomeCliente: request.nomeCliente,
      destinoViagem: request.destinoViagem,
      motivoBloqueio: request.motivoBloqueio,
      notes: request.notes,
      createdAt: DateTime.now(),
    );
    _agendas.add(agenda);
    return Right(agenda);
  }

  @override
  Future<Either<Failure, Agendamento>> updateAgenda(
    String id,
    UpdateAgendaRequest request,
  ) async {
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
      nomeCliente: old.nomeCliente,
      destinoViagem: old.destinoViagem,
      motivoBloqueio: old.motivoBloqueio,
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
  Future<Either<Failure, List<TimeSlotModel>>> getAvailableSlots(
    DateTime date,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Slots from 09:00 to 16:00 (8 slots)
    final slots = List.generate(8, (i) {
      final hour = 9 + i;
      final start = DateTime(date.year, date.month, date.day, hour);
      final isBooked = _agendas.any(
        (a) =>
            a.dateTime.year == date.year &&
            a.dateTime.month == date.month &&
            a.dateTime.day == date.day &&
            a.dateTime.hour == hour &&
            a.status != 'cancelado',
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
