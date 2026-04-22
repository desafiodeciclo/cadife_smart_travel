import 'package:equatable/equatable.dart';

class BriefingModel extends Equatable {
  const BriefingModel({
    required this.leadId,
    required this.completudePct,
    this.destino,
    this.dataIda,
    this.dataVolta,
    this.numPessoas,
    this.perfil,
    this.tipoViagem,
    this.preferencias,
    this.orcamentoFaixa,
    this.passaporteValido,
    this.experienciaInternacional,
    this.resumoConversa,
  });

  final String leadId;
  final int completudePct;
  final String? destino;
  final DateTime? dataIda;
  final DateTime? dataVolta;
  final int? numPessoas;
  final String? perfil;
  final String? tipoViagem;
  final String? preferencias;
  final String? orcamentoFaixa;
  final bool? passaporteValido;
  final bool? experienciaInternacional;
  final String? resumoConversa;

  factory BriefingModel.fromJson(Map<String, dynamic> json) => BriefingModel(
        leadId: json['lead_id'] as String,
        completudePct: json['completude_pct'] as int,
        destino: json['destino'] as String?,
        dataIda: json['data_ida'] != null
            ? DateTime.parse(json['data_ida'] as String)
            : null,
        dataVolta: json['data_volta'] != null
            ? DateTime.parse(json['data_volta'] as String)
            : null,
        numPessoas: json['num_pessoas'] as int?,
        perfil: json['perfil'] as String?,
        tipoViagem: json['tipo_viagem'] as String?,
        preferencias: json['preferencias'] as String?,
        orcamentoFaixa: json['orcamento_faixa'] as String?,
        passaporteValido: json['passaporte_valido'] as bool?,
        experienciaInternacional: json['experiencia_internacional'] as bool?,
        resumoConversa: json['resumo_conversa'] as String?,
      );

  @override
  List<Object?> get props => [leadId, completudePct];
}