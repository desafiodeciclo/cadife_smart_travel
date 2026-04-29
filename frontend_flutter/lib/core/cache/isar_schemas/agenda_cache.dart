import 'package:isar/isar.dart';

part 'agenda_cache.g.dart';

@Collection()
class AgendaCache {
  AgendaCache({
    this.id,
    required this.serverId,
    required this.leadId,
    required this.consultorId,
    required this.dateTime,
    required this.durationMinutes,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.cachedAt,
  });

  Id? id;

  @Index(unique: true)
  late String serverId;

  late String leadId;
  late String consultorId;
  late DateTime dateTime;
  late int durationMinutes;
  late String status;
  String? notes;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? cachedAt;
}
