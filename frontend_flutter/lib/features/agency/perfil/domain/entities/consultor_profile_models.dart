import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class ConsultorProfile extends Equatable {
  const ConsultorProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.bio,
    required this.totalSales,
    required this.conversionRate,
    required this.activeMonths,
    this.phone,
    this.avatarUrl,
    this.fotoLocal,
    this.cargo = 'Consultor de Viagens',
    this.agencia = 'Cadife Tour',
    this.dataAtualizacao,
  });

  final String id;
  final String name;
  final String email;
  final String bio;
  final String? phone;
  final String? avatarUrl;
  // Local file path used as optimistic preview before upload completes
  final String? fotoLocal;
  final int totalSales;
  final double conversionRate;
  final int activeMonths;
  final String cargo;
  final String agencia;
  final DateTime? dataAtualizacao;

  ConsultorProfile copyWith({
    String? bio,
    String? avatarUrl,
    String? fotoLocal,
    String? cargo,
    String? agencia,
  }) =>
      ConsultorProfile(
        id: id,
        name: name,
        email: email,
        bio: bio ?? this.bio,
        phone: phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        fotoLocal: fotoLocal,
        totalSales: totalSales,
        conversionRate: conversionRate,
        activeMonths: activeMonths,
        cargo: cargo ?? this.cargo,
        agencia: agencia ?? this.agencia,
        dataAtualizacao: DateTime.now(),
      );

  factory ConsultorProfile.fromJson(Map<String, dynamic> json) =>
      ConsultorProfile(
        id: json['id'] as String? ?? '',
        name: (json['nomeCompleto'] ?? json['name']) as String? ?? '',
        email: json['email'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        phone: (json['telefone'] ?? json['phone']) as String?,
        avatarUrl: (json['fotoUrl'] ?? json['avatar_url']) as String?,
        totalSales: json['total_sales'] as int? ?? 0,
        conversionRate:
            (json['conversion_rate'] as num?)?.toDouble() ?? 0.0,
        activeMonths: json['active_months'] as int? ?? 0,
        cargo: json['cargo'] as String? ?? 'Consultor de Viagens',
        agencia: json['agencia'] as String? ?? 'Cadife Tour',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'bio': bio,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'totalSales': totalSales,
        'conversionRate': conversionRate,
        'activeMonths': activeMonths,
        'cargo': cargo,
        'agencia': agencia,
        'dataAtualizacao': dataAtualizacao?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        bio,
        phone,
        avatarUrl,
        fotoLocal,
        totalSales,
        conversionRate,
        activeMonths,
        cargo,
        agencia,
      ];
}

class ConsultantMetrics extends Equatable {
  const ConsultantMetrics({
    required this.totalLeadsAtendidos,
    required this.taxaConversao,
    required this.receitaGerada,
    required this.leadsAtivosAgora,
    required this.ultimaAtualizacao,
  });

  final int totalLeadsAtendidos;
  final double taxaConversao;
  final double receitaGerada;
  final int leadsAtivosAgora;
  final DateTime ultimaAtualizacao;

  factory ConsultantMetrics.fromJson(Map<String, dynamic> json) =>
      ConsultantMetrics(
        totalLeadsAtendidos:
            (json['totalLeadsAtendidos'] as int?) ?? 0,
        taxaConversao:
            (json['taxaConversao'] as num?)?.toDouble() ?? 0.0,
        receitaGerada:
            (json['receitaGerada'] as num?)?.toDouble() ?? 0.0,
        leadsAtivosAgora: (json['leadsAtivosAgora'] as int?) ?? 0,
        ultimaAtualizacao: DateTime.tryParse(
                json['ultimaAtualizacao'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'totalLeadsAtendidos': totalLeadsAtendidos,
        'taxaConversao': taxaConversao,
        'receitaGerada': receitaGerada,
        'leadsAtivosAgora': leadsAtivosAgora,
        'ultimaAtualizacao': ultimaAtualizacao.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        totalLeadsAtendidos,
        taxaConversao,
        receitaGerada,
        leadsAtivosAgora,
        ultimaAtualizacao,
      ];
}

class SaleGoal extends Equatable {
  const SaleGoal({
    required this.month,
    required this.year,
    required this.target,
    required this.achieved,
    this.receita,
  });

  final int month;
  final int year;
  final int target;
  final int achieved;
  final double? receita;

  double get progressPct =>
      target == 0 ? 0 : (achieved / target).clamp(0, 1);
  bool get isCompleted => achieved >= target;

  factory SaleGoal.fromJson(Map<String, dynamic> json) => SaleGoal(
        month: json['month'] as int? ?? json['mes'] as int? ?? 1,
        year: json['year'] as int? ??
            json['ano'] as int? ??
            DateTime.now().year,
        target:
            json['target'] as int? ?? json['metaLeads'] as int? ?? 0,
        achieved: json['achieved'] as int? ??
            json['realizadoLeads'] as int? ??
            0,
        receita: (json['receita'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'month': month,
        'year': year,
        'target': target,
        'achieved': achieved,
        'receita': receita,
      };

  @override
  List<Object?> get props => [month, year, target, achieved, receita];
}

// Placeholder so other files can import Uint8List via this model file
typedef PhotoBytes = Uint8List;
