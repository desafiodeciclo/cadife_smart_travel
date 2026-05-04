import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/perfil/domain/entities/consultor_profile_models.dart';
import 'package:cadife_smart_travel/features/agency/perfil/domain/repositories/i_consultor_repository.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

class ConsultorRepositoryImpl implements IConsultorRepository {
  final Dio _dio;

  ConsultorRepositoryImpl(this._dio);

  @override
  Future<Either<Failure, ConsultorProfile>> getProfile() async {
    try {
      final response = await _dio.get('/consultor/profile');
      return Right(ConsultorProfile.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ConsultorProfile>> updateBio(String bio) async {
    try {
      final response = await _dio.put('/consultor/profile', data: {'bio': bio});
      return Right(ConsultorProfile.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SaleGoal>>> getGoals() async {
    try {
      final response = await _dio.get('/consultor/goals');
      final list = (response.data as List)
          .map((e) => SaleGoal.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(list);
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
