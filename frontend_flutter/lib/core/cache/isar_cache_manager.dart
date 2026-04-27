import 'dart:async';

import 'package:cadife_smart_travel/core/cache/isar_schemas/isar_schemas.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

/// Gerenciador de pre-cache estruturado usando Isar.
///
/// Complementa o [OfflineManager] (Hive) fornecendo queries tipadas
/// e performance para objetos complexos: leads, briefings, agenda, propostas.
class IsarCacheManager {
  IsarCacheManager({Isar? isar}) : _isar = isar {
    if (isar != null && isar.isOpen) {
      _initialized = true;
    }
  }

  Isar? _isar;
  bool _initialized = false;

  Isar? get isar {
    return _isar;
  }

  bool get isInitialized => _initialized;

  /// Inicializa o Isar com as coleções do app.
  Future<void> initialize() async {
    if (_initialized) return;

    // Isar 3 web support can be unstable. Skipping it on web to prevent white screen.
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    String path = '';
    final dir = await getApplicationDocumentsDirectory();
    path = dir.path;

    _isar = await Isar.open(
      [
        LeadCacheSchema,
        BriefingCacheSchema,
        AgendaCacheSchema,
        ProposalCacheSchema,
      ],
      directory: path,
      name: 'cadife_cache_v2',
    );
    _initialized = true;
  }

  /// Fecha a instância do Isar.
  Future<void> close() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.close();
    }
    _initialized = false;
  }

  // ── LeadCache CRUD ─────────────────────────────────────

  Future<void> putLead(LeadCache lead) async {
    if (isar == null) return;
    await isar!.writeTxn(() async {
      await isar!.leadCaches.put(lead);
    });
  }

  Future<void> putLeads(List<LeadCache> leads) async {
    if (isar == null) return;
    await isar!.writeTxn(() async {
      await isar!.leadCaches.putAll(leads);
    });
  }

  Future<LeadCache?> getLeadByServerId(String serverId) async {
    if (isar == null) return null;
    return await isar!.leadCaches.where().serverIdEqualTo(serverId).findFirst();
  }

  Future<List<LeadCache>> getAllLeads() async {
    if (isar == null) return [];
    return await isar!.leadCaches.where().findAll();
  }

  Future<void> deleteLeadByServerId(String serverId) async {
    if (isar == null) return;
    final id = await isar!.leadCaches.where().serverIdEqualTo(serverId).idProperty().findFirst();
    if (id != null) {
      await isar!.writeTxn(() async {
        await isar!.leadCaches.delete(id);
      });
    }
  }

  Future<void> clearLeads() async {
    if (isar == null) return;
    await isar!.writeTxn(() async {
      await isar!.leadCaches.clear();
    });
  }

  // ── BriefingCache CRUD ─────────────────────────────────

  Future<void> putBriefing(BriefingCache briefing) async {
    if (isar == null) return;
    await isar!.writeTxn(() async {
      await isar!.briefingCaches.put(briefing);
    });
  }

  Future<void> putBriefings(List<BriefingCache> briefings) async {
    if (isar == null) return;
    await isar!.writeTxn(() async {
      await isar!.briefingCaches.putAll(briefings);
    });
  }

  Future<BriefingCache?> getBriefingByLeadId(String leadId) async {
    if (isar == null) return null;
    return await isar!.briefingCaches.where().leadIdEqualTo(leadId).findFirst();
  }

  Future<List<BriefingCache>> getAllBriefings() async {
    if (isar == null) return [];
    return await isar!.briefingCaches.where().findAll();
  }

  Future<void> deleteBriefingByLeadId(String leadId) async {
    if (isar == null) return;
    final id = await isar!.briefingCaches.where().leadIdEqualTo(leadId).idProperty().findFirst();
    if (id != null) {
      await isar!.writeTxn(() async {
        await isar!.briefingCaches.delete(id);
      });
    }
  }

  Future<void> clearBriefings() async {
    if (isar == null) return;
    await isar!.writeTxn(() async {
      await isar!.briefingCaches.clear();
    });
  }

  // ── AgendaCache CRUD ───────────────────────────────────

  Future<void> putAgenda(AgendaCache agenda) async {
    if (isar == null) return;
    await isar!.writeTxn(() async {
      await isar!.agendaCaches.put(agenda);
    });
  }

  Future<void> putAgendas(List<AgendaCache> agendas) async {
    if (isar == null) return;
    await isar!.writeTxn(() async {
      await isar!.agendaCaches.putAll(agendas);
    });
  }

  Future<AgendaCache?> getAgendaByServerId(String serverId) async {
    if (isar == null) return null;
    return await isar!.agendaCaches.where().serverIdEqualTo(serverId).findFirst();
  }

  Future<List<AgendaCache>> getAllAgendas() async {
    if (isar == null) return [];
    return await isar!.agendaCaches.where().findAll();
  }

  Future<void> deleteAgendaByServerId(String serverId) async {
    if (isar == null) return;
    final id = await isar!.agendaCaches.where().serverIdEqualTo(serverId).idProperty().findFirst();
    if (id != null) {
      await isar!.writeTxn(() async {
        await isar!.agendaCaches.delete(id);
      });
    }
  }

  Future<void> clearAgendas() async {
    if (isar == null) return;
    await isar!.writeTxn(() async {
      await isar!.agendaCaches.clear();
    });
  }

  // ── ProposalCache CRUD ─────────────────────────────────

  Future<void> putProposal(ProposalCache proposal) async {
    if (isar == null) return;
    await isar!.writeTxn(() async {
      await isar!.proposalCaches.put(proposal);
    });
  }

  Future<void> putProposals(List<ProposalCache> proposals) async {
    if (isar == null) return;
    await isar!.writeTxn(() async {
      await isar!.proposalCaches.putAll(proposals);
    });
  }

  Future<ProposalCache?> getProposalByServerId(String serverId) async {
    if (isar == null) return null;
    return await isar!.proposalCaches.where().serverIdEqualTo(serverId).findFirst();
  }

  Future<List<ProposalCache>> getAllProposals() async {
    if (isar == null) return [];
    return await isar!.proposalCaches.where().findAll();
  }

  Future<void> deleteProposalByServerId(String serverId) async {
    if (isar == null) return;
    final id = await isar!.proposalCaches.where().serverIdEqualTo(serverId).idProperty().findFirst();
    if (id != null) {
      await isar!.writeTxn(() async {
        await isar!.proposalCaches.delete(id);
      });
    }
  }

  Future<void> clearProposals() async {
    if (isar == null) return;
    await isar!.writeTxn(() async {
      await isar!.proposalCaches.clear();
    });
  }

  // ── Global Operations ──────────────────────────────────

  /// Remove todo o cache (todas as coleções).
  Future<void> clearAll() async {
    if (isar == null) return;
    await isar!.writeTxn(() async {
      await isar!.leadCaches.clear();
      await isar!.briefingCaches.clear();
      await isar!.agendaCaches.clear();
      await isar!.proposalCaches.clear();
    });
  }

  /// Contagem total de objetos cacheados.
  Future<int> totalCount() async {
    if (isar == null) return 0;
    final leads = await isar!.leadCaches.count();
    final briefings = await isar!.briefingCaches.count();
    final agendas = await isar!.agendaCaches.count();
    final proposals = await isar!.proposalCaches.count();
    return leads + briefings + agendas + proposals;
  }
}
