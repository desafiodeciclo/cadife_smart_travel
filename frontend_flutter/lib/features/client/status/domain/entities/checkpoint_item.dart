import 'package:equatable/equatable.dart';

enum TravelCheckpointType {
  briefingColetado,
  curadoriaIniciada,
  propostaEnviada,
  propostaAprovada,
  viagemConfirmada,
  viagemEmAndamento,
  viagemConcluida,
}

extension TravelCheckpointTypeX on TravelCheckpointType {
  static TravelCheckpointType fromApi(String value) {
    switch (value) {
      case 'BRIEFING_COLETADO':
        return TravelCheckpointType.briefingColetado;
      case 'CURADORIA_INICIADA':
        return TravelCheckpointType.curadoriaIniciada;
      case 'PROPOSTA_ENVIADA':
        return TravelCheckpointType.propostaEnviada;
      case 'PROPOSTA_APROVADA':
        return TravelCheckpointType.propostaAprovada;
      case 'VIAGEM_CONFIRMADA':
        return TravelCheckpointType.viagemConfirmada;
      case 'VIAGEM_EM_ANDAMENTO':
        return TravelCheckpointType.viagemEmAndamento;
      case 'VIAGEM_CONCLUIDA':
        return TravelCheckpointType.viagemConcluida;
      default:
        throw ArgumentError('Unknown checkpoint: $value');
    }
  }

  String get label {
    switch (this) {
      case TravelCheckpointType.briefingColetado:
        return 'Briefing coletado';
      case TravelCheckpointType.curadoriaIniciada:
        return 'Curadoria iniciada';
      case TravelCheckpointType.propostaEnviada:
        return 'Proposta enviada';
      case TravelCheckpointType.propostaAprovada:
        return 'Proposta aprovada';
      case TravelCheckpointType.viagemConfirmada:
        return 'Viagem confirmada';
      case TravelCheckpointType.viagemEmAndamento:
        return 'Viagem em andamento';
      case TravelCheckpointType.viagemConcluida:
        return 'Viagem concluída';
    }
  }
}

class CheckpointItem extends Equatable {
  const CheckpointItem({
    required this.checkpoint,
    required this.ativadoEm,
    required this.ativadoPor,
  });

  final TravelCheckpointType checkpoint;
  final DateTime ativadoEm;
  final String ativadoPor;

  factory CheckpointItem.fromJson(Map<String, dynamic> json) {
    return CheckpointItem(
      checkpoint: TravelCheckpointTypeX.fromApi(json['checkpoint'] as String),
      ativadoEm: DateTime.parse(json['ativado_em'] as String),
      ativadoPor: json['ativado_por'] as String,
    );
  }

  @override
  List<Object?> get props => [checkpoint, ativadoEm, ativadoPor];
}
