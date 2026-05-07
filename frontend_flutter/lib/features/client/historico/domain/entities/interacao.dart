import 'package:equatable/equatable.dart';

class Interacao extends Equatable {
  const Interacao({
    required this.id,
    required this.leadId,
    required this.channel,
    required this.direction,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  final String id;
  final String leadId;
  final String channel;
  final String direction;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  factory Interacao.fromJson(Map<String, dynamic> json) =>
      Interacao(
        id: json['id'] as String,
        leadId: json['lead_id'] as String,
        channel: json['channel'] as String,
        direction: json['direction'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  @override
  List<Object?> get props => [id, leadId, channel, timestamp];
}

