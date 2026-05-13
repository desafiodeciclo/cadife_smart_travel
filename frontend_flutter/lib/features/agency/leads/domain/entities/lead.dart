import 'package:equatable/equatable.dart';

class Lead extends Equatable {
  const Lead({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    required this.score,
    required this.completudePct,
    this.ayaAtivo = true,
    this.email,
    this.origem,
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
    this.consultorNome,
    this.consultorAvatar,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final bool ayaAtivo;
  final LeadOrigem? origem;
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
  final String? consultorNome;
  final String? consultorAvatar;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    email: json['email'] as String?,
    ayaAtivo: json['aya_ativo'] as bool? ?? true,
    origem: json['origem'] != null ? LeadOrigem.fromSnakeCase(json['origem'] as String) : null,
    status: LeadStatus.fromSnakeCase(json['status'] as String? ?? 'novo'),
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'aya_ativo': ayaAtivo,
    'status': status.name.replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}'),
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

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    status,
    score,
    completudePct,
    ayaAtivo,
    assignedTo,
    consultorNome,
    consultorAvatar,
    imageUrl,
  ];
}

enum LeadStatus {
  novo,
  emAtendimento,
  qualificado,
  agendado,
  proposta,
  fechado,
  perdido;

  static LeadStatus fromSnakeCase(String value) {
    return LeadStatus.values.firstWhere(
      (e) => e.name == value || 
             e.name.replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}') == value,
      orElse: () => LeadStatus.novo,
    );
  }

  String toSnakeCase() {
    return name.replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}');
  }
}

enum LeadScore { quente, morno, frio }

enum LeadOrigem {
  indicacao('Indicação'),
  telefone('Telefone'),
  presencial('Presencial'),
  redeSocial('Rede Social'),
  outro('Outro'),
  manual('Manual');

  final String label;
  const LeadOrigem(this.label);

  static LeadOrigem fromSnakeCase(String value) {
    return LeadOrigem.values.firstWhere(
      (e) => e.name == value || 
             e.name.replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}') == value,
      orElse: () => LeadOrigem.manual,
    );
  }

  String toSnakeCase() {
    return name.replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}');
  }
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

class ManualLeadCreate extends Equatable {
  const ManualLeadCreate({
    required this.name,
    required this.phone,
    this.email,
    this.origem = LeadOrigem.manual,
    this.consultorId,
    this.forceCreate = false,
    this.destino,
    this.dataIda,
    this.numPessoas,
    this.orcamentoFaixa,
    this.preferencias,
  });

  final String name;
  final String phone;
  final String? email;
  final LeadOrigem origem;
  final String? consultorId;
  final bool forceCreate;
  
  // Briefing inicial (opcional na criação manual)
  final String? destino;
  final DateTime? dataIda;
  final int? numPessoas;
  final String? orcamentoFaixa;
  final String? preferencias;

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
    'origem': origem.toSnakeCase(),
    'consultor_id': consultorId,
    'force_create': forceCreate,
    'destino': destino,
    'data_ida': dataIda?.toIso8601String(),
    'num_pessoas': numPessoas,
    'orcamento_faixa': orcamentoFaixa,
    'preferencias': preferencias,
  };

  @override
  List<Object?> get props => [
    name, 
    phone, 
    email, 
    origem, 
    consultorId, 
    forceCreate,
    destino,
    dataIda,
    numPessoas,
    orcamentoFaixa,
    preferencias,
  ];
}

