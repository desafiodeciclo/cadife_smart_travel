import 'package:cadife_smart_travel/core/constants/api_constants.dart';
import 'package:cadife_smart_travel/core/offline/offline_manager.dart';
import 'package:cadife_smart_travel/core/ports/agenda_port.dart';
import 'package:cadife_smart_travel/shared/models/models.dart';
import 'package:dio/dio.dart';

class AgendaRepositoryImpl implements AgendaPort {
  AgendaRepositoryImpl({required Dio dio, required OfflineManager offlineManager})
      : _dio = dio,
        _offlineManager = offlineManager;

  final Dio _dio;
  final OfflineManager _offlineManager;

  static const _cacheKeyPrefix = 'agenda';

  @override
  Future<List<AgendaModel>> getAgenda({DateTime? date}) async {
    try {
      final response = await _dio.get(
        ApiConstants.agenda,
        queryParameters: {
          if (date != null) 'date': date.toIso8601String(),
        },
      );
      final items = (response.data as List)
          .map((e) => AgendaModel.fromJson(e as Map<String, dynamic>))
          .toList();

      await _offlineManager.saveToCache(
        '$_cacheKeyPrefix:list:${date?.toIso8601String() ?? 'all'}',
        response.data,
      );
      return items;
    } on DioException {
      final cached = _offlineManager.getFromCacheOffline(
        '$_cacheKeyPrefix:list:${date?.toIso8601String() ?? 'all'}',
      );
      if (cached != null) {
        return (cached as List)
            .map((e) => AgendaModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      rethrow;
    }
  }

  @override
  Future<AgendaModel> getAgendaById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.agendaById(id));
      final agenda = AgendaModel.fromJson(response.data as Map<String, dynamic>);

      await _offlineManager.saveToCache('$_cacheKeyPrefix:detail:$id', response.data);
      return agenda;
    } on DioException {
      final cached = _offlineManager.getFromCacheOffline('$_cacheKeyPrefix:detail:$id');
      if (cached != null) {
        return AgendaModel.fromJson(cached as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  @override
  Future<AgendaModel> createAgenda(CreateAgendaRequest request) async {
    final response = await _dio.post(
      ApiConstants.agenda,
      data: request.toJson(),
    );
    final agenda = AgendaModel.fromJson(response.data as Map<String, dynamic>);

    await _offlineManager.invalidateByPrefix('$_cacheKeyPrefix:list:');
    return agenda;
  }

  @override
  Future<AgendaModel> updateAgenda(String id, UpdateAgendaRequest request) async {
    final response = await _dio.patch(
      ApiConstants.agendaById(id),
      data: request.toJson(),
    );
    final agenda = AgendaModel.fromJson(response.data as Map<String, dynamic>);

    await _offlineManager.saveToCache('$_cacheKeyPrefix:detail:$id', response.data);
    await _offlineManager.invalidateByPrefix('$_cacheKeyPrefix:list:');
    return agenda;
  }

  @override
  Future<void> deleteAgenda(String id) async {
    await _dio.delete(ApiConstants.agendaById(id));
    await _offlineManager.removeFromCache('$_cacheKeyPrefix:detail:$id');
    await _offlineManager.invalidateByPrefix('$_cacheKeyPrefix:list:');
  }

  @override
  Future<List<TimeSlotModel>> getAvailableSlots(DateTime date) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.agenda}/slots',
        queryParameters: {'date': date.toIso8601String()},
      );
      final slots = (response.data as List)
          .map((e) => TimeSlotModel(
                startTime: DateTime.parse(e['start_time'] as String),
                endTime: DateTime.parse(e['end_time'] as String),
                available: e['available'] as bool,
              ))
          .toList();

      await _offlineManager.saveToCache(
        '$_cacheKeyPrefix:slots:${date.toIso8601String()}',
        response.data,
      );
      return slots;
    } on DioException {
      final cached = _offlineManager.getFromCacheOffline(
        '$_cacheKeyPrefix:slots:${date.toIso8601String()}',
      );
      if (cached != null) {
        return (cached as List)
            .map((e) => TimeSlotModel(
                  startTime: DateTime.parse(e['start_time'] as String),
                  endTime: DateTime.parse(e['end_time'] as String),
                  available: e['available'] as bool,
                ))
            .toList();
      }
      rethrow;
    }
  }
}