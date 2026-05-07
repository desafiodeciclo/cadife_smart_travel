import 'package:equatable/equatable.dart';

class DiaryEntry extends Equatable {
  const DiaryEntry({
    required this.id,
    required this.tripId,
    required this.photoUrl,
    required this.note,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.sharingToken,
    this.isShared = false,
  });

  final String id;
  final String tripId;
  final String photoUrl;
  final String note;
  final DateTime date;
  final String? sharingToken;
  final bool isShared;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiaryEntry copyWith({
    String? note,
    String? sharingToken,
    bool? isShared,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id,
      tripId: tripId,
      photoUrl: photoUrl,
      note: note ?? this.note,
      date: date,
      sharingToken: sharingToken ?? this.sharingToken,
      isShared: isShared ?? this.isShared,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tripId,
        photoUrl,
        note,
        date,
        sharingToken,
        isShared,
        createdAt,
        updatedAt,
      ];
}
