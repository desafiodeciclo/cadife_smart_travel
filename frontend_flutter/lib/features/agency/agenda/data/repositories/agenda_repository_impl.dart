import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/core/offline/offline_manager.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/entities/agendamento.dart';
import 'package:cadife_smart_travel/features/agency/agenda/domain/repositories/i_agenda_repository.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

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
    // Backend canonical query param is `data` (PT). The legacy `date` (EN)
    // is still accepted server-side but emits a deprecation warning — we
    // already use `data` here so no warning is raised.
    final dataParam = date != null
        ? '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
        : null;
    try {
      final response = await _dio.get(
        ApiConstants.agenda,
        queryParameters: {'data': ?dataParam},
      );
      // Backend now returns AgendamentoListResponse: { items, total, data }
      // Old contract returned a bare list — accept both for transition period.
      final raw = response.data;
      final List<dynamic> rawItems = raw is Map<String, dynamic>
          ? (raw['items'] as List<dynamic>? ?? const <dynamic>[])
          : (raw as List<dynamic>);
      final items = rawItems
          .map((e) => Agendamento.fromJson(e as Map<String, dynamic>))
          .toList();

      await _offlineManager.saveToCache(
        '$_cacheKeyPrefix:list:${dataParam ?? 'all'}',
        rawItems,
      );
      return Right(items);
    } on DioException catch (e) {
      final cached = _offlineManager.getFromCacheOffline(
        '$_cacheKeyPrefix:list:${dataParam ?? 'all'}',
      );
      if (cached != null) {
        return Right((cached as List)
            .map((e) => Agendamento.fromJson(e as Map<String, dynamic>))
            .toList());
      }
      return Left(_handleDioError(e));
    } on Exception catch (e) {
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
    } on Exception catch (e) {
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
    } on Exception catch (e) {
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
    } on Exception catch (e) {
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
    } on Exception catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TimeSlotModel>>> getAvailableSlots(DateTime date) async {
    // Canonical endpoint is /agenda/disponibilidade. The legacy /agenda/slots
    // is kept as a deprecated alias on the backend; we already migrated here.
    final dataParam =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      final response = await _dio.get(
        '${ApiConstants.agenda}/disponibilidade',
        queryParameters: {'data': dataParam},
      );
      // Backend payload: { "slots": [{ "data", "hora": "HH:00", "disponivel": bool }] }
      final raw = response.data;
      final slotsList = raw is Map<String, dynamic>
          ? (raw['slots'] as List<dynamic>? ?? const <dynamic>[])
          : (raw as List<dynamic>);
      final slots = slotsList
          .map((e) => _slotFromBackend(e as Map<String, dynamic>, date))
          .toList();

      await _offlineManager.saveToCache(
        '$_cacheKeyPrefix:slots:$dataParam',
        slotsList,
      );
      return Right(slots);
    } on DioException catch (e) {
      final cached = _offlineManager.getFromCacheOffline(
        '$_cacheKeyPrefix:slots:$dataParam',
      );
      if (cached != null) {
        return Right((cached as List)
            .map((e) => _slotFromBackend(e as Map<String, dynamic>, date))
            .toList());
      }
      return Left(_handleDioError(e));
    } on Exception catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  /// Maps the backend `SlotDisponivel` shape (data + hora "HH:00" + disponivel)
  /// to the front's `TimeSlotModel` (startTime + endTime + available).
  /// Slot duration is the canonical 60min step from spec §8.1.
  TimeSlotModel _slotFromBackend(Map<String, dynamic> e, DateTime referenceDate) {
    final hora = e['hora'] as String; // "HH:MM"
    final parts = hora.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
    final start = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
      hour,
      minute,
    );
    final end = start.add(const Duration(hours: 1));
    return TimeSlotModel(
      startTime: start,
      endTime: end,
      available: e['disponivel'] as bool? ?? false,
    );
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
    if (e.response?.statusCode == 409) {
      final detail = e.response?.data?['detail'] as String?;
      return ConflictFailure(detail ?? 'Conflito: Horário já ocupado.');
    }
    return ServerFailure(e.message ?? 'Erro no servidor');
  }
}





