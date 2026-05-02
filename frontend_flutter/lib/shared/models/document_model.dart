import 'package:equatable/equatable.dart';

enum DocumentType { pdf, image, video, audio, other }

class DocumentModel extends Equatable {
  const DocumentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.url,
    this.isGlobal = false,
    this.tripId,
    this.createdAt,
    this.category,
  });

  final String id;
  final String name;
  final DocumentType type;
  final int size; // in bytes
  final String url;
  final bool isGlobal;
  final String? tripId;
  final DateTime? createdAt;
  final String? category;

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  DocumentModel copyWith({
    String? id,
    String? name,
    DocumentType? type,
    int? size,
    String? url,
    bool? isGlobal,
    String? tripId,
    DateTime? createdAt,
    String? category,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      size: size ?? this.size,
      url: url ?? this.url,
      isGlobal: isGlobal ?? this.isGlobal,
      tripId: tripId ?? this.tripId,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [id, name, type, size, url, isGlobal, tripId, createdAt, category];
}
