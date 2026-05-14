import 'package:cadife_smart_travel/features/client/status/data/datasources/status_datasource.dart';
import 'package:cadife_smart_travel/features/client/status/domain/entities/client_travel_status.dart';
import 'package:dio/dio.dart';

class StatusRemoteDatasource implements IStatusDatasource {
  StatusRemoteDatasource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<ClientTravelStatus?> getMyStatus() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/travels',
      queryParameters: {'status': 'ongoing'},
    );
    final data = res.data!;
    final travels = (data['travels'] as List<dynamic>);
    if (travels.isEmpty) {
      // Sem viagem em andamento — tenta buscar a próxima agendada.
      final upcoming = await _dio.get<Map<String, dynamic>>(
        '/travels',
        queryParameters: {'status': 'upcoming'},
      );
      final upcomingList = (upcoming.data!['travels'] as List<dynamic>);
      if (upcomingList.isEmpty) return null;
      return _mapTravel(upcomingList.first as Map<String, dynamic>);
    }
    return _mapTravel(travels.first as Map<String, dynamic>);
  }

  @override
  Future<ClientTravelStatus?> getStatusById(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/travels/$id');
    if (res.data == null) return null;
    return _mapTravel(res.data!);
  }

  ClientTravelStatus _mapTravel(Map<String, dynamic> t) {
    return ClientTravelStatus(
      id: t['id'] as String,
      status: _mapStatus(t['status'] as String?),
      destino: t['destination'] as String?,
      dataPartida: _parseDate(t['start_date']),
      dataRetorno: _parseDate(t['end_date']),
    );
  }

  // Backend usa upcoming/ongoing/completed; Flutter usa enum de pipeline de leads.
  // Mapeamento: ongoing → confirmado, upcoming → agendado, completed → confirmado.
  TravelStatus _mapStatus(String? raw) {
    switch (raw) {
      case 'upcoming':
        return TravelStatus.agendado;
      case 'ongoing':
        return TravelStatus.confirmado;
      case 'completed':
        return TravelStatus.confirmado;
      default:
        return TravelStatus.confirmado;
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value as String);
    } on Exception catch (_) {
      return null;
    }
  }
}
