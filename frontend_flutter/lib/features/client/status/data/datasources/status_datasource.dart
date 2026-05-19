import 'package:cadife_smart_travel/features/client/status/domain/entities/client_travel_status.dart';

abstract class IStatusDatasource {
  Future<ClientTravelStatus?> getMyStatus();
  Future<ClientTravelStatus?> getStatusById(String id);
}
