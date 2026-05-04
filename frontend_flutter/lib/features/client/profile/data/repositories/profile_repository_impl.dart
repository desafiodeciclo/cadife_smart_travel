import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/core/offline/offline_manager.dart';
import 'package:cadife_smart_travel/features/auth/domain/entities/auth_user.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/repositories/i_profile_repository.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

class ProfileRepositoryImpl implements IProfileRepository {
  ProfileRepositoryImpl({required Dio dio, required OfflineManager offlineManager})
    : _dio = dio,
      _offlineManager = offlineManager;

  final Dio _dio;
  final OfflineManager _offlineManager;

  static const _cacheKey = 'profile:me';

  @override
  Future<Either<Failure, AuthUser>> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      final user = AuthUser.fromJson(response.data as Map<String, dynamic>);

      await _offlineManager.saveToCache(_cacheKey, response.data);
      return Right(user);
    } on DioException catch (e) {
      final cached = _offlineManager.getFromCacheOffline(_cacheKey);
      if (cached != null) {
        return Right(AuthUser.fromJson(cached as Map<String, dynamic>));
      }
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> updateProfile({
    String? name,
    List<String>? tipoViagem,
    List<String>? preferencias,
    bool? temPassaporte,
  }) async {
    try {
      final response = await _dio.patch(
        ApiConstants.me,
        data: {
          'nome': name,
          'tipo_viagem': tipoViagem,
          'preferencias': preferencias,
          'tem_passaporte': temPassaporte,
        }..removeWhere((_, v) => v == null),
      );
      final user = AuthUser.fromJson(response.data as Map<String, dynamic>);

      await _offlineManager.saveToCache(_cacheKey, response.data);
      return Right(user);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
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





