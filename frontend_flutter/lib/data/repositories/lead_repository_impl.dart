import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/core/offline/offline_manager.dart';
import 'package:cadife_smart_travel/core/ports/lead_port.dart';
import 'package:cadife_smart_travel/shared/models/models.dart';
import 'package:dio/dio.dart';

class LeadRepositoryImpl implements LeadPort {
  LeadRepositoryImpl({required Dio dio, required OfflineManager offlineManager})
      : _dio = dio,
        _offlineManager = offlineManager;

  final Dio _dio;
  final OfflineManager _offlineManager;

  static const _cacheKeyPrefix = 'leads';

  @override
  Future<List<LeadModel>> getLeads({LeadStatus? status, LeadScore? score}) async {
    try {
      final response = await _dio.get(
        ApiConstants.leads,
        queryParameters: {
          if (status != null) 'status': status.name,
          if (score != null) 'score': score.name,
        },
      );
      final leads = (response.data as List)
          .map((e) => LeadModel.fromJson(e as Map<String, dynamic>))
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
            .map((e) => LeadModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }
  }

  @override
  Future<LeadModel> getLeadById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.leadById(id));
      final lead = LeadModel.fromJson(response.data as Map<String, dynamic>);

      await _offlineManager.saveToCache('$_cacheKeyPrefix:detail:$id', response.data);
      return lead;
    } on DioException {
      final cached = _offlineManager.getFromCacheOffline('$_cacheKeyPrefix:detail:$id');
      if (cached != null) {
        return LeadModel.fromJson(cached as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  @override
  Future<LeadModel> updateLeadStatus(String id, LeadStatus newStatus) async {
    final response = await _dio.patch(
      ApiConstants.leadById(id),
      data: {'status': newStatus.name},
    );
    final lead = LeadModel.fromJson(response.data as Map<String, dynamic>);

    await _offlineManager.saveToCache('$_cacheKeyPrefix:detail:$id', response.data);
    await _offlineManager.invalidateByPrefix('$_cacheKeyPrefix:list:');
    return lead;
  }

  @override
  Future<BriefingModel> getBriefing(String leadId) async {
    try {
      final response = await _dio.get(ApiConstants.leadBriefing(leadId));
      final briefing = BriefingModel.fromJson(response.data as Map<String, dynamic>);

      await _offlineManager.saveToCache('briefing:$leadId', response.data);
      return briefing;
    } on DioException {
      final cached = _offlineManager.getFromCacheOffline('briefing:$leadId');
      if (cached != null) {
        return BriefingModel.fromJson(cached as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  @override
  Future<List<InteractionModel>> getInteractions(String leadId) async {
    try {
      final response = await _dio.get('${ApiConstants.leadById(leadId)}/interactions');
      final interactions = (response.data as List)
          .map((e) => InteractionModel.fromJson(e as Map<String, dynamic>))
          .toList();

      await _offlineManager.saveToCache('interactions:$leadId', response.data);
      return interactions;
    } on DioException {
      final cached = _offlineManager.getFromCacheOffline('interactions:$leadId');
      if (cached != null) {
        return (cached as List)
            .map((e) => InteractionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }
  }

  @override
  Future<LeadModel> createLead(CreateLeadRequest request) async {
    final response = await _dio.post(
      ApiConstants.leads,
      data: request.toJson(),
    );
    final lead = LeadModel.fromJson(response.data as Map<String, dynamic>);

    await _offlineManager.invalidateByPrefix('$_cacheKeyPrefix:list:');
    return lead;
  }
}