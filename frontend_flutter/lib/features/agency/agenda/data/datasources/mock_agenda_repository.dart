import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/repositories/i_agenda_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Dados alinhados com backend/scripts/db/seeds/02_leads.py e 04_agendamentos.py.
/// Usa datas relativas ao dia atual para manter o calendário funcional em dev.
class MockAgendaRepository implements IAgendaRepository {
  MockAgendaRepository() {
    _seedMockData();
  }

  final List<Agendamento> _agendas = [];

  void _seedMockData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _agendas.addAll([
      // Hoje — leads dos seeds
      Agendamento(
        id: 'mock-1',
        leadId: 'rafael-mendes',
        consultorId: 'jakeline-lima',
        dateTime: today.copyWith(hour: 9),
        durationMinutes: 60,
        status: 'agendado',
        nomeCliente: 'Rafael Mendes',
        destinoViagem: 'Nova York, EUA',
        notes: 'Família de 4 pessoas (2 adultos + 2 crianças). Curadoria principal.',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Agendamento(
        id: 'mock-2',
        leadId: 'camila-santos',
        consultorId: 'daniela-costa',
        dateTime: today.copyWith(hour: 11),
        durationMinutes: 90,
        status: 'pendente',
        nomeCliente: 'Camila Santos',
        destinoViagem: 'Tóquio, Japão',
        notes: 'Grupo de 4 amigas. Atenção: alergia a frutos do mar.',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Agendamento(
        id: 'mock-3',
        leadId: 'blocked',
        consultorId: 'daniela-costa',
        dateTime: today.copyWith(hour: 13),
        durationMinutes: 60,
        status: 'bloqueado',
        motivoBloqueio: MotivoBloqueio.pausa,
        notes: 'Pausa para almoço',
        createdAt: now,
      ),
      Agendamento(
        id: 'mock-4',
        leadId: 'ana-luiza-gomes',
        consultorId: 'marcos-andrade',
        dateTime: today.copyWith(hour: 15),
        durationMinutes: 60,
        status: 'agendado',
        nomeCliente: 'Ana Luiza Gomes',
        destinoViagem: 'Maldivas',
        notes: 'Lua de mel. Cliente muito animada com villa overwater.',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      // Ontem — lead realizado
      Agendamento(
        id: 'mock-5',
        leadId: 'otavio-grotto',
        consultorId: 'daniela-costa',
        dateTime: today.subtract(const Duration(days: 1)).copyWith(hour: 10),
        durationMinutes: 60,
        status: 'realizado',
        nomeCliente: 'Otávio Grotto',
        destinoViagem: 'Paris, França',
        notes: 'Aniversário de casamento. Roteiro finalizado e aprovado.',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      // Amanhã
      Agendamento(
        id: 'mock-6',
        leadId: 'joao-silva',
        consultorId: 'jakeline-lima',
        dateTime: today.add(const Duration(days: 1)).copyWith(hour: 10),
        durationMinutes: 60,
        status: 'agendado',
        nomeCliente: 'João Silva',
        destinoViagem: 'Europa (Portugal ou Espanha)',
        notes: 'Primeiro contato. Ainda definindo destino.',
        createdAt: now,
      ),
      Agendamento(
        id: 'mock-7',
        leadId: 'maria-oliveira',
        consultorId: 'diego-costa',
        dateTime: today.add(const Duration(days: 1)).copyWith(hour: 14),
        durationMinutes: 90,
        status: 'pendente',
        nomeCliente: 'Maria Oliveira',
        destinoViagem: 'Cancún, México',
        notes: 'Casal. Verificar passaportes antes da reunião.',
        createdAt: now,
      ),
      // Depois de amanhã
      Agendamento(
        id: 'mock-8',
        leadId: 'fernanda-castro',
        consultorId: 'diego-costa',
        dateTime: today.add(const Duration(days: 2)).copyWith(hour: 9),
        durationMinutes: 60,
        status: 'agendado',
        nomeCliente: 'Fernanda Castro',
        destinoViagem: 'Maldivas',
        notes: 'Lead qualificado. Aguardando proposta.',
        createdAt: now,
      ),
      Agendamento(
        id: 'mock-9',
        leadId: 'rafael-mendes',
        consultorId: 'jakeline-lima',
        dateTime: today.add(const Duration(days: 2)).copyWith(hour: 11),
        durationMinutes: 60,
        status: 'agendado',
        nomeCliente: 'Rafael Mendes',
        destinoViagem: 'Nova York, EUA',
        notes: 'Follow-up — confirmar visto americano.',
        createdAt: now,
      ),
      Agendamento(
        id: 'mock-10',
        leadId: 'ana-luiza-gomes',
        consultorId: 'marcos-andrade',
        dateTime: today.add(const Duration(days: 2)).copyWith(hour: 14),
        durationMinutes: 60,
        status: 'agendado',
        nomeCliente: 'Ana Luiza Gomes',
        destinoViagem: 'Maldivas',
        notes: 'Apresentação final do pacote curado.',
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

    final hour = request.dateTime.hour;
    if (hour < 9 || hour >= 16) {
      return const Left(
        ServerFailure('Agendamento fora do horário permitido (09:00–16:00)'),
      );
    }

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
      consultorId: 'daniela-costa',
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
