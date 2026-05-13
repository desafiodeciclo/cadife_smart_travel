// lib/features/client/historico/domain/entities/travel_diary.dart

class TravelDiary {
  final String id;
  final String travelId;
  final List<DiaryEntry> entries;

  TravelDiary({
    required this.id,
    required this.travelId,
    required this.entries,
  });
}

class DiaryEntry {
  final DateTime date;
  final String title;
  final String content;
  final List<String> photos;
  final DiaryMood mood;

  DiaryEntry({
    required this.date,
    required this.title,
    required this.content,
    required this.photos,
    required this.mood,
  });
}

enum DiaryMood { excited, happy, neutral, tired, sad }
