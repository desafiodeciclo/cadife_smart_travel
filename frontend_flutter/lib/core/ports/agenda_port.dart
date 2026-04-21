import 'package:cadife_smart_travel/shared/models/agenda_model.dart';
import 'package:cadife_smart_travel/shared/models/models.dart';

abstract class AgendaPort {
  Future<List<AgendaModel>> getAgenda({DateTime? date});
  Future<AgendaModel> getAgendaById(String id);
  Future<AgendaModel> createAgenda(CreateAgendaRequest request);
  Future<AgendaModel> updateAgenda(String id, UpdateAgendaRequest request);
  Future<void> deleteAgenda(String id);
  Future<List<TimeSlotModel>> getAvailableSlots(DateTime date);
}