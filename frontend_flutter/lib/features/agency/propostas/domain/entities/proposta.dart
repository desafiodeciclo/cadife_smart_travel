import 'package:equatable/equatable.dart';

enum ProposalStatus { rascunho, enviada, aceita, recusada, expirada }

class Proposta extends Equatable {
  const Proposta({
    required this.id,
    required this.leadId,
    required this.consultorId,
    required this.status,
    required this.totalValue,
    this.destino,
    this.dataIda,
    this.dataVolta,
    this.numPessoas,
    this.notes,
    this.pdfUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String leadId;
  final String consultorId;
  final ProposalStatus status;
  final double totalValue;
  final String? destino;
  final DateTime? dataIda;
  final DateTime? dataVolta;
  final int? numPessoas;
  final String? notes;
  final String? pdfUrl;
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
    destino: json['destino'] as String?,
    dataIda: json['data_ida'] != null
        ? DateTime.parse(json['data_ida'] as String)
        : null,
    dataVolta: json['data_volta'] != null
        ? DateTime.parse(json['data_volta'] as String)
        : null,
    numPessoas: json['num_pessoas'] as int?,
    notes: json['notes'] as String?,
    pdfUrl: json['pdf_url'] as String?,
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
    this.destino,
    this.dataIda,
    this.dataVolta,
    this.numPessoas,
    this.notes,
  });

  final String leadId;
  final String consultorId;
  final double totalValue;
  final String? destino;
  final DateTime? dataIda;
  final DateTime? dataVolta;
  final int? numPessoas;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'lead_id': leadId,
    'consultor_id': consultorId,
    'total_value': totalValue,
    'destino': destino,
    'data_ida': dataIda?.toIso8601String(),
    'data_volta': dataVolta?.toIso8601String(),
    'num_pessoas': numPessoas,
    'notes': notes,
  };

  @override
  List<Object?> get props => [leadId, consultorId, totalValue];
}

class UpdateProposalRequest extends Equatable {
  const UpdateProposalRequest({this.status, this.totalValue, this.notes});

  final ProposalStatus? status;
  final double? totalValue;
  final String? notes;

  Map<String, dynamic> toJson() => {
    if (status != null) 'status': status!.name,
    if (totalValue != null) 'total_value': totalValue,
    if (notes != null) 'notes': notes,
  };

  @override
  List<Object?> get props => [status, totalValue, notes];
}

