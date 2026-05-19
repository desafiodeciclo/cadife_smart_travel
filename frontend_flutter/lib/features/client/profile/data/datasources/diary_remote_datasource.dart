import 'package:cadife_smart_travel/features/client/profile/domain/entities/diary_entry.dart';
import 'package:dio/dio.dart';

/// Datasource remoto do Diário de Viagem.
///
/// Mapeia o schema `DiaryEntryRead` do backend para a entidade [DiaryEntry].
class DiaryRemoteDatasource {
  DiaryRemoteDatasource(this._dio);

  final Dio _dio;

  /// Memórias de uma viagem específica — GET /leads/{leadId}/diary/entries.
  Future<List<DiaryEntry>> listByTrip(String leadId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/leads/$leadId/diary/entries',
    );
    return _parseEntries(res.data, fallbackTripId: leadId);
  }

  /// Linha do tempo completa do usuário — GET /users/me/diary.
  Future<List<DiaryEntry>> listMyTimeline() async {
    final res = await _dio.get<Map<String, dynamic>>('/users/me/diary');
    return _parseEntries(res.data, fallbackTripId: '');
  }

  List<DiaryEntry> _parseEntries(
    Map<String, dynamic>? data, {
    required String fallbackTripId,
  }) {
    final raw = (data?['entries'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    return raw.map((e) => _fromJson(e, fallbackTripId)).toList();
  }

  DiaryEntry _fromJson(Map<String, dynamic> json, String fallbackTripId) {
    final criadoEm = DateTime.tryParse(json['criado_em'] as String? ?? '') ??
        DateTime.now();
    final dataEntrada =
        DateTime.tryParse(json['data_entrada'] as String? ?? '') ?? criadoEm;
    return DiaryEntry(
      id: json['id'] as String,
      tripId: (json['lead_id'] as String?) ?? fallbackTripId,
      photoUrl: (json['foto_url'] as String?) ?? '',
      note: (json['nota'] as String?) ?? '',
      date: dataEntrada,
      createdAt: criadoEm,
      updatedAt: criadoEm,
    );
  }
}
