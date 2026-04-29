import 'dart:io';

import 'package:cadife_smart_travel/core/cache/isar_cache_manager.dart';
import 'package:cadife_smart_travel/core/cache/isar_schemas/isar_schemas.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

void main() {
  group('IsarCacheManager', () {
    late IsarCacheManager manager;
    late Directory tempDir;

    setUpAll(() async {
      await Isar.initializeIsarCore(download: true);
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('isar_test');
      manager = IsarCacheManager(
        isar: await Isar.open(
          [
            LeadCacheSchema,
            BriefingCacheSchema,
            AgendaCacheSchema,
            ProposalCacheSchema,
          ],
          directory: tempDir.path,
          name: 'test_cache',
        ),
      );
    });

    tearDown(() async {
      await manager.close();
      await tempDir.delete(recursive: true);
    });

    test('putLead e getLeadByServerId devem persistir LeadCache', () async {
      final lead = LeadCache(
        serverId: 'lead-001',
        name: 'João Silva',
        phone: '5511999999999',
        status: 'novo',
        score: 'quente',
        completudePct: 75,
        cachedAt: DateTime.now(),
      );

      await manager.putLead(lead);
      final result = await manager.getLeadByServerId('lead-001');

      expect(result, isNotNull);
      expect(result!.name, equals('João Silva'));
      expect(result.phone, equals('5511999999999'));
    });

    test('putLeads e getAllLeads devem retornar lista completa', () async {
      final leads = [
        LeadCache(
          serverId: 'lead-001',
          name: 'Ana',
          phone: '111',
          status: 'novo',
          score: 'frio',
          completudePct: 10,
          cachedAt: DateTime.now(),
        ),
        LeadCache(
          serverId: 'lead-002',
          name: 'Bruno',
          phone: '222',
          status: 'qualificado',
          score: 'quente',
          completudePct: 90,
          cachedAt: DateTime.now(),
        ),
      ];

      await manager.putLeads(leads);
      final all = await manager.getAllLeads();

      expect(all.length, equals(2));
      expect(all.map((l) => l.name).toList(), containsAll(['Ana', 'Bruno']));
    });

    test('deleteLeadByServerId deve remover lead', () async {
      final lead = LeadCache(
        serverId: 'lead-003',
        name: 'Carlos',
        phone: '333',
        status: 'novo',
        score: 'morno',
        completudePct: 50,
        cachedAt: DateTime.now(),
      );

      await manager.putLead(lead);
      await manager.deleteLeadByServerId('lead-003');
      final result = await manager.getLeadByServerId('lead-003');

      expect(result, isNull);
    });

    test('clearLeads deve remover todos os leads', () async {
      await manager.putLead(LeadCache(
        serverId: 'lead-004',
        name: 'Diana',
        phone: '444',
        status: 'novo',
        score: 'quente',
        completudePct: 80,
        cachedAt: DateTime.now(),
      ));

      await manager.clearLeads();
      expect((await manager.getAllLeads()).length, equals(0));
    });

    test('clearAll deve esvaziar todas as coleções', () async {
      await manager.putLead(LeadCache(
        serverId: 'lead-005',
        name: 'Eduardo',
        phone: '555',
        status: 'novo',
        score: 'frio',
        completudePct: 20,
        cachedAt: DateTime.now(),
      ));
      await manager.putAgenda(AgendaCache(
        serverId: 'agenda-001',
        leadId: 'lead-005',
        consultorId: 'consultor-1',
        dateTime: DateTime.now(),
        durationMinutes: 30,
        status: 'agendado',
        cachedAt: DateTime.now(),
      ));

      await manager.clearAll();
      expect((await manager.getAllLeads()).length, equals(0));
      expect((await manager.getAllAgendas()).length, equals(0));
    });

    test('totalCount deve retornar número correto de objetos', () async {
      expect(await manager.totalCount(), equals(0));
      await manager.putLead(LeadCache(
        serverId: 'lead-006',
        name: 'Fernanda',
        phone: '666',
        status: 'novo',
        score: 'quente',
        completudePct: 100,
        cachedAt: DateTime.now(),
      ));
      expect(await manager.totalCount(), equals(1));
    });

    test('briefing CRUD funciona corretamente', () async {
      final briefing = BriefingCache(
        leadId: 'lead-007',
        completudePct: 60,
        destino: 'Paris',
        cachedAt: DateTime.now(),
      );

      await manager.putBriefing(briefing);
      final result = await manager.getBriefingByLeadId('lead-007');
      expect(result, isNotNull);
      expect(result!.destino, equals('Paris'));

      await manager.deleteBriefingByLeadId('lead-007');
      expect(await manager.getBriefingByLeadId('lead-007'), isNull);
    });

    test('proposal CRUD funciona corretamente', () async {
      final proposal = ProposalCache(
        serverId: 'prop-001',
        leadId: 'lead-008',
        consultorId: 'consultor-2',
        status: 'enviada',
        totalValue: 15000.0,
        cachedAt: DateTime.now(),
      );

      await manager.putProposal(proposal);
      final result = await manager.getProposalByServerId('prop-001');
      expect(result, isNotNull);
      expect(result!.totalValue, equals(15000.0));

      await manager.deleteProposalByServerId('prop-001');
      expect(await manager.getProposalByServerId('prop-001'), isNull);
    });
  });
}
