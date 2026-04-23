import 'package:isar/isar.dart';

part 'lead_cache.g.dart';

@Collection()
class LeadCache {
  LeadCache({
    this.id,
    required this.serverId,
    required this.name,
    required this.phone,
    required this.status,
    required this.score,
    required this.completudePct,
    this.email,
    this.destino,
    this.dataIda,
    this.dataVolta,
    this.numPessoas,
    this.perfil,
    this.tipoViagem,
    this.preferencias,
    this.orcamentoFaixa,
    this.passaporteValido,
    this.experienciaInternacional,
    this.assignedTo,
    this.createdAt,
    this.updatedAt,
    this.cachedAt,
  });

  Id? id;

  @Index(unique: true)
  late String serverId;

  late String name;
  late String phone;
  String? email;
  late String status;
  late String score;
  late int completudePct;
  String? destino;
  DateTime? dataIda;
  DateTime? dataVolta;
  int? numPessoas;
  String? perfil;
  String? tipoViagem;
  String? preferencias;
  String? orcamentoFaixa;
  bool? passaporteValido;
  bool? experienciaInternacional;
  String? assignedTo;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? cachedAt;
}
