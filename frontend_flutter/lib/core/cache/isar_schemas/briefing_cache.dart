import 'package:isar/isar.dart';

part 'briefing_cache.g.dart';

@Collection()
class BriefingCache {
  BriefingCache({
    this.id,
    required this.leadId,
    required this.completudePct,
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
    this.resumoConversa,
    this.cachedAt,
  });

  Id? id;

  @Index(unique: true)
  late String leadId;

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
  String? resumoConversa;
  DateTime? cachedAt;
}
