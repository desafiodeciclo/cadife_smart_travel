import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';

abstract class AgendaPort {
  Future<List<Agendamento>> getAgenda({DateTime? date});
  Future<Agendamento> getAgendaById(String id);
  Future<Agendamento> createAgenda(CreateAgendaRequest request);
  Future<Agendamento> updateAgenda(String id, UpdateAgendaRequest request);
  Future<void> deleteAgenda(String id);
  Future<List<TimeSlotModel>> getAvailableSlots(DateTime date);
}




