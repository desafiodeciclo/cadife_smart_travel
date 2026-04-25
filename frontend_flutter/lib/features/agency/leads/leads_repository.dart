import 'package:cadife_smart_travel/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Lead {
  final String id;
  final String? nome;
  final String telefone;
  final String status;
  final String? score;
  final int? completudePct;
  final String criadoEm;

  const Lead({
    required this.id,
    this.nome,
    required this.telefone,
    required this.status,
    this.score,
    this.completudePct,
    required this.criadoEm,
  });

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
    id: json['id'],
    nome: json['nome'],
    telefone: json['telefone'],
    status: json['status'],
    score: json['score'],
    completudePct: json['completude_pct'],
    criadoEm: json['criado_em'],
  );
}

class LeadsRepository {
  final ApiService _api;
  LeadsRepository(this._api);
  Future<List<Lead>> getLeads({String? status, String? score, String? search, int page = 1}) async {
    final response = await _api.get('/leads', queryParameters: {
      if (status != null) 'status': status,
      if (score != null) 'score': score,
      if (search != null) 'search': search,
      'page': page,
      'limit': 20,
    });

    final items = response.data['items'] as List;
    return items.map((e) => Lead.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getLeadDetail(String id) async {
    final response = await _api.get('/leads/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateLeadStatus(String id, String status) async {
    await _api.put('/leads/$id', data: {'status': status});
  }

  Future<void> archiveLead(String id) async {
    await _api.delete('/leads/$id');
  }
}

final leadsRepositoryProvider = Provider<LeadsRepository>((ref) {
  return LeadsRepository(ref.watch(apiServiceProvider));
});
