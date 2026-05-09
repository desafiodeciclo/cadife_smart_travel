import 'dart:convert';
import 'dart:typed_data';

import 'package:cadife_smart_travel/features/agency/perfil/domain/entities/consultor_profile_models.dart';
import 'package:cadife_smart_travel/features/agency/perfil/domain/repositories/i_consultor_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kProfileKey = 'consultant_profile_v1';
const _kMetricsKey = 'consultant_metrics_v1';
const _kCacheTimeKey = 'consultant_cache_time_v1';
const _kCacheMaxAge = Duration(hours: 1);

// Override registered in: lib/core/di/provider_overrides.dart
final iConsultorRepositoryProvider = Provider<IConsultorRepository>((ref) {
  throw UnimplementedError('Override em ProviderScope');
});

// ── Profile ───────────────────────────────────────────────────────────────────

final consultorProfileProvider =
    AsyncNotifierProvider<ConsultorProfileNotifier, ConsultorProfile>(
  ConsultorProfileNotifier.new,
);

class ConsultorProfileNotifier extends AsyncNotifier<ConsultorProfile> {
  @override
  Future<ConsultorProfile> build() async {
    final cached = await _loadProfileFromCache();
    if (cached != null) {
      _refreshProfileInBackground();
      return cached;
    }
    final result = await ref.read(iConsultorRepositoryProvider).getProfile();
    return result.fold(
      (failure) => throw failure,
      (profile) {
        _saveProfileToCache(profile);
        return profile;
      },
    );
  }

  /// Optimistic update + server sync. Returns error message on failure, null on success.
  Future<String?> updateBio(String bio) async {
    final previous = state.valueOrNull;
    if (previous == null) return null;

    state = AsyncData(previous.copyWith(bio: bio));

    final result =
        await ref.read(iConsultorRepositoryProvider).updateBio(bio);
    return result.fold(
      (failure) {
        state = AsyncData(previous); // revert optimistic
        return 'Erro ao salvar bio. Tente novamente.';
      },
      (updated) {
        state = AsyncData(updated);
        _saveProfileToCache(updated);
        return null;
      },
    );
  }

  /// Upload photo bytes. Returns error message on failure, null on success.
  Future<String?> uploadPhoto(Uint8List bytes, String fileName) async {
    final result = await ref
        .read(iConsultorRepositoryProvider)
        .uploadPhoto(bytes, fileName);
    return result.fold(
      (failure) => 'Erro ao enviar foto. Tente novamente.',
      (updated) {
        state = AsyncData(updated);
        _saveProfileToCache(updated);
        return null;
      },
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await ref.read(iConsultorRepositoryProvider).getProfile();
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (profile) {
        _saveProfileToCache(profile);
        return AsyncData(profile);
      },
    );
  }

  // ── Cache helpers ──────────────────────────────────────────────────────────

  Future<ConsultorProfile?> _loadProfileFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getString(_kCacheTimeKey);
      if (timeStr == null) return null;
      final cacheTime = DateTime.tryParse(timeStr);
      if (cacheTime == null) return null;
      if (DateTime.now().difference(cacheTime) > _kCacheMaxAge) return null;
      final jsonStr = prefs.getString(_kProfileKey);
      if (jsonStr == null) return null;
      return ConsultorProfile.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    } on Exception catch (_) {
      return null;
    }
  }

  Future<void> _saveProfileToCache(ConsultorProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProfileKey, jsonEncode(profile.toJson()));
      await prefs.setString(_kCacheTimeKey, DateTime.now().toIso8601String());
    } on Exception catch (_) {}
  }

  void _refreshProfileInBackground() {
    Future.microtask(() async {
      final result =
          await ref.read(iConsultorRepositoryProvider).getProfile();
      result.fold(
        (_) {},
        (profile) {
          if (state is! AsyncError) {
            state = AsyncData(profile);
            _saveProfileToCache(profile);
          }
        },
      );
    });
  }
}

// ── Metrics ───────────────────────────────────────────────────────────────────

final consultantMetricsProvider =
    AsyncNotifierProvider<ConsultantMetricsNotifier, ConsultantMetrics>(
  ConsultantMetricsNotifier.new,
);

class ConsultantMetricsNotifier extends AsyncNotifier<ConsultantMetrics> {
  @override
  Future<ConsultantMetrics> build() async {
    final cached = await _loadFromCache();
    if (cached != null) {
      _refreshInBackground();
      return cached;
    }
    final result =
        await ref.read(iConsultorRepositoryProvider).getMetrics();
    return result.fold(
      (failure) => throw failure,
      (metrics) {
        _saveToCache(metrics);
        return metrics;
      },
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result =
        await ref.read(iConsultorRepositoryProvider).getMetrics();
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (metrics) {
        _saveToCache(metrics);
        return AsyncData(metrics);
      },
    );
  }

  Future<ConsultantMetrics?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_kMetricsKey);
      if (jsonStr == null) return null;
      return ConsultantMetrics.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    } on Exception catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(ConsultantMetrics metrics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kMetricsKey, jsonEncode(metrics.toJson()));
    } on Exception catch (_) {}
  }

  void _refreshInBackground() {
    Future.microtask(() async {
      final result =
          await ref.read(iConsultorRepositoryProvider).getMetrics();
      result.fold(
        (_) {},
        (metrics) {
          if (state is! AsyncError) {
            state = AsyncData(metrics);
            _saveToCache(metrics);
          }
        },
      );
    });
  }
}

// ── Goals ─────────────────────────────────────────────────────────────────────

final saleGoalsProvider =
    AsyncNotifierProvider<SaleGoalsNotifier, List<SaleGoal>>(
  SaleGoalsNotifier.new,
);

class SaleGoalsNotifier extends AsyncNotifier<List<SaleGoal>> {
  @override
  Future<List<SaleGoal>> build() async {
    final result = await ref.read(iConsultorRepositoryProvider).getGoals();
    return result.fold<List<SaleGoal>>(
      (failure) => throw failure,
      (goals) => goals,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result =
        await ref.read(iConsultorRepositoryProvider).getGoals();
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      AsyncData.new,
    );
  }
}
