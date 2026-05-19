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
    super.ayaAtivo = true,
    super.origem,
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
    // Backend list endpoint uses Portuguese field names (nome, telefone_mascarado,
    // criado_em, atualizado_em). Detail endpoint may use English names. Accept both.
    final id = json['id']?.toString() ?? '';
    final name = (json['nome'] ?? json['name'] ?? '') as String;
    final phone = (json['telefone_mascarado'] ?? json['phone'] ?? json['telefone'] ?? '') as String;
    final rawCreatedAt = json['criado_em'] ?? json['created_at'];
    final rawUpdatedAt = json['atualizado_em'] ?? json['updated_at'];
    final rawConsultorId = json['consultor_id']?.toString() ?? json['assigned_to']?.toString();

    return LeadApiModel(
      id: id,
      name: name,
      phone: phone,
      email: json['email'] as String?,
      ayaAtivo: json['aya_ativo'] as bool? ?? true,
      status: LeadStatus.fromSnakeCase(json['status'] as String? ?? 'novo'),
      score: LeadScore.values.firstWhere(
        (e) => e.name == json['score'],
        orElse: () => LeadScore.frio,
      ),
      completudePct: json['completude_pct'] as int? ?? 0,
      origem: json['origem'] != null ? LeadOrigem.fromSnakeCase(json['origem'] as String) : null,
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
      assignedTo: rawConsultorId,
      consultorNome: json['consultor_nome'] as String?,
      consultorAvatar: json['consultor_avatar'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: rawCreatedAt != null ? DateTime.parse(rawCreatedAt as String) : null,
      updatedAt: rawUpdatedAt != null ? DateTime.parse(rawUpdatedAt as String) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'aya_ativo': ayaAtivo,
        'status': status.toSnakeCase(),
        'score': score.name,
        'completude_pct': completudePct,
        'origem': origem?.name,
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

  LeadApiModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    bool? ayaAtivo,
    LeadStatus? status,
    LeadScore? score,
    int? completudePct,
    LeadOrigem? origem,
    String? destino,
    DateTime? dataIda,
    DateTime? dataVolta,
    int? numPessoas,
    String? perfil,
    String? tipoViagem,
    String? preferencias,
    String? orcamentoFaixa,
    bool? passaporteValido,
    bool? experienciaInternacional,
    String? assignedTo,
    String? consultorNome,
    String? consultorAvatar,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeadApiModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      ayaAtivo: ayaAtivo ?? this.ayaAtivo,
      status: status ?? this.status,
      score: score ?? this.score,
      completudePct: completudePct ?? this.completudePct,
      origem: origem ?? this.origem,
      destino: destino ?? this.destino,
      dataIda: dataIda ?? this.dataIda,
      dataVolta: dataVolta ?? this.dataVolta,
      numPessoas: numPessoas ?? this.numPessoas,
      perfil: perfil ?? this.perfil,
      tipoViagem: tipoViagem ?? this.tipoViagem,
      preferencias: preferencias ?? this.preferencias,
      orcamentoFaixa: orcamentoFaixa ?? this.orcamentoFaixa,
      passaporteValido: passaporteValido ?? this.passaporteValido,
      experienciaInternacional: experienciaInternacional ?? this.experienciaInternacional,
      assignedTo: assignedTo ?? this.assignedTo,
      consultorNome: consultorNome ?? this.consultorNome,
      consultorAvatar: consultorAvatar ?? this.consultorAvatar,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
