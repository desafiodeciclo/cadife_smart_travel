import 'package:fpdart/fpdart.dart';
import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/core/offline/offline_manager.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/repositories/i_agenda_repository.dart';
import 'package:dio/dio.dart';

class AgendaRepositoryImpl implements IAgendaRepository {
  AgendaRepositoryImpl({
    required Dio dio,
    required OfflineManager offlineManager,
  }) : _dio = dio,
       _offlineManager = offlineManager;

  final Dio _dio;
  final OfflineManager _offlineManager;

  static const _cacheKeyPrefix = 'agenda';

  @override
  Future<Either<Failure, List<Agendamento>>> getAgenda({DateTime? date}) async {
    try {
      final response = await _dio.get(
        ApiConstants.agenda,
        queryParameters: {if (date != null) 'date': date.toIso8601String()},
      );
      final items = (response.data as List)
          .map((e) => Agendamento.fromJson(e as Map<String, dynamic>))
          .toList();

      await _offlineManager.saveToCache(
        '$_cacheKeyPrefix:list:${date?.toIso8601String() ?? 'all'}',
        response.data,
      );
      return Right(items);
    } on DioException catch (e) {
      final cached = _offlineManager.getFromCacheOffline(
        '$_cacheKeyPrefix:list:${date?.toIso8601String() ?? 'all'}',
      );
      if (cached != null) {
        return Right((cached as List)
            .map((e) => Agendamento.fromJson(e as Map<String, dynamic>))
            .toList());
      }
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Agendamento>> getAgendaById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.agendaById(id));
      final agenda = Agendamento.fromJson(
        response.data as Map<String, dynamic>,
      );

      await _offlineManager.saveToCache(
        '$_cacheKeyPrefix:detail:$id',
        response.data,
      );
      return Right(agenda);
    } on DioException catch (e) {
      final cached = _offlineManager.getFromCacheOffline(
        '$_cacheKeyPrefix:detail:$id',
      );
      if (cached != null) {
        return Right(Agendamento.fromJson(cached as Map<String, dynamic>));
      }
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Agendamento>> createAgenda(CreateAgendaRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.agenda,
        data: request.toJson(),
      );
      final agenda = Agendamento.fromJson(response.data as Map<String, dynamic>);

      await _offlineManager.invalidateByPrefix('$_cacheKeyPrefix:list:');
      return Right(agenda);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Agendamento>> updateAgenda(
    String id,
    UpdateAgendaRequest request,
  ) async {
    try {
      final response = await _dio.patch(
        ApiConstants.agendaById(id),
        data: request.toJson(),
      );
      final agenda = Agendamento.fromJson(response.data as Map<String, dynamic>);

      await _offlineManager.saveToCache(
        '$_cacheKeyPrefix:detail:$id',
        response.data,
      );
      await _offlineManager.invalidateByPrefix('$_cacheKeyPrefix:list:');
      return Right(agenda);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAgenda(String id) async {
    try {
      await _dio.delete(ApiConstants.agendaById(id));
      await _offlineManager.removeFromCache('$_cacheKeyPrefix:detail:$id');
      await _offlineManager.invalidateByPrefix('$_cacheKeyPrefix:list:');
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TimeSlotModel>>> getAvailableSlots(DateTime date) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.agenda}/slots',
        queryParameters: {'date': date.toIso8601String()},
      );
      final slots = (response.data as List)
          .map(
            (e) => TimeSlotModel(
              startTime: DateTime.parse(e['start_time'] as String),
              endTime: DateTime.parse(e['end_time'] as String),
              available: e['available'] as bool,
            ),
          )
          .toList();

      await _offlineManager.saveToCache(
        '$_cacheKeyPrefix:slots:${date.toIso8601String()}',
        response.data,
      );
      return Right(slots);
    } on DioException catch (e) {
      final cached = _offlineManager.getFromCacheOffline(
        '$_cacheKeyPrefix:slots:${date.toIso8601String()}',
      );
      if (cached != null) {
        return Right((cached as List)
            .map(
              (e) => TimeSlotModel(
                startTime: DateTime.parse(e['start_time'] as String),
                endTime: DateTime.parse(e['end_time'] as String),
                available: e['available'] as bool,
              ),
            )
            .toList());
      }
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





