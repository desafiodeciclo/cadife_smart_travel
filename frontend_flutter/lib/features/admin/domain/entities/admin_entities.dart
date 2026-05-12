import 'package:equatable/equatable.dart';

class ConsultorAdmin extends Equatable {
  const ConsultorAdmin({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.isActive,
    required this.leadsAtivos,
    required this.taxaConversao,
    this.avatarUrl,
    this.totalLeadsAtendidos,
    this.receitaGerada,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final bool isActive;
  final int leadsAtivos;
  final double taxaConversao;
  final String? avatarUrl;
  final int? totalLeadsAtendidos;
  final double? receitaGerada;

  ConsultorAdmin copyWith({
    String? name,
    String? email,
    String? phone,
    bool? isActive,
    int? leadsAtivos,
    double? taxaConversao,
    String? avatarUrl,
    int? totalLeadsAtendidos,
    double? receitaGerada,
  }) => ConsultorAdmin(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    isActive: isActive ?? this.isActive,
    leadsAtivos: leadsAtivos ?? this.leadsAtivos,
    taxaConversao: taxaConversao ?? this.taxaConversao,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    totalLeadsAtendidos: totalLeadsAtendidos ?? this.totalLeadsAtendidos,
    receitaGerada: receitaGerada ?? this.receitaGerada,
  );

  factory ConsultorAdmin.fromJson(Map<String, dynamic> json) => ConsultorAdmin(
    id: json['id'] as String,
    name: json['name'] as String? ?? json['nome'] as String? ?? '',
    email: json['email'] as String,
    phone: json['phone'] as String? ?? json['telefone'] as String? ?? '',
    isActive: json['is_active'] as bool? ?? json['ativo'] as bool? ?? true,
    leadsAtivos: json['leads_ativos'] as int? ?? 0,
    taxaConversao: (json['taxa_conversao'] as num?)?.toDouble() ?? 0.0,
    avatarUrl: json['avatar_url'] as String?,
    totalLeadsAtendidos: json['total_leads_atendidos'] as int?,
    receitaGerada: (json['receita_gerada'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'is_active': isActive,
    'leads_ativos': leadsAtivos,
    'taxa_conversao': taxaConversao,
    'avatar_url': avatarUrl,
    'total_leads_atendidos': totalLeadsAtendidos,
    'receita_gerada': receitaGerada,
  };

  @override
  List<Object?> get props => [id, name, email, phone, isActive, leadsAtivos, taxaConversao];
}

class AgenciaMetrics extends Equatable {
  const AgenciaMetrics({
    required this.totalLeads,
    required this.taxaConversao,
    required this.receitaEstimada,
    required this.consultoresAtivos,
    required this.leadsNovosMes,
    required this.leadsFechadosMes,
    required this.leadsPerdidosMes,
  });

  final int totalLeads;
  final double taxaConversao;
  final double receitaEstimada;
  final int consultoresAtivos;
  final int leadsNovosMes;
  final int leadsFechadosMes;
  final int leadsPerdidosMes;

  factory AgenciaMetrics.fromJson(Map<String, dynamic> json) => AgenciaMetrics(
    totalLeads: json['total_leads'] as int? ?? 0,
    taxaConversao: (json['taxa_conversao'] as num?)?.toDouble() ?? 0.0,
    receitaEstimada: (json['receita_estimada'] as num?)?.toDouble() ?? 0.0,
    consultoresAtivos: json['consultores_ativos'] as int? ?? 0,
    leadsNovosMes: json['leads_novos_mes'] as int? ?? 0,
    leadsFechadosMes: json['leads_fechados_mes'] as int? ?? 0,
    leadsPerdidosMes: json['leads_perdidos_mes'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'total_leads': totalLeads,
    'taxa_conversao': taxaConversao,
    'receita_estimada': receitaEstimada,
    'consultores_ativos': consultoresAtivos,
    'leads_novos_mes': leadsNovosMes,
    'leads_fechados_mes': leadsFechadosMes,
    'leads_perdidos_mes': leadsPerdidosMes,
  };

  @override
  List<Object?> get props => [
    totalLeads, taxaConversao, receitaEstimada, consultoresAtivos,
    leadsNovosMes, leadsFechadosMes, leadsPerdidosMes,
  ];
}
