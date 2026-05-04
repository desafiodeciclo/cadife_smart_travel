import 'package:fpdart/fpdart.dart';
import 'package:cadife_smart_travel/core/error/failures.dart';
import 'package:cadife_smart_travel/data/local/database_helper.dart';
import 'package:cadife_smart_travel/domain/entities/offline_event.dart';
import 'package:cadife_smart_travel/domain/repositories/i_offline_event_repository.dart';

class OfflineEventRepositoryImpl implements IOfflineEventRepository {
  final DatabaseHelper _databaseHelper;

  OfflineEventRepositoryImpl(this._databaseHelper);

  @override
  Future<Either<Failure, void>> insertEvent(OfflineEvent event) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert('offline_events', event.toMap());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OfflineEvent>>> getUnsyncedEvents() async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'offline_events',
        where: 'is_synced = ?',
        whereArgs: [0],
      );

      return Right(List.generate(maps.length, (i) {
        return OfflineEvent.fromMap(maps[i]);
      }));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsSynced(int id) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        'offline_events',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
