import 'dart:typed_data';

import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/perfil/domain/entities/consultor_profile_models.dart';
import 'package:cadife_smart_travel/features/agency/perfil/domain/repositories/i_consultor_repository.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

class ConsultorRepositoryImpl implements IConsultorRepository {
  ConsultorRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, ConsultorProfile>> getProfile() async {
    try {
      final response = await _dio.get('/users/me');
      return Right(
        ConsultorProfile.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } on Exception catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ConsultorProfile>> updateBio(String bio) async {
    try {
      final response = await _dio.patch('/users/me/bio', data: {'bio': bio});
      return Right(
        ConsultorProfile.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } on Exception catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ConsultantMetrics>> getMetrics() async {
    try {
      final response = await _dio.get('/users/me/metrics');
      return Right(
        ConsultantMetrics.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } on Exception catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SaleGoal>>> getGoals() async {
    try {
      final response =
          await _dio.get('/users/me/goals', queryParameters: {'months': 3});
      final data = response.data as Map<String, dynamic>;
      final list = (data['goals'] as List<dynamic>)
          .map((e) => SaleGoal.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } on Exception catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ConsultorProfile>> uploadPhoto(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });
      final response =
          await _dio.patch('/users/me/profile-photo', data: formData);
      return Right(
        ConsultorProfile.fromJson(response.data as Map<String, dynamic>),
      );
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
    if (e.response?.statusCode == 401) return const UnauthorizedFailure();
    return ServerFailure(e.message ?? 'Erro no servidor');
  }
}
