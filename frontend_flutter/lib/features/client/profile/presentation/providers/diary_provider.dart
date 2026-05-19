import 'package:cadife_smart_travel/core/di/service_locator.dart';
import 'package:cadife_smart_travel/features/client/domain/entities/travel_diary.dart';
import 'package:cadife_smart_travel/features/client/home/presentation/providers/travels_provider.dart';
import 'package:cadife_smart_travel/features/client/profile/data/datasources/diary_remote_datasource.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/entities/diary_entry.dart'
    as profile;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final diaryRemoteDatasourceProvider = Provider<DiaryRemoteDatasource>((ref) {
  return DiaryRemoteDatasource(sl<Dio>());
});

/// Memórias (profile.DiaryEntry) de uma viagem específica — backend real.
final tripDiaryEntriesProvider =
    FutureProvider.family<List<profile.DiaryEntry>, String>(
  (ref, leadId) async {
    final ds = ref.watch(diaryRemoteDatasourceProvider);
    final entries = await ds.listByTrip(leadId);
    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  },
);

final diaryProvider = AsyncNotifierProvider<DiaryNotifier, List<TravelDiary>>(
  DiaryNotifier.new,
);

class DiaryNotifier extends AsyncNotifier<List<TravelDiary>> {
  @override
  Future<List<TravelDiary>> build() async {
    final ds = ref.watch(diaryRemoteDatasourceProvider);
    final entries = await ds.listMyTimeline();

    // Títulos a partir das viagens reais do usuário.
    final travels = await ref.watch(travelsProvider.future);
    final titleById = {for (final t in travels) t.id: t.destination};

    final grouped = <String, List<profile.DiaryEntry>>{};
    for (final e in entries) {
      grouped.putIfAbsent(e.tripId, () => []).add(e);
    }

    return grouped.entries.map((g) {
      final mapped = g.value
          .map(
            (e) => DiaryEntry(
              date: e.date,
              mood: DiaryMood.happy,
              title: '',
              content: e.note,
              photos: e.photoUrl.isEmpty ? const [] : [e.photoUrl],
            ),
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      return TravelDiary(
        id: g.key,
        travelId: g.key,
        travelTitle: titleById[g.key] ?? 'Diário de viagem',
        entries: mapped,
      );
    }).toList();
  }

  Future<void> createDiary(String travelId, String travelTitle) async {
    final currentDiaries = state.valueOrNull ?? [];
    if (currentDiaries.any((d) => d.travelId == travelId)) return;
    final newDiary = TravelDiary(
      id: travelId,
      travelId: travelId,
      travelTitle: travelTitle,
      entries: const [],
    );
    state = AsyncData([...currentDiaries, newDiary]);
  }

  void addEntry(String diaryId, DiaryEntry entry) {
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.map((d) {
      if (d.id != diaryId) return d;
      return TravelDiary(
        id: d.id,
        travelId: d.travelId,
        travelTitle: d.travelTitle,
        entries: [...d.entries, entry],
      );
    }).toList());
  }

  void updateEntry(String diaryId, int entryIndex, DiaryEntry updated) {
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.map((d) {
      if (d.id != diaryId) return d;
      final entries = List<DiaryEntry>.from(d.entries);
      entries[entryIndex] = updated;
      return TravelDiary(
        id: d.id,
        travelId: d.travelId,
        travelTitle: d.travelTitle,
        entries: entries,
      );
    }).toList());
  }
}
