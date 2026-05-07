import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/client/status/domain/entities/client_travel_status.dart';
import 'package:fpdart/fpdart.dart';

abstract class IStatusRepository {
  Future<Either<Failure, ClientTravelStatus?>> getMyStatus();
  Future<Either<Failure, ClientTravelStatus?>> getStatusById(String id);
}
