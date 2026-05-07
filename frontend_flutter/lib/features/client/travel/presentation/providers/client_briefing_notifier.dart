import 'dart:async';
import 'dart:convert';

import 'package:cadife_smart_travel/core/cache/isar_cache_manager.dart';
import 'package:cadife_smart_travel/core/cache/isar_schemas/briefing_cache.dart';
import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/presentation/providers/leads_usecases_providers.dart';
import 'package:cadife_smart_travel/features/client/travel/domain/entities/briefing_flag.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── State ────────────────────────────────────────────────────────────────────

class BriefingViewState {
  const BriefingViewState({
    required this.briefing,
    this.isOffline = false,
    this.cachedAt,
    this.lastSynced,
  });

  final Briefing briefing;
  final bool isOffline;
  final DateTime? cachedAt;
  final DateTime? lastSynced;

  BriefingViewState copyWith({
    Briefing? briefing,
    bool? isOffline,
    DateTime? cachedAt,
    DateTime? lastSynced,
  }) => BriefingViewState(
        briefing: briefing ?? this.briefing,
        isOffline: isOffline ?? this.isOffline,
        cachedAt: cachedAt ?? this.cachedAt,
        lastSynced: lastSynced ?? this.lastSynced,
      );
}

// ── Briefing provider (family by leadId) ─────────────────────────────────────

final clientBriefingProvider = AsyncNotifierProvider.family<
    ClientBriefingNotifier, BriefingViewState, String>(
  ClientBriefingNotifier.new,
);

class ClientBriefingNotifier
    extends FamilyAsyncNotifier<BriefingViewState, String> {
  @override
  Future<BriefingViewState> build(String leadId) async {
    // Poll every 30s; cancel on dispose
    final timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _silentRefresh(leadId);
    });
    ref.onDispose(timer.cancel);

    return _loadBriefing(leadId);
  }

  Future<BriefingViewState> _loadBriefing(String leadId) async {
    final cacheManager = sl<IsarCacheManager>();

    // 1. Try Isar cache first (instant)
    final cached = await cacheManager.getBriefingByLeadId(leadId);

    // 2. Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.ethernet);

    if (!isOnline && cached != null) {
      return BriefingViewState(
        briefing: _fromCache(cached),
        isOffline: true,
        cachedAt: cached.cachedAt,
      );
    }

    // 3. Fetch from API
    final useCase = ref.read(getBriefingUseCaseProvider);
    final result = await useCase(leadId);

    return result.fold(
      (failure) {
        // API failed — fall back to cache if available
        if (cached != null) {
          return BriefingViewState(
            briefing: _fromCache(cached),
            isOffline: true,
            cachedAt: cached.cachedAt,
          );
        }
        throw failure;
      },
      (briefing) async {
        // 4. Persist fresh data to Isar
        await cacheManager.putBriefing(_toCache(briefing));
        return BriefingViewState(
          briefing: briefing,
          isOffline: false,
          lastSynced: DateTime.now(),
        );
      },
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadBriefing(arg));
  }

  // Silent refresh (polling): only update state if data changed, no loading flicker
  Future<void> _silentRefresh(String leadId) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.ethernet);
      if (!isOnline) return;

      final useCase = ref.read(getBriefingUseCaseProvider);
      final result = await useCase(leadId);
      if (result.isRight()) {
        final briefing = result.getOrElse((_) => throw StateError('unreachable'));
        await sl<IsarCacheManager>().putBriefing(_toCache(briefing));
        state = AsyncData(
          BriefingViewState(
            briefing: briefing,
            isOffline: false,
            lastSynced: DateTime.now(),
          ),
        );
      }
    } on Object {
      // Swallow silently — UI keeps showing previous data
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Briefing _fromCache(BriefingCache c) => Briefing(
        leadId: c.leadId,
        completudePct: c.completudePct,
        destino: c.destino,
        dataIda: c.dataIda,
        dataVolta: c.dataVolta,
        numPessoas: c.numPessoas,
        perfil: c.perfil,
        tipoViagem: c.tipoViagem,
        preferencias: c.preferencias,
        orcamentoFaixa: c.orcamentoFaixa,
        passaporteValido: c.passaporteValido,
        experienciaInternacional: c.experienciaInternacional,
        resumoConversa: c.resumoConversa,
      );

  BriefingCache _toCache(Briefing b) => BriefingCache(
        leadId: b.leadId,
        completudePct: b.completudePct,
        destino: b.destino,
        dataIda: b.dataIda,
        dataVolta: b.dataVolta,
        numPessoas: b.numPessoas,
        perfil: b.perfil,
        tipoViagem: b.tipoViagem,
        preferencias: b.preferencias,
        orcamentoFaixa: b.orcamentoFaixa,
        passaporteValido: b.passaporteValido,
        experienciaInternacional: b.experienciaInternacional,
        resumoConversa: b.resumoConversa,
        cachedAt: DateTime.now(),
      );
}

// ── Briefing flag provider (family by leadId) ─────────────────────────────────

const _flagsPrefixKey = 'briefing_flags_';

final briefingFlagProvider = NotifierProvider.family<
    BriefingFlagNotifier, List<BriefingFlag>, String>(
  BriefingFlagNotifier.new,
);

class BriefingFlagNotifier
    extends FamilyNotifier<List<BriefingFlag>, String> {
  @override
  List<BriefingFlag> build(String leadId) {
    unawaited(_loadFromPrefs(leadId));
    return [];
  }

  Future<void> _loadFromPrefs(String leadId) async {
    try {
      final prefs = sl<SharedPreferences>();
      final raw = prefs.getString('$_flagsPrefixKey$leadId');
      if (raw == null) return;
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => BriefingFlag.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    } on Object {
      // prefs not yet ready or parse error — keep empty list
    }
  }

  Future<void> addFlag(String field, BriefingFlagType type) async {
    final updated = [
      ...state.where((f) => f.field != field),
      BriefingFlag(field: field, type: type),
    ];
    state = updated;
    await _persist(arg, updated);
  }

  Future<void> removeFlag(String field) async {
    final updated = state.where((f) => f.field != field).toList();
    state = updated;
    await _persist(arg, updated);
  }

  BriefingFlagType? flagFor(String field) {
    try {
      return state.firstWhere((f) => f.field == field).type;
    } on StateError {
      return null;
    }
  }

  Future<void> _persist(String leadId, List<BriefingFlag> flags) async {
    try {
      final prefs = sl<SharedPreferences>();
      final encoded = jsonEncode(flags.map((f) => f.toJson()).toList());
      await prefs.setString('$_flagsPrefixKey$leadId', encoded);
    } on Object {
      // Non-critical — flag is already in memory
    }
  }
}
