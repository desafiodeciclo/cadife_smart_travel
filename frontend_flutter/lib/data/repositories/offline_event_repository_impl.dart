import 'package:cadife_smart_travel/data/local/database_helper.dart';
import 'package:cadife_smart_travel/domain/entities/offline_event.dart';
import 'package:cadife_smart_travel/domain/repositories/i_offline_event_repository.dart';

class OfflineEventRepositoryImpl implements IOfflineEventRepository {
  final DatabaseHelper _databaseHelper;

  OfflineEventRepositoryImpl(this._databaseHelper);

  @override
  Future<void> insertEvent(OfflineEvent event) async {
    final db = await _databaseHelper.database;
    await db.insert('offline_events', event.toMap());
  }

  @override
  Future<List<OfflineEvent>> getUnsyncedEvents() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'offline_events',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    return List.generate(maps.length, (i) {
      return OfflineEvent.fromMap(maps[i]);
    });
  }

  @override
  Future<void> markAsSynced(int id) async {
    final db = await _databaseHelper.database;
    await db.update(
      'offline_events',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
