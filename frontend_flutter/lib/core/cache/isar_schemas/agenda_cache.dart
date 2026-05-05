import 'package:isar/isar.dart';

part 'agenda_cache.g.dart';

@Name('ag')
@Collection()
class AgendaCache {
  AgendaCache({
    required this.serverId,
    required this.leadId,
    required this.consultorId,
    required this.dateTime,
    required this.durationMinutes,
    required this.status,
    this.id,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.cachedAt,
  });

  Id? id;

  @Index(name: 's1', unique: true)
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
