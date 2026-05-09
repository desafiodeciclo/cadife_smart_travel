import 'package:equatable/equatable.dart';

enum StatusAgendamento { agendado, pendente, realizado, cancelado, bloqueado }

enum MotivoBloqueio { pausa, reuniaoInterna, indisponibilidade, outro }

extension StatusAgendamentoExt on StatusAgendamento {
  String get label => switch (this) {
        StatusAgendamento.agendado => 'Agendado',
        StatusAgendamento.pendente => 'Pendente',
        StatusAgendamento.realizado => 'Realizado',
        StatusAgendamento.cancelado => 'Cancelado',
        StatusAgendamento.bloqueado => 'Bloqueado',
      };
}

extension MotivoBloqueioExt on MotivoBloqueio {
  String get label => switch (this) {
        MotivoBloqueio.pausa => 'Pausa',
        MotivoBloqueio.reuniaoInterna => 'Reunião Interna',
        MotivoBloqueio.indisponibilidade => 'Indisponibilidade',
        MotivoBloqueio.outro => 'Outro',
      };
}

class Agendamento extends Equatable {
  const Agendamento({
    required this.id,
    required this.leadId,
    required this.consultorId,
    required this.dateTime,
    required this.durationMinutes,
    required this.status,
    this.nomeCliente,
    this.destinoViagem,
    this.motivoBloqueio,
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
  final String? nomeCliente;
  final String? destinoViagem;
  final MotivoBloqueio? motivoBloqueio;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isBloqueado => status == 'bloqueado';
  bool get isCancelado => status == 'cancelado';

  StatusAgendamento get statusEnum => StatusAgendamento.values.firstWhere(
        (e) => e.name == status,
        orElse: () => StatusAgendamento.agendado,
      );

  factory Agendamento.fromJson(Map<String, dynamic> json) => Agendamento(
        id: json['id'] as String,
        leadId: json['lead_id'] as String,
        consultorId: json['consultor_id'] as String,
        dateTime: DateTime.parse(json['date_time'] as String),
        durationMinutes: json['duration_minutes'] as int,
        status: json['status'] as String,
        nomeCliente: json['nome_cliente'] as String?,
        destinoViagem: json['destino_viagem'] as String?,
        motivoBloqueio: json['motivo_bloqueio'] != null
            ? MotivoBloqueio.values.firstWhere(
                (e) => e.name == json['motivo_bloqueio'],
                orElse: () => MotivoBloqueio.outro,
              )
            : null,
        notes: json['notes'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  Agendamento copyWith({
    String? nomeCliente,
    String? destinoViagem,
    String? status,
    String? notes,
    DateTime? dateTime,
    int? durationMinutes,
  }) {
    return Agendamento(
      id: id,
      leadId: leadId,
      consultorId: consultorId,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      nomeCliente: nomeCliente ?? this.nomeCliente,
      destinoViagem: destinoViagem ?? this.destinoViagem,
      motivoBloqueio: motivoBloqueio,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, leadId, consultorId, dateTime, status];
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
    this.nomeCliente,
    this.destinoViagem,
    this.motivoBloqueio,
  });

  final String leadId;
  final DateTime dateTime;
  final int durationMinutes;
  final String? notes;
  final String? nomeCliente;
  final String? destinoViagem;
  final MotivoBloqueio? motivoBloqueio;

  Map<String, dynamic> toJson() => {
        'lead_id': leadId,
        'date_time': dateTime.toIso8601String(),
        'duration_minutes': durationMinutes,
        if (notes != null) 'notes': notes,
        if (nomeCliente != null) 'nome_cliente': nomeCliente,
        if (destinoViagem != null) 'destino_viagem': destinoViagem,
        if (motivoBloqueio != null) 'motivo_bloqueio': motivoBloqueio!.name,
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

