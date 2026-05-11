import 'package:cadife_smart_travel/data/mock/travel_diary_mock.dart';
import 'package:cadife_smart_travel/features/client/domain/entities/travel_diary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final diaryProvider = AsyncNotifierProvider<DiaryNotifier, List<TravelDiary>>(
  DiaryNotifier.new,
);

class DiaryNotifier extends AsyncNotifier<List<TravelDiary>> {
  @override
  Future<List<TravelDiary>> build() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return TravelDiaryMock.getMockDiaries();
  }

  Future<void> createDiary(String travelId, String travelTitle) async {
    final currentDiaries = state.valueOrNull ?? [];
    final newDiary = TravelDiary(
      id: 'diary-${DateTime.now().millisecondsSinceEpoch}',
      travelId: travelId,
      travelTitle: travelTitle,
      entries: [],
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
