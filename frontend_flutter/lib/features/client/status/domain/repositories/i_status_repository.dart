import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/features/agency/leads/domain/entities/lead.dart';
import 'package:fpdart/fpdart.dart';

abstract class IStatusRepository {
  Future<Either<Failure, Lead?>> getMyStatus();
  Future<Either<Failure, Lead?>> getStatusById(String id);
}
