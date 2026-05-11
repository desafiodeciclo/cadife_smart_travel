enum DiaryMood {
  happy('😊'),
  excited('🤩'),
  relaxed('😌'),
  tired('😴'),
  sad('😢');

  final String emoji;
  const DiaryMood(this.emoji);
}

class DiaryEntry {
  final DateTime date;
  final DiaryMood mood;
  final String title;
  final String content;
  final List<String> photos;

  DiaryEntry({
    required this.date,
    required this.mood,
    required this.title,
    required this.content,
    this.photos = const [],
  });
}

class TravelDiary {
  final String id;
  final String travelId;
  final String travelTitle;
  final List<DiaryEntry> entries;

  TravelDiary({
    required this.id,
    required this.travelId,
    required this.travelTitle,
    required this.entries,
  });
}
