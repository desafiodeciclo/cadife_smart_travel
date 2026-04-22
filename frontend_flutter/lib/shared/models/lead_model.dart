import 'package:equatable/equatable.dart';

class LeadModel extends Equatable {
  const LeadModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    required this.score,
    required this.completudePct,
    this.email,
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
    this.assignedTo,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final LeadStatus status;
  final LeadScore score;
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
  final String? assignedTo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory LeadModel.fromJson(Map<String, dynamic> json) => LeadModel(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        status: LeadStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => LeadStatus.novo,
        ),
        score: LeadScore.values.firstWhere(
          (e) => e.name == json['score'],
          orElse: () => LeadScore.frio,
        ),
        completudePct: json['completude_pct'] as int? ?? 0,
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
        assignedTo: json['assigned_to'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'status': status.name,
        'score': score.name,
        'completude_pct': completudePct,
        'destino': destino,
        'data_ida': dataIda?.toIso8601String(),
        'data_volta': dataVolta?.toIso8601String(),
        'num_pessoas': numPessoas,
        'perfil': perfil,
        'tipo_viagem': tipoViagem,
        'preferencias': preferencias,
        'orcamento_faixa': orcamentoFaixa,
        'passaporte_valido': passaporteValido,
        'experiencia_internacional': experienciaInternacional,
        'assigned_to': assignedTo,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, name, phone, status, score, completudePct];
}

enum LeadStatus {
  novo,
  emAtendimento,
  qualificado,
  agendado,
  proposta,
  fechado,
  perdido,
}

enum LeadScore {
  quente,
  morno,
  frio,
}

class CreateLeadRequest extends Equatable {
  const CreateLeadRequest({
    required this.name,
    required this.phone,
    this.email,
    this.destino,
  });

  final String name;
  final String phone;
  final String? email;
  final String? destino;

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'email': email,
        'destino': destino,
      };

  @override
  List<Object?> get props => [name, phone, email, destino];
}