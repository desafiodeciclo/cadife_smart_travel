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
        data: today,
        hora: '09:00',
        tipo: 'online',
        status: 'confirmado',
        nomeCliente: 'Rafael Mendes',
        destinoViagem: 'Nova York, EUA',
        notas: 'Família de 4 pessoas (2 adultos + 2 crianças). Curadoria principal.',
        criadoEm: now.subtract(const Duration(days: 2)),
      ),
      Agendamento(
        id: 'mock-2',
        leadId: 'camila-santos',
        consultorId: 'daniela-costa',
        data: today,
        hora: '11:00',
        tipo: 'online',
        status: 'pendente',
        nomeCliente: 'Camila Santos',
        destinoViagem: 'Tóquio, Japão',
        notas: 'Grupo de 4 amigas. Atenção: alergia a frutos do mar.',
        criadoEm: now.subtract(const Duration(days: 1)),
      ),
      Agendamento(
        id: 'mock-3',
        consultorId: 'daniela-costa',
        data: today,
        hora: '13:00',
        tipo: 'bloqueio',
        status: 'pendente',
        motivoBloqueio: MotivoBloqueio.pausa,
        notas: 'Pausa para almoço',
        criadoEm: now,
      ),
      Agendamento(
        id: 'mock-4',
        leadId: 'ana-luiza-gomes',
        consultorId: 'marcos-andrade',
        data: today,
        hora: '15:00',
        tipo: 'online',
        status: 'confirmado',
        nomeCliente: 'Ana Luiza Gomes',
        destinoViagem: 'Maldivas',
        notas: 'Lua de mel. Cliente muito animada com villa overwater.',
        criadoEm: now.subtract(const Duration(hours: 3)),
      ),
      // Ontem — lead realizado
      Agendamento(
        id: 'mock-5',
        leadId: 'otavio-grotto',
        consultorId: 'daniela-costa',
        data: today.subtract(const Duration(days: 1)),
        hora: '10:00',
        tipo: 'online',
        status: 'realizado',
        nomeCliente: 'Otávio Grotto',
        destinoViagem: 'Paris, França',
        notas: 'Aniversário de casamento. Roteiro finalizado e aprovado.',
        criadoEm: now.subtract(const Duration(days: 3)),
      ),
      // Amanhã
      Agendamento(
        id: 'mock-6',
        leadId: 'joao-silva',
        consultorId: 'jakeline-lima',
        data: today.add(const Duration(days: 1)),
        hora: '10:00',
        tipo: 'online',
        status: 'confirmado',
        nomeCliente: 'João Silva',
        destinoViagem: 'Europa (Portugal ou Espanha)',
        notas: 'Primeiro contato. Ainda definindo destino.',
        criadoEm: now,
      ),
      Agendamento(
        id: 'mock-7',
        leadId: 'maria-oliveira',
        consultorId: 'diego-costa',
        data: today.add(const Duration(days: 1)),
        hora: '14:00',
        tipo: 'online',
        status: 'pendente',
        nomeCliente: 'Maria Oliveira',
        destinoViagem: 'Cancún, México',
        notas: 'Casal. Verificar passaportes antes da reunião.',
        criadoEm: now,
      ),
      // Depois de amanhã
      Agendamento(
        id: 'mock-8',
        leadId: 'fernanda-castro',
        consultorId: 'diego-costa',
        data: today.add(const Duration(days: 2)),
        hora: '09:00',
        tipo: 'online',
        status: 'confirmado',
        nomeCliente: 'Fernanda Castro',
        destinoViagem: 'Maldivas',
        notas: 'Lead qualificado. Aguardando proposta.',
        criadoEm: now,
      ),
      Agendamento(
        id: 'mock-9',
        leadId: 'rafael-mendes',
        consultorId: 'jakeline-lima',
        data: today.add(const Duration(days: 2)),
        hora: '11:00',
        tipo: 'online',
        status: 'confirmado',
        nomeCliente: 'Rafael Mendes',
        destinoViagem: 'Nova York, EUA',
        notas: 'Follow-up — confirmar visto americano.',
        criadoEm: now,
      ),
      Agendamento(
        id: 'mock-10',
        leadId: 'ana-luiza-gomes',
        consultorId: 'marcos-andrade',
        data: today.add(const Duration(days: 2)),
        hora: '14:00',
        tipo: 'online',
        status: 'confirmado',
        nomeCliente: 'Ana Luiza Gomes',
        destinoViagem: 'Maldivas',
        notas: 'Apresentação final do pacote curado.',
        criadoEm: now,
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
              a.data.year == date.year &&
              a.data.month == date.month &&
              a.data.day == date.day,
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

    final hour = int.parse(request.hora.split(':')[0]);
    if (hour < 9 || hour >= 16) {
      return const Left(
        ServerFailure('Agendamento fora do horário permitido (09:00–16:00)'),
      );
    }

    final sameDay = _agendas
        .where(
          (a) =>
              a.data.year == request.data.year &&
              a.data.month == request.data.month &&
              a.data.day == request.data.day &&
              a.status != 'cancelado' &&
              a.tipo != 'bloqueio',
        )
        .length;
    if (sameDay >= 6) {
      return const Left(
        ServerFailure('Limite de 6 agendamentos por dia atingido'),
      );
    }

    final conflict = _agendas.any(
      (a) =>
          a.data.year == request.data.year &&
          a.data.month == request.data.month &&
          a.data.day == request.data.day &&
          a.hora == request.hora &&
          a.status != 'cancelado',
    );
    if (conflict) {
      return const Left(ConflictFailure('Horário já ocupado'));
    }

    final isBloqueio = request.tipo == 'bloqueio';
    final agenda = Agendamento(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      leadId: isBloqueio ? null : request.leadId,
      consultorId: 'daniela-costa',
      data: request.data,
      hora: request.hora,
      tipo: request.tipo,
      status: isBloqueio ? 'pendente' : 'confirmado',
      nomeCliente: null,
      destinoViagem: null,
      motivoBloqueio: request.motivoBloqueio,
      notas: request.notas,
      criadoEm: DateTime.now(),
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
      data: request.data ?? old.data,
      hora: request.hora ?? old.hora,
      tipo: request.tipo ?? old.tipo,
      status: request.status ?? old.status,
      nomeCliente: old.nomeCliente,
      destinoViagem: old.destinoViagem,
      motivoBloqueio: request.motivoBloqueio ?? old.motivoBloqueio,
      notas: request.notas ?? old.notas,
      criadoEm: old.criadoEm,
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
      final horaStr = '${hour.toString().padLeft(2, '0')}:00';
      final isBooked = _agendas.any(
        (a) =>
            a.data.year == date.year &&
            a.data.month == date.month &&
            a.data.day == date.day &&
            a.hora == horaStr &&
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
