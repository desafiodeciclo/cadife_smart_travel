import 'package:equatable/equatable.dart';

enum DocumentType { pdf, image, video, audio, other }

class Documento extends Equatable {
  const Documento({
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
    if (size <= 0) return '—';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Documento copyWith({
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
    return Documento(
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

  factory Documento.fromJson(Map<String, dynamic> json) {
    DocumentType parseType(String? t) {
      switch (t) {
        case 'pdf':
          return DocumentType.pdf;
        case 'image':
          return DocumentType.image;
        case 'video':
          return DocumentType.video;
        case 'audio':
          return DocumentType.audio;
        default:
          return DocumentType.other;
      }
    }

    return Documento(
      id: json['id'] as String,
      name: json['name'] as String,
      type: parseType(json['type'] as String?),
      size: (json['size_kb'] as num).toInt() * 1024,
      url: json['url'] as String,
      tripId: json['travel_id'] as String?,
      createdAt: DateTime.tryParse(json['uploaded_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, name, type, size, url, isGlobal, tripId, createdAt, category];
}

