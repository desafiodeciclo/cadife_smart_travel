import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/core/offline/offline_manager.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/briefing.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/repositories/lead_port.dart';
import 'package:cadife_smart_travel/features/client/historico/domain/entities/interacao.dart';
import 'package:dio/dio.dart';

class LeadRepositoryImpl implements LeadPort {
  LeadRepositoryImpl({required Dio dio, required OfflineManager offlineManager})
    : _dio = dio,
      _offlineManager = offlineManager;

  final Dio _dio;
  final OfflineManager _offlineManager;

  static const _cacheKeyPrefix = 'leads';

  @override
  Future<List<Lead>> getLeads({
    LeadStatus? status,
    LeadScore? score,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.leads,
        queryParameters: {
          if (status != null) 'status': status.name,
          if (score != null) 'score': score.name,
        },
      );
      final leads = (response.data as List)
          .map((e) => Lead.fromJson(e as Map<String, dynamic>))
          .toList();

      await _offlineManager.saveToCache(
        '$_cacheKeyPrefix:list:${status?.name ?? "all"}:${score?.name ?? "all"}',
        response.data,
      );
      return leads;
    } on DioException {
      final cached = _offlineManager.getFromCacheOffline(
        '$_cacheKeyPrefix:list:${status?.name ?? "all"}:${score?.name ?? "all"}',
      );
      if (cached != null) {
        return (cached as List)
            .map((e) => Lead.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }
  }

  @override
  Future<Lead> getLeadById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.leadById(id));
      final lead = Lead.fromJson(response.data as Map<String, dynamic>);

      await _offlineManager.saveToCache(
        '$_cacheKeyPrefix:detail:$id',
        response.data,
      );
      return lead;
    } on DioException {
      final cached = _offlineManager.getFromCacheOffline(
        '$_cacheKeyPrefix:detail:$id',
      );
      if (cached != null) {
        return Lead.fromJson(cached as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  @override
  Future<Lead> updateLeadStatus(String id, LeadStatus newStatus) async {
    final response = await _dio.patch(
      ApiConstants.leadById(id),
      data: {'status': newStatus.name},
    );
    final lead = Lead.fromJson(response.data as Map<String, dynamic>);

    await _offlineManager.saveToCache(
      '$_cacheKeyPrefix:detail:$id',
      response.data,
    );
    await _offlineManager.invalidateByPrefix('$_cacheKeyPrefix:list:');
    return lead;
  }

  @override
  Future<Briefing> getBriefing(String leadId) async {
    try {
      final response = await _dio.get(ApiConstants.leadBriefing(leadId));
      final briefing = Briefing.fromJson(
        response.data as Map<String, dynamic>,
      );

      await _offlineManager.saveToCache('briefing:$leadId', response.data);
      return briefing;
    } on DioException {
      final cached = _offlineManager.getFromCacheOffline('briefing:$leadId');
      if (cached != null) {
        return Briefing.fromJson(cached as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  @override
  Future<List<Interacao>> getInteractions(String leadId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.leadById(leadId)}/interactions',
      );
      final interactions = (response.data as List)
          .map((e) => Interacao.fromJson(e as Map<String, dynamic>))
          .toList();

      await _offlineManager.saveToCache('interactions:$leadId', response.data);
      return interactions;
    } on DioException {
      final cached = _offlineManager.getFromCacheOffline(
        'interactions:$leadId',
      );
      if (cached != null) {
        return (cached as List)
            .map((e) => Interacao.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }
  }

  @override
  Future<Lead> createLead(CreateLeadRequest request) async {
    final response = await _dio.post(
      ApiConstants.leads,
      data: request.toJson(),
    );
    final lead = Lead.fromJson(response.data as Map<String, dynamic>);

    await _offlineManager.invalidateByPrefix('$_cacheKeyPrefix:list:');
    return lead;
  }

  @override
  Future<Lead?> getMyLead() async {
    try {
      final response = await _dio.get('${ApiConstants.leads}/my-active');
      final lead = Lead.fromJson(response.data as Map<String, dynamic>);

      await _offlineManager.saveToCache(
        '$_cacheKeyPrefix:my-active',
        response.data,
      );
      return lead;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;

      final cached = _offlineManager.getFromCacheOffline(
        '$_cacheKeyPrefix:my-active',
      );
      if (cached != null) {
        return Lead.fromJson(cached as Map<String, dynamic>);
      }
      rethrow;
    }
  }
}




