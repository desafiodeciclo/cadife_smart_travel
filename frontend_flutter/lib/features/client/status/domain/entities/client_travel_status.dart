import 'package:equatable/equatable.dart';

enum TravelStatus { emAtendimento, qualificado, agendado, proposta, confirmado }

class ClientTravelStatus extends Equatable {
  const ClientTravelStatus({
    required this.id,
    required this.status,
    this.destino,
    this.dataPartida,
    this.dataRetorno,
    this.numPessoas,
    this.consultorNome,
    this.consultorAvatar,
  });

  final String id;
  final TravelStatus status;
  final String? destino;
  final DateTime? dataPartida;
  final DateTime? dataRetorno;
  final int? numPessoas;
  final String? consultorNome;
  final String? consultorAvatar;

  @override
  List<Object?> get props => [id, status, destino, dataPartida, dataRetorno];
}
