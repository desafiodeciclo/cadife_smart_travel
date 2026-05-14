import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Agendamento.fromJson', () {
    test('parses curadoria response correctly', () {
      final json = <String, dynamic>{
        'id': 'uuid-1',
        'lead_id': 'lead-1',
        'consultor_id': 'consultor-1',
        'data': '2026-06-08',
        'hora': '10:00',
        'tipo': 'online',
        'status': 'confirmado',
        'notas': 'Anotação de teste',
        'criado_em': '2026-06-01T10:00:00Z',
      };

      final ag = Agendamento.fromJson(json);

      expect(ag.id, 'uuid-1');
      expect(ag.leadId, 'lead-1');
      expect(ag.consultorId, 'consultor-1');
      expect(ag.data, DateTime(2026, 6, 8));
      expect(ag.hora, '10:00');
      expect(ag.tipo, 'online');
      expect(ag.status, 'confirmado');
      expect(ag.notas, 'Anotação de teste');
      expect(ag.criadoEm, DateTime.parse('2026-06-01T10:00:00Z'));
      expect(ag.dateTime, DateTime(2026, 6, 8, 10, 0));
      expect(ag.durationMinutes, 60);
      expect(ag.isBloqueado, false);
      expect(ag.isCancelado, false);
    });

    test('parses bloqueio response with nullable lead_id', () {
      final json = <String, dynamic>{
        'id': 'uuid-2',
        'lead_id': null,
        'consultor_id': 'consultor-1',
        'data': '2026-06-08',
        'hora': '13:00',
        'tipo': 'bloqueio',
        'status': 'pendente',
        'motivo_bloqueio': 'pausa',
        'notas': null,
        'criado_em': '2026-06-01T10:00:00Z',
        'cancelado_em': null,
        'motivo_cancelamento': null,
      };

      final ag = Agendamento.fromJson(json);

      expect(ag.leadId, isNull);
      expect(ag.tipo, 'bloqueio');
      expect(ag.motivoBloqueio, MotivoBloqueio.pausa);
      expect(ag.isBloqueado, true);
    });

    test('parses cancelado response', () {
      final json = <String, dynamic>{
        'id': 'uuid-3',
        'lead_id': 'lead-2',
        'consultor_id': 'consultor-1',
        'data': '2026-06-08',
        'hora': '15:00',
        'tipo': 'presencial',
        'status': 'cancelado',
        'cancelado_em': '2026-06-07T10:00:00Z',
        'motivo_cancelamento': 'cliente desmarcou',
      };

      final ag = Agendamento.fromJson(json);

      expect(ag.status, 'cancelado');
      expect(ag.isCancelado, true);
      expect(ag.canceladoEm, DateTime.parse('2026-06-07T10:00:00Z'));
      expect(ag.motivoCancelamento, 'cliente desmarcou');
    });
  });

  group('CreateAgendaRequest.toJson', () {
    test('serializes curadoria request correctly', () {
      final request = CreateAgendaRequest(
        leadId: 'lead-1',
        data: DateTime(2026, 6, 8),
        hora: '10:00',
        tipo: 'online',
        notas: 'Observação',
      );

      final json = request.toJson();

      expect(json['lead_id'], 'lead-1');
      expect(json['data'], '2026-06-08');
      expect(json['hora'], '10:00');
      expect(json['tipo'], 'online');
      expect(json['notas'], 'Observação');
      expect(json.containsKey('motivo_bloqueio'), false);
    });

    test('serializes bloqueio request correctly', () {
      final request = CreateAgendaRequest(
        data: DateTime(2026, 6, 8),
        hora: '12:00',
        tipo: 'bloqueio',
        motivoBloqueio: MotivoBloqueio.reuniaoInterna,
      );

      final json = request.toJson();

      expect(json.containsKey('lead_id'), false);
      expect(json['tipo'], 'bloqueio');
      expect(json['motivo_bloqueio'], 'reuniaoInterna');
    });
  });

  group('UpdateAgendaRequest.toJson', () {
    test('serializes partial update correctly', () {
      const request = UpdateAgendaRequest(
        status: 'confirmado',
        notas: 'Atualizado',
      );

      final json = request.toJson();

      expect(json['status'], 'confirmado');
      expect(json['notas'], 'Atualizado');
      expect(json.containsKey('data'), false);
      expect(json.containsKey('hora'), false);
      expect(json.containsKey('tipo'), false);
    });
  });

  group('Slot parsing logic (_slotFromBackend equivalent)', () {
    test('maps backend slot to TimeSlotModel', () {
      final backendSlot = <String, dynamic>{
        'data': '2026-06-08',
        'hora': '14:00',
        'disponivel': true,
      };

      final referenceDate = DateTime(2026, 6, 8);
      final hour = (backendSlot['hora'] as String).split(':')[0];
      final minute = (backendSlot['hora'] as String).split(':')[1];
      final start = DateTime(
        referenceDate.year,
        referenceDate.month,
        referenceDate.day,
        int.parse(hour),
        int.parse(minute),
      );
      final end = start.add(const Duration(hours: 1));
      final model = TimeSlotModel(
        startTime: start,
        endTime: end,
        available: backendSlot['disponivel'] as bool,
      );

      expect(model.startTime, DateTime(2026, 6, 8, 14, 0));
      expect(model.endTime, DateTime(2026, 6, 8, 15, 0));
      expect(model.available, true);
    });
  });
}
