class OfflineEvent {
  final int? id;
  final String title;
  final String payload;
  final DateTime createdAt;
  final bool isSynced;

  OfflineEvent({
    required this.title,
    required this.payload,
    required this.createdAt,
    this.id,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory OfflineEvent.fromMap(Map<String, dynamic> map) {
    return OfflineEvent(
      id: map['id'] as int?,
      title: map['title'] as String,
      payload: map['payload'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      isSynced: (map['is_synced'] as int) == 1,
    );
  }
}
