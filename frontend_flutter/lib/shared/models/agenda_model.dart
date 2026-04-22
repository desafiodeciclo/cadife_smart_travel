import 'package:equatable/equatable.dart';

class AgendaModel extends Equatable {
  const AgendaModel({
    required this.id,
    required this.leadId,
    required this.consultorId,
    required this.dateTime,
    required this.durationMinutes,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String leadId;
  final String consultorId;
  final DateTime dateTime;
  final int durationMinutes;
  final String status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AgendaModel.fromJson(Map<String, dynamic> json) => AgendaModel(
        id: json['id'] as String,
        leadId: json['lead_id'] as String,
        consultorId: json['consultor_id'] as String,
        dateTime: DateTime.parse(json['date_time'] as String),
        durationMinutes: json['duration_minutes'] as int,
        status: json['status'] as String,
        notes: json['notes'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  @override
  List<Object?> get props => [id, leadId, consultorId, dateTime];
}

class TimeSlotModel extends Equatable {
  const TimeSlotModel({
    required this.startTime,
    required this.endTime,
    required this.available,
  });

  final DateTime startTime;
  final DateTime endTime;
  final bool available;

  @override
  List<Object?> get props => [startTime, endTime, available];
}

class CreateAgendaRequest extends Equatable {
  const CreateAgendaRequest({
    required this.leadId,
    required this.dateTime,
    required this.durationMinutes,
    this.notes,
  });

  final String leadId;
  final DateTime dateTime;
  final int durationMinutes;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'lead_id': leadId,
        'date_time': dateTime.toIso8601String(),
        'duration_minutes': durationMinutes,
        'notes': notes,
      };

  @override
  List<Object?> get props => [leadId, dateTime, durationMinutes];
}

class UpdateAgendaRequest extends Equatable {
  const UpdateAgendaRequest({
    this.dateTime,
    this.durationMinutes,
    this.notes,
    this.status,
  });

  final DateTime? dateTime;
  final int? durationMinutes;
  final String? notes;
  final String? status;

  Map<String, dynamic> toJson() => {
        if (dateTime != null) 'date_time': dateTime!.toIso8601String(),
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        if (notes != null) 'notes': notes,
        if (status != null) 'status': status,
      };

  @override
  List<Object?> get props => [dateTime, durationMinutes, notes, status];
}