import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/core/offline/offline_manager.dart';
import 'package:cadife_smart_travel/core/ports/proposal_port.dart';
import 'package:cadife_smart_travel/shared/models/models.dart';
import 'package:dio/dio.dart';

class ProposalRepositoryImpl implements ProposalPort {
  ProposalRepositoryImpl({required Dio dio, required OfflineManager offlineManager})
      : _dio = dio,
        _offlineManager = offlineManager;

  final Dio _dio;
  final OfflineManager _offlineManager;

  static const _cacheKeyPrefix = 'proposals';

  @override
  Future<List<ProposalModel>> getProposals({
    String? leadId,
    ProposalStatus? status,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.proposals,
        queryParameters: {
          'lead_id': ?leadId,
          if (status != null) 'status': status.name,
        },
      );
      final items = (response.data as List)
          .map((e) => ProposalModel.fromJson(e as Map<String, dynamic>))
          .toList();

      await _offlineManager.saveToCache(
        '$_cacheKeyPrefix:list:${leadId ?? 'all'}:${status?.name ?? 'all'}',
        response.data,
      );
      return items;
    } on DioException {
      final cached = _offlineManager.getFromCacheOffline(
        '$_cacheKeyPrefix:list:${leadId ?? 'all'}:${status?.name ?? 'all'}',
      );
      if (cached != null) {
        return (cached as List)
            .map((e) => ProposalModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }
  }

  @override
  Future<ProposalModel> getProposalById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.proposalById(id));
      final proposal = ProposalModel.fromJson(response.data as Map<String, dynamic>);

      await _offlineManager.saveToCache('$_cacheKeyPrefix:detail:$id', response.data);
      return proposal;
    } on DioException {
      final cached = _offlineManager.getFromCacheOffline('$_cacheKeyPrefix:detail:$id');
      if (cached != null) {
        return ProposalModel.fromJson(cached as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  @override
  Future<ProposalModel> createProposal(CreateProposalRequest request) async {
    final response = await _dio.post(
      ApiConstants.proposals,
      data: request.toJson(),
    );
    final proposal = ProposalModel.fromJson(response.data as Map<String, dynamic>);

    await _offlineManager.invalidateByPrefix('$_cacheKeyPrefix:list:');
    return proposal;
  }

  @override
  Future<ProposalModel> updateProposal(String id, UpdateProposalRequest request) async {
    final response = await _dio.patch(
      ApiConstants.proposalById(id),
      data: request.toJson(),
    );
    final proposal = ProposalModel.fromJson(response.data as Map<String, dynamic>);

    await _offlineManager.saveToCache('$_cacheKeyPrefix:detail:$id', response.data);
    await _offlineManager.invalidateByPrefix('$_cacheKeyPrefix:list:');
    return proposal;
  }

  @override
  Future<void> deleteProposal(String id) async {
    await _dio.delete(ApiConstants.proposalById(id));
    await _offlineManager.removeFromCache('$_cacheKeyPrefix:detail:$id');
    await _offlineManager.invalidateByPrefix('$_cacheKeyPrefix:list:');
  }
}