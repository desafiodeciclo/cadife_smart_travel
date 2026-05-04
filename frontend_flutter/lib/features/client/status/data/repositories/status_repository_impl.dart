import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:cadife_smart_travel/features/client/status/data/datasources/status_datasource.dart';
import 'package:cadife_smart_travel/features/client/status/domain/repositories/i_status_repository.dart';
import 'package:fpdart/fpdart.dart';

class StatusRepositoryImpl implements IStatusRepository {
  final IStatusDatasource _datasource;

  StatusRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, Lead?>> getMyStatus() async {
    try {
      final result = await _datasource.getMyStatus();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lead?>> getStatusById(String id) async {
    try {
      final result = await _datasource.getStatusById(id);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
