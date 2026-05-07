import 'package:equatable/equatable.dart';

/// Resumo de viagem usado pelo portal do cliente.
/// Contém apenas os campos necessários para exibição — sem acoplar
/// ao Lead da feature de agência.
class TripSummary extends Equatable {
  const TripSummary({
    required this.id,
    required this.name,
    this.destino,
    this.dataIda,
    this.dataVolta,
    this.numPessoas,
    this.imageUrl,
    this.orcamento,
  });

  final String id;
  final String name;
  final String? destino;
  final DateTime? dataIda;
  final DateTime? dataVolta;
  final int? numPessoas;
  final String? imageUrl;
  final double? orcamento;

  @override
  List<Object?> get props => [
        id,
        name,
        destino,
        dataIda,
        dataVolta,
        numPessoas,
        imageUrl,
        orcamento,
      ];
}
