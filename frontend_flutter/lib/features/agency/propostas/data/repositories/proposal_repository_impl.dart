import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/core/offline/offline_manager.dart';
import 'package:cadife_smart_travel/features/agency/propostas/domain/entities/proposta.dart';
import 'package:cadife_smart_travel/features/agency/propostas/domain/repositories/i_proposals_repository.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

class ProposalRepositoryImpl implements IProposalsRepository {
  ProposalRepositoryImpl({
    required Dio dio,
    required OfflineManager offlineManager,
  }) : _dio = dio,
       _offlineManager = offlineManager;

  final Dio _dio;
  final OfflineManager _offlineManager;

  static const _cacheKeyPrefix = 'proposals';

  @override
  Future<Either<Failure, List<Proposta>>> getProposals({
    String? leadId,
    ProposalStatus? status,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.proposals,
        queryParameters: {
          'lead_id': leadId,
          if (status != null) 'status': status.name,
        },
      );
      final items = (response.data as List)
          .map((e) => Proposta.fromJson(e as Map<String, dynamic>))
          .toList();

      await _offlineManager.saveToCache(
        '$_cacheKeyPrefix:list:${leadId ?? 'all'}:${status?.name ?? 'all'}',
        response.data,
      );
      return Right(items);
    } on DioException catch (e) {
      final cached = _offlineManager.getFromCacheOffline(
        '$_cacheKeyPrefix:list:${leadId ?? 'all'}:${status?.name ?? 'all'}',
      );
      if (cached != null) {
        return Right((cached as List)
            .map((e) => Proposta.fromJson(e as Map<String, dynamic>))
            .toList());
      }
      return Left(_handleDioError(e));
    } on Exception catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Proposta>> getProposalById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.proposalById(id));
      final proposal = Proposta.fromJson(
        response.data as Map<String, dynamic>,
      );

      await _offlineManager.saveToCache(
        '$_cacheKeyPrefix:detail:$id',
        response.data,
      );
      return Right(proposal);
    } on DioException catch (e) {
      final cached = _offlineManager.getFromCacheOffline(
        '$_cacheKeyPrefix:detail:$id',
      );
      if (cached != null) {
        return Right(Proposta.fromJson(cached as Map<String, dynamic>));
      }
      return Left(_handleDioError(e));
    } on Exception catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Proposta>> createProposal(CreateProposalRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.proposals,
        data: request.toJson(),
      );
      final proposal = Proposta.fromJson(
        response.data as Map<String, dynamic>,
      );

      await _offlineManager.invalidateByPrefix('$_cacheKeyPrefix:list:');
      return Right(proposal);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } on Exception catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Proposta>> updateProposal(
    String id,
    UpdateProposalRequest request,
  ) async {
    try {
      final response = await _dio.patch(
        ApiConstants.proposalById(id),
        data: request.toJson(),
      );
      final proposal = Proposta.fromJson(
        response.data as Map<String, dynamic>,
      );

      await _offlineManager.saveToCache(
        '$_cacheKeyPrefix:detail:$id',
        response.data,
      );
      await _offlineManager.invalidateByPrefix('$_cacheKeyPrefix:list:');
      return Right(proposal);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } on Exception catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProposal(String id) async {
    try {
      await _dio.delete(ApiConstants.proposalById(id));
      await _offlineManager.removeFromCache('$_cacheKeyPrefix:detail:$id');
      await _offlineManager.invalidateByPrefix('$_cacheKeyPrefix:list:');
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } on Exception catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NetworkFailure();
    }
    if (e.response?.statusCode == 401) {
      return const UnauthorizedFailure();
    }
    return ServerFailure(e.message ?? 'Erro no servidor');
  }
}





