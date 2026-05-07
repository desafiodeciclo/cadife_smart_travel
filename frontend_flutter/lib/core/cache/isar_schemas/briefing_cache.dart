import 'package:isar/isar.dart';

part 'briefing_cache.g.dart';

@Name('br')
@Collection()
class BriefingCache {
  BriefingCache({
    required this.leadId,
    required this.destino,
    required this.dataIda,
    required this.dataVolta,
    required this.numPessoas,
    required this.perfil,
    required this.tipoViagem,
    required this.preferencias,
    required this.orcamentoFaixa,
    required this.passaporteValido,
    required this.experienciaInternacional,
    required this.resumoConversa,
    required this.completudePct,
    this.id,
    this.cachedAt,
  });

  Id? id;

  @Index(name: 'l1', unique: true)
  late String leadId;

  late int completudePct;
  DateTime? dataIda;
  DateTime? dataVolta;
  String? destino;
  bool? experienciaInternacional;
  int? numPessoas;
  String? orcamentoFaixa;
  bool? passaporteValido;
  String? perfil;
  String? preferencias;
  String? resumoConversa;
  String? tipoViagem;
  DateTime? cachedAt;
}
