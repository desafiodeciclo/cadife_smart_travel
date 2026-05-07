import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';

class LeadApiModel extends Lead {
  const LeadApiModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.status,
    required super.score,
    required super.completudePct,
    super.email,
    super.destino,
    super.dataIda,
    super.dataVolta,
    super.numPessoas,
    super.perfil,
    super.tipoViagem,
    super.preferencias,
    super.orcamentoFaixa,
    super.passaporteValido,
    super.experienciaInternacional,
    super.assignedTo,
    super.consultorNome,
    super.consultorAvatar,
    super.imageUrl,
    super.createdAt,
    super.updatedAt,
  });

  factory LeadApiModel.fromJson(Map<String, dynamic> json) {
    return LeadApiModel(
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
      assignedTo: json['assigned_to'] as String? ?? json['consultor_id'] as String?,
      consultorNome: json['consultor_nome'] as String?,
      consultorAvatar: json['consultor_avatar'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  @override
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
        'consultor_nome': consultorNome,
        'consultor_avatar': consultorAvatar,
        'image_url': imageUrl,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
