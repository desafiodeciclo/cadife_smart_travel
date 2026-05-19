import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/features/admin/domain/entities/admin_entities.dart';
import 'package:dio/dio.dart';

/// Repositório admin real — consome os endpoints `/admin/*` do backend.
class AdminRepository {
  AdminRepository(this._dio);

  final Dio _dio;

  String get _base => ApiConstants.baseUrl;

  ConsultorAdmin _mapUser(Map<String, dynamic> json) {
    final metrics = (json['metrics'] as Map<String, dynamic>?) ?? const {};
    final total = (metrics['total_leads'] as int?) ?? 0;
    final closed = (metrics['closed_leads'] as int?) ?? 0;
    final active = (metrics['active_leads'] as int?) ?? 0;
    final conversao = total > 0 ? closed / total : 0.0;
    return ConsultorAdmin(
      id: json['id'] as String,
      name: json['nome'] as String? ?? '',
      email: json['email'] as String,
      phone: json['telefone'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      leadsAtivos: active,
      taxaConversao: conversao,
      totalLeadsAtendidos: total,
    );
  }

  Future<List<ConsultorAdmin>> getConsultores() async {
    final res = await _dio.get<Map<String, dynamic>>('$_base/admin/users');
    final items = (res.data!['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    return items.map(_mapUser).toList();
  }

  Future<ConsultorAdmin?> getConsultorById(String id) async {
    final all = await getConsultores();
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<ConsultorAdmin> toggleConsultorStatus(String id) async {
    final current = await getConsultorById(id);
    if (current == null) throw Exception('Consultor não encontrado');
    final res = await _dio.patch<Map<String, dynamic>>(
      '$_base/admin/users/$id',
      data: {'is_active': !current.isActive},
    );
    return _mapUser(res.data!);
  }

  Future<ConsultorAdmin> createConsultor({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/admin/users',
      data: {
        'nome': name,
        'email': email,
        'telefone': phone,
      },
    );
    return _mapUser(res.data!);
  }

  Future<ConsultorAdmin> updateConsultor(ConsultorAdmin consultor) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '$_base/admin/users/${consultor.id}',
      data: {
        'nome': consultor.name,
        'email': consultor.email,
        'telefone': consultor.phone,
        'is_active': consultor.isActive,
      },
    );
    return _mapUser(res.data!);
  }

  Future<void> deleteConsultor(String id) async {
    await _dio.delete<void>('$_base/admin/users/$id');
  }

  Future<AgenciaMetrics> getMetrics() async {
    final consultores = await getConsultores();
    var totalLeadsAtivos = 0;
    var totalLeadsAtendidos = 0;
    var somaTaxaConversao = 0.0;
    var consultoresAtivos = 0;
    for (final c in consultores) {
      totalLeadsAtivos += c.leadsAtivos;
      totalLeadsAtendidos += c.totalLeadsAtendidos ?? 0;
      somaTaxaConversao += c.taxaConversao;
      if (c.isActive) consultoresAtivos++;
    }
    final media =
        consultores.isEmpty ? 0.0 : somaTaxaConversao / consultores.length;
    return AgenciaMetrics(
      totalLeads: totalLeadsAtivos,
      taxaConversao: media,
      receitaEstimada: 0,
      consultoresAtivos: consultoresAtivos,
      leadsNovosMes: 0,
      leadsFechadosMes: totalLeadsAtendidos,
      leadsPerdidosMes: 0,
    );
  }
}
