class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({
    required this.start,
    required this.end,
  });

  int get durationInDays => end.difference(start).inDays;

  @override
  String toString() => 'DateRange(start: $start, end: $end)';
}
