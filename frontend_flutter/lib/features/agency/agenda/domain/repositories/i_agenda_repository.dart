import 'package:fpdart/fpdart.dart';
import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';

abstract class IAgendaRepository {
  Future<Either<Failure, List<Agendamento>>> getAgenda({DateTime? date});
  Future<Either<Failure, Agendamento>> getAgendaById(String id);
  Future<Either<Failure, Agendamento>> createAgenda(CreateAgendaRequest request);
  Future<Either<Failure, Agendamento>> updateAgenda(String id, UpdateAgendaRequest request);
  Future<Either<Failure, void>> deleteAgenda(String id);
  Future<Either<Failure, List<TimeSlotModel>>> getAvailableSlots(DateTime date);
}
