import 'package:equatable/equatable.dart';

enum StatusAgendamento { pendente, confirmado, realizado, cancelado }

enum TipoAgendamento { online, presencial, bloqueio }

enum MotivoBloqueio { pausa, reuniaoInterna, indisponibilidade, outro }

extension StatusAgendamentoExt on StatusAgendamento {
  String get label => switch (this) {
        StatusAgendamento.pendente => 'Pendente',
        StatusAgendamento.confirmado => 'Confirmado',
        StatusAgendamento.realizado => 'Realizado',
        StatusAgendamento.cancelado => 'Cancelado',
      };
}

extension TipoAgendamentoExt on TipoAgendamento {
  String get label => switch (this) {
        TipoAgendamento.online => 'Online',
        TipoAgendamento.presencial => 'Presencial',
        TipoAgendamento.bloqueio => 'Bloqueio',
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

/// Constrói um [DateTime] a partir de uma data e uma string de hora "HH:mm".
DateTime _buildDateTime(DateTime data, String hora) {
  final parts = hora.split(':');
  final hour = int.parse(parts[0]);
  final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
  return DateTime(data.year, data.month, data.day, hour, minute);
}

class Agendamento extends Equatable {
  const Agendamento({
    required this.id,
    required this.consultorId, required this.data, required this.hora, required this.status, this.leadId,
    this.tipo = 'online',
    this.nomeCliente,
    this.destinoViagem,
    this.motivoBloqueio,
    this.notas,
    this.criadoEm,
    this.canceladoEm,
    this.motivoCancelamento,
  });

  final String id;
  final String? leadId;
  final String consultorId;
  final DateTime data;
  final String hora;
  final String tipo;
  final String status;
  final String? nomeCliente;
  final String? destinoViagem;
  final MotivoBloqueio? motivoBloqueio;
  final String? notas;
  final DateTime? criadoEm;
  final DateTime? canceladoEm;
  final String? motivoCancelamento;

  /// Helper que monta o DateTime completo a partir de [data] + [hora].
  DateTime get dateTime => _buildDateTime(data, hora);

  /// Duração fixa de 60 min conforme spec do backend.
  int get durationMinutes => 60;

  bool get isBloqueado => tipo == 'bloqueio';
  bool get isCancelado => status == 'cancelado';

  StatusAgendamento get statusEnum => StatusAgendamento.values.firstWhere(
        (e) => e.name == status,
        orElse: () => StatusAgendamento.pendente,
      );

  TipoAgendamento get tipoEnum => TipoAgendamento.values.firstWhere(
        (e) => e.name == tipo,
        orElse: () => TipoAgendamento.online,
      );

  factory Agendamento.fromJson(Map<String, dynamic> json) => Agendamento(
        id: json['id'] as String,
        leadId: json['lead_id'] as String?,
        consultorId: json['consultor_id'] as String,
        data: DateTime.parse(json['data'] as String),
        hora: json['hora'] as String,
        tipo: json['tipo'] as String? ?? 'online',
        status: json['status'] as String,
        nomeCliente: json['nome_cliente'] as String?,
        destinoViagem: json['destino_viagem'] as String?,
        motivoBloqueio: json['motivo_bloqueio'] != null
            ? MotivoBloqueio.values.firstWhere(
                (e) => e.name == json['motivo_bloqueio'],
                orElse: () => MotivoBloqueio.outro,
              )
            : null,
        notas: json['notas'] as String?,
        criadoEm: json['criado_em'] != null
            ? DateTime.parse(json['criado_em'] as String)
            : null,
        canceladoEm: json['cancelado_em'] != null
            ? DateTime.parse(json['cancelado_em'] as String)
            : null,
        motivoCancelamento: json['motivo_cancelamento'] as String?,
      );

  Agendamento copyWith({
    String? nomeCliente,
    String? destinoViagem,
    String? status,
    String? notas,
    DateTime? data,
    String? hora,
    String? tipo,
    MotivoBloqueio? motivoBloqueio,
    DateTime? canceladoEm,
    String? motivoCancelamento,
  }) {
    return Agendamento(
      id: id,
      leadId: leadId,
      consultorId: consultorId,
      data: data ?? this.data,
      hora: hora ?? this.hora,
      tipo: tipo ?? this.tipo,
      status: status ?? this.status,
      nomeCliente: nomeCliente ?? this.nomeCliente,
      destinoViagem: destinoViagem ?? this.destinoViagem,
      motivoBloqueio: motivoBloqueio ?? this.motivoBloqueio,
      notas: notas ?? this.notas,
      criadoEm: criadoEm,
      canceladoEm: canceladoEm ?? this.canceladoEm,
      motivoCancelamento: motivoCancelamento ?? this.motivoCancelamento,
    );
  }

  @override
  List<Object?> get props => [id, leadId, consultorId, data, hora, status, tipo];
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
    required this.data, required this.hora, this.leadId,
    this.tipo = 'online',
    this.notas,
    this.motivoBloqueio,
  });

  final String? leadId;
  final DateTime data;
  final String hora;
  final String tipo;
  final String? notas;
  final MotivoBloqueio? motivoBloqueio;

  Map<String, dynamic> toJson() => {
        if (leadId != null) 'lead_id': leadId,
        'data':
            '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}',
        'hora': hora,
        'tipo': tipo,
        if (notas != null) 'notas': notas,
        if (motivoBloqueio != null) 'motivo_bloqueio': motivoBloqueio!.name,
      };

  @override
  List<Object?> get props => [leadId, data, hora, tipo];
}

class UpdateAgendaRequest extends Equatable {
  const UpdateAgendaRequest({
    this.data,
    this.hora,
    this.notas,
    this.status,
    this.tipo,
    this.motivoBloqueio,
  });

  final DateTime? data;
  final String? hora;
  final String? notas;
  final String? status;
  final String? tipo;
  final MotivoBloqueio? motivoBloqueio;

  Map<String, dynamic> toJson() => {
        if (data != null)
          'data':
              '${data!.year.toString().padLeft(4, '0')}-${data!.month.toString().padLeft(2, '0')}-${data!.day.toString().padLeft(2, '0')}',
        if (hora != null) 'hora': hora,
        if (notas != null) 'notas': notas,
        if (status != null) 'status': status,
        if (tipo != null) 'tipo': tipo,
        if (motivoBloqueio != null) 'motivo_bloqueio': motivoBloqueio!.name,
      };

  @override
  List<Object?> get props => [data, hora, notas, status, tipo];
}
