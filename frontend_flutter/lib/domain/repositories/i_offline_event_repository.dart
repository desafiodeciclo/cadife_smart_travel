import 'package:cadife_smart_travel/domain/entities/offline_event.dart';

abstract class IOfflineEventRepository {
  Future<void> insertEvent(OfflineEvent event);
  Future<List<OfflineEvent>> getUnsyncedEvents();
  Future<void> markAsSynced(int id);
}
