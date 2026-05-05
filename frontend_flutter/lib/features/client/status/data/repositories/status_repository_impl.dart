import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/client/status/data/datasources/status_datasource.dart';
import 'package:cadife_smart_travel/features/client/status/domain/entities/client_travel_status.dart';
import 'package:cadife_smart_travel/features/client/status/domain/repositories/i_status_repository.dart';
import 'package:fpdart/fpdart.dart';

class StatusRepositoryImpl implements IStatusRepository {
  const StatusRepositoryImpl(this._datasource);

  final IStatusDatasource _datasource;

  @override
  Future<Either<Failure, ClientTravelStatus?>> getMyStatus() async {
    try {
      final result = await _datasource.getMyStatus();
      return Right(result);
    } on Exception catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, ClientTravelStatus?>> getStatusById(String id) async {
    try {
      final result = await _datasource.getStatusById(id);
      return Right(result);
    } on Exception catch (e) {
      return Left(Failure.fromException(e));
    }
  }
}
