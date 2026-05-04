import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/core/offline/offline_event.dart';
import 'package:fpdart/fpdart.dart';

abstract class IOfflineEventRepository {
  Future<Either<Failure, void>> insertEvent(OfflineEvent event);
  Future<Either<Failure, List<OfflineEvent>>> getUnsyncedEvents();
  Future<Either<Failure, void>> markAsSynced(int id);
}
