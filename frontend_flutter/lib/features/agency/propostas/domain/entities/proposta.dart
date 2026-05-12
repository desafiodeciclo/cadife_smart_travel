import 'package:equatable/equatable.dart';

enum ProposalStatus { rascunho, enviada, aceita, recusada, expirada }

enum ServicoIncluso {
  aereo,
  hotel,
  transfer,
  seguro,
  passeios;

  String get label {
    switch (this) {
      case ServicoIncluso.aereo:
        return 'Aéreo';
      case ServicoIncluso.hotel:
        return 'Hotel';
      case ServicoIncluso.transfer:
        return 'Transfer';
      case ServicoIncluso.seguro:
        return 'Seguro Viagem';
      case ServicoIncluso.passeios:
        return 'Passeios';
    }
  }
}

class AssinaturaDigital extends Equatable {
  const AssinaturaDigital({
    required this.nomeConsultor,
    required this.timestamp,
    required this.hash,
    this.cpfMascarado,
    this.textoAssinatura,
  });

  final String nomeConsultor;
  final DateTime timestamp;
  final String hash;
  final String? cpfMascarado;
  final String? textoAssinatura;

  Map<String, dynamic> toJson() => {
        'nome_consultor': nomeConsultor,
        'timestamp': timestamp.toIso8601String(),
        'hash': hash,
        if (cpfMascarado != null) 'cpf_mascarado': cpfMascarado,
        if (textoAssinatura != null) 'texto_assinatura': textoAssinatura,
      };

  factory AssinaturaDigital.fromJson(Map<String, dynamic> json) =>
      AssinaturaDigital(
        nomeConsultor: json['nome_consultor'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        hash: json['hash'] as String,
        cpfMascarado: json['cpf_mascarado'] as String?,
        textoAssinatura: json['texto_assinatura'] as String?,
      );

  @override
  List<Object?> get props => [nomeConsultor, timestamp, hash];
}

class Proposta extends Equatable {
  const Proposta({
    required this.id,
    required this.leadId,
    required this.consultorId,
    required this.status,
    required this.totalValue,
    this.titulo,
    this.destino,
    this.destinos,
    this.dataIda,
    this.dataVolta,
    this.numPessoas,
    this.numAdultos,
    this.numCriancas,
    this.servicosInclusos,
    this.condicoesPagamento,
    this.validadeProposta,
    this.observacoesGerais,
    this.assinatura,
    this.htmlContent,
    this.notes,
    this.pdfUrl,
    this.versao,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String leadId;
  final String consultorId;
  final ProposalStatus status;
  final double totalValue;
  final String? titulo;
  final String? destino;
  final List<String>? destinos;
  final DateTime? dataIda;
  final DateTime? dataVolta;
  final int? numPessoas;
  final int? numAdultos;
  final int? numCriancas;
  final List<ServicoIncluso>? servicosInclusos;
  final String? condicoesPagamento;
  final DateTime? validadeProposta;
  final String? observacoesGerais;
  final AssinaturaDigital? assinatura;
  final String? htmlContent;
  final String? notes;
  final String? pdfUrl;
  final int? versao;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Proposta.fromJson(Map<String, dynamic> json) => Proposta(
        id: json['id'] as String,
        leadId: json['lead_id'] as String,
        consultorId: json['consultor_id'] as String,
        status: ProposalStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => ProposalStatus.rascunho,
        ),
        totalValue: (json['total_value'] as num).toDouble(),
        titulo: json['titulo'] as String?,
        destino: json['destino'] as String?,
        destinos: (json['destinos'] as List?)?.cast<String>(),
        dataIda: json['data_ida'] != null
            ? DateTime.parse(json['data_ida'] as String)
            : null,
        dataVolta: json['data_volta'] != null
            ? DateTime.parse(json['data_volta'] as String)
            : null,
        numPessoas: json['num_pessoas'] as int?,
        numAdultos: json['num_adultos'] as int?,
        numCriancas: json['num_criancas'] as int?,
        servicosInclusos: (json['servicos_inclusos'] as List?)
            ?.map(
              (e) => ServicoIncluso.values.firstWhere(
                (s) => s.name == e,
                orElse: () => ServicoIncluso.hotel,
              ),
            )
            .toList(),
        condicoesPagamento: json['condicoes_pagamento'] as String?,
        validadeProposta: json['validade_proposta'] != null
            ? DateTime.parse(json['validade_proposta'] as String)
            : null,
        observacoesGerais: json['observacoes_gerais'] as String?,
        assinatura: json['assinatura'] != null
            ? AssinaturaDigital.fromJson(
                json['assinatura'] as Map<String, dynamic>,
              )
            : null,
        htmlContent: json['html_content'] as String?,
        notes: json['notes'] as String?,
        pdfUrl: json['pdf_url'] as String?,
        versao: json['versao'] as int?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  @override
  List<Object?> get props => [id, leadId, status, totalValue];
}

class CreateProposalRequest extends Equatable {
  const CreateProposalRequest({
    required this.leadId,
    required this.consultorId,
    required this.totalValue,
    this.titulo,
    this.destino,
    this.destinos,
    this.dataIda,
    this.dataVolta,
    this.numPessoas,
    this.numAdultos,
    this.numCriancas,
    this.servicosInclusos,
    this.condicoesPagamento,
    this.validadeProposta,
    this.observacoesGerais,
    this.assinatura,
    this.htmlContent,
    this.notes,
  });

  final String leadId;
  final String consultorId;
  final double totalValue;
  final String? titulo;
  final String? destino;
  final List<String>? destinos;
  final DateTime? dataIda;
  final DateTime? dataVolta;
  final int? numPessoas;
  final int? numAdultos;
  final int? numCriancas;
  final List<ServicoIncluso>? servicosInclusos;
  final String? condicoesPagamento;
  final DateTime? validadeProposta;
  final String? observacoesGerais;
  final AssinaturaDigital? assinatura;
  final String? htmlContent;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'lead_id': leadId,
        'consultor_id': consultorId,
        'total_value': totalValue,
        if (titulo != null) 'titulo': titulo,
        if (destino != null) 'destino': destino,
        if (destinos != null) 'destinos': destinos,
        'data_ida': dataIda?.toIso8601String(),
        'data_volta': dataVolta?.toIso8601String(),
        'num_pessoas': numPessoas,
        if (numAdultos != null) 'num_adultos': numAdultos,
        if (numCriancas != null) 'num_criancas': numCriancas,
        if (servicosInclusos != null)
          'servicos_inclusos':
              servicosInclusos!.map((e) => e.name).toList(),
        if (condicoesPagamento != null)
          'condicoes_pagamento': condicoesPagamento,
        if (validadeProposta != null)
          'validade_proposta': validadeProposta!.toIso8601String(),
        if (observacoesGerais != null) 'observacoes_gerais': observacoesGerais,
        if (assinatura != null) 'assinatura': assinatura!.toJson(),
        if (htmlContent != null) 'html_content': htmlContent,
        if (notes != null) 'notes': notes,
      };

  @override
  List<Object?> get props => [leadId, consultorId, totalValue];
}

class UpdateProposalRequest extends Equatable {
  const UpdateProposalRequest({
    this.status,
    this.totalValue,
    this.titulo,
    this.servicosInclusos,
    this.condicoesPagamento,
    this.observacoesGerais,
    this.htmlContent,
    this.assinatura,
    this.notes,
  });

  final ProposalStatus? status;
  final double? totalValue;
  final String? titulo;
  final List<ServicoIncluso>? servicosInclusos;
  final String? condicoesPagamento;
  final String? observacoesGerais;
  final String? htmlContent;
  final AssinaturaDigital? assinatura;
  final String? notes;

  Map<String, dynamic> toJson() => {
        if (status != null) 'status': status!.name,
        if (totalValue != null) 'total_value': totalValue,
        if (titulo != null) 'titulo': titulo,
        if (servicosInclusos != null)
          'servicos_inclusos':
              servicosInclusos!.map((e) => e.name).toList(),
        if (condicoesPagamento != null)
          'condicoes_pagamento': condicoesPagamento,
        if (observacoesGerais != null) 'observacoes_gerais': observacoesGerais,
        if (htmlContent != null) 'html_content': htmlContent,
        if (assinatura != null) 'assinatura': assinatura!.toJson(),
        if (notes != null) 'notes': notes,
      };

  @override
  List<Object?> get props => [status, totalValue, notes];
}
