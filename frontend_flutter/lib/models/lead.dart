import 'package:equatable/equatable.dart';

class Lead extends Equatable {
  final String id;
  final String nome;
  final String? email;
  final String telefone;
  final String status;
  final double score;
  final DateTime criadoEm;

  const Lead({
    required this.id,
    required this.nome,
    this.email,
    required this.telefone,
    required this.status,
    required this.score,
    required this.criadoEm,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String?,
      telefone: json['telefone'] as String? ?? json['phone'] as String? ?? '',
      status: json['status'] as String? ?? 'novo',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      criadoEm: json['criado_em'] != null 
          ? DateTime.parse(json['criado_em'] as String)
          : (json['created_at'] != null 
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'email': email,
    'telefone': telefone,
    'status': status,
    'score': score,
    'criado_em': criadoEm.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, nome, email, telefone, status, score, criadoEm];
}

class LeadsListResponse extends Equatable {
  final List<Lead> items;
  final int total;
  final int page;
  final int pages;

  const LeadsListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pages,
  });

  factory LeadsListResponse.fromJson(Map<String, dynamic> json) {
    return LeadsListResponse(
      items: (json['items'] as List? ?? [])
          .map((e) => Lead.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pages: json['pages'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [items, total, page, pages];
}
