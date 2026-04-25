import 'package:isar/isar.dart';

part 'proposal_cache.g.dart';

@Collection()
class ProposalCache {
  ProposalCache({
    this.id,
    required this.serverId,
    required this.leadId,
    required this.consultorId,
    required this.status,
    required this.totalValue,
    this.destino,
    this.dataIda,
    this.dataVolta,
    this.numPessoas,
    this.notes,
    this.pdfUrl,
    this.createdAt,
    this.updatedAt,
    this.cachedAt,
  });

  Id? id;

  @Index(unique: true)
  late String serverId;

  late String leadId;
  late String consultorId;
  late String status;
  late double totalValue;
  String? destino;
  DateTime? dataIda;
  DateTime? dataVolta;
  int? numPessoas;
  String? notes;
  String? pdfUrl;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? cachedAt;
}
