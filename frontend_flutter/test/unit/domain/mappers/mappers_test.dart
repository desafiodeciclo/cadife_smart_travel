import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_fixtures.dart';

void main() {
  group('Lead Serialization', () {
    test('Lead.fromJson cria Lead com todos os campos obrigatórios', () {
      final json = {
        'id': 'lead-001',
        'name': 'João Silva',
        'phone': '+5511999887766',
        'score': 'quente',
        'status': 'qualificado',
        'completude_pct': 85,
        'created_at': '2026-05-01T10:00:00Z',
      };

      final lead = Lead.fromJson(json);

      expect(lead.id, equals('lead-001'));
      expect(lead.score, equals(LeadScore.quente));
      expect(lead.status, equals(LeadStatus.qualificado));
      expect(lead.completudePct, equals(85));
    });

    test('Lead.toJson serializa Lead corretamente', () {
      final lead = LeadFixture.quente();
      final json = lead.toJson();

      expect(json['id'], equals('lead-001'));
      expect(json['status'], equals('qualificado'));
      expect(json['score'], equals('quente'));
    });
  });

  group('Briefing Serialization', () {
    test('Briefing.fromJson cria Briefing corretamente', () {
      final json = {
        'lead_id': 'lead-001',
        'completude_pct': 100,
        'destino': 'Paris, França',
      };

      final briefing = Briefing.fromJson(json);

      expect(briefing.leadId, equals('lead-001'));
      expect(briefing.completudePct, equals(100));
      expect(briefing.destino, equals('Paris, França'));
    });
  });
}
