// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'briefing_cache.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBriefingCacheCollection on Isar {
  IsarCollection<BriefingCache> get briefingCaches => this.collection();
}

const BriefingCacheSchema = CollectionSchema(
  name: r'br',
  id: 1002,
  properties: {
    r'cachedAt': PropertySchema(
      id: 0,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'completudePct': PropertySchema(
      id: 1,
      name: r'completudePct',
      type: IsarType.long,
    ),
    r'dataIda': PropertySchema(
      id: 2,
      name: r'dataIda',
      type: IsarType.dateTime,
    ),
    r'dataVolta': PropertySchema(
      id: 3,
      name: r'dataVolta',
      type: IsarType.dateTime,
    ),
    r'destino': PropertySchema(
      id: 4,
      name: r'destino',
      type: IsarType.string,
    ),
    r'experienciaInternacional': PropertySchema(
      id: 5,
      name: r'experienciaInternacional',
      type: IsarType.bool,
    ),
    r'leadId': PropertySchema(
      id: 6,
      name: r'leadId',
      type: IsarType.string,
    ),
    r'numPessoas': PropertySchema(
      id: 7,
      name: r'numPessoas',
      type: IsarType.long,
    ),
    r'orcamentoFaixa': PropertySchema(
      id: 8,
      name: r'orcamentoFaixa',
      type: IsarType.string,
    ),
    r'passaporteValido': PropertySchema(
      id: 9,
      name: r'passaporteValido',
      type: IsarType.bool,
    ),
    r'perfil': PropertySchema(
      id: 10,
      name: r'perfil',
      type: IsarType.string,
    ),
    r'preferencias': PropertySchema(
      id: 11,
      name: r'preferencias',
      type: IsarType.string,
    ),
    r'resumoConversa': PropertySchema(
      id: 12,
      name: r'resumoConversa',
      type: IsarType.string,
    ),
    r'tipoViagem': PropertySchema(
      id: 13,
      name: r'tipoViagem',
      type: IsarType.string,
    )
  },
  estimateSize: _briefingCacheEstimateSize,
  serialize: _briefingCacheSerialize,
  deserialize: _briefingCacheDeserialize,
  deserializeProp: _briefingCacheDeserializeProp,
  idName: r'id',
  indexes: {
    r'l1': IndexSchema(
      id: 2002,
      name: r'l1',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'leadId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _briefingCacheGetId,
  getLinks: _briefingCacheGetLinks,
  attach: _briefingCacheAttach,
  version: '3.1.0+1',
);

int _briefingCacheEstimateSize(
  BriefingCache object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.destino;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.leadId.length * 3;
  {
    final value = object.orcamentoFaixa;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.perfil;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.preferencias;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.resumoConversa;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.tipoViagem;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _briefingCacheSerialize(
  BriefingCache object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.cachedAt);
  writer.writeLong(offsets[1], object.completudePct);
  writer.writeDateTime(offsets[2], object.dataIda);
  writer.writeDateTime(offsets[3], object.dataVolta);
  writer.writeString(offsets[4], object.destino);
  writer.writeBool(offsets[5], object.experienciaInternacional);
  writer.writeString(offsets[6], object.leadId);
  writer.writeLong(offsets[7], object.numPessoas);
  writer.writeString(offsets[8], object.orcamentoFaixa);
  writer.writeBool(offsets[9], object.passaporteValido);
  writer.writeString(offsets[10], object.perfil);
  writer.writeString(offsets[11], object.preferencias);
  writer.writeString(offsets[12], object.resumoConversa);
  writer.writeString(offsets[13], object.tipoViagem);
}

BriefingCache _briefingCacheDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BriefingCache(
    cachedAt: reader.readDateTimeOrNull(offsets[0]),
    completudePct: reader.readLong(offsets[1]),
    dataIda: reader.readDateTimeOrNull(offsets[2]),
    dataVolta: reader.readDateTimeOrNull(offsets[3]),
    destino: reader.readStringOrNull(offsets[4]),
    experienciaInternacional: reader.readBoolOrNull(offsets[5]),
    id: id,
    leadId: reader.readString(offsets[6]),
    numPessoas: reader.readLongOrNull(offsets[7]),
    orcamentoFaixa: reader.readStringOrNull(offsets[8]),
    passaporteValido: reader.readBoolOrNull(offsets[9]),
    perfil: reader.readStringOrNull(offsets[10]),
    preferencias: reader.readStringOrNull(offsets[11]),
    resumoConversa: reader.readStringOrNull(offsets[12]),
    tipoViagem: reader.readStringOrNull(offsets[13]),
  );
  return object;
}

P _briefingCacheDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readBoolOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readBoolOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _briefingCacheGetId(BriefingCache object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _briefingCacheGetLinks(BriefingCache object) {
  return [];
}

void _briefingCacheAttach(
    IsarCollection<dynamic> col, Id id, BriefingCache object) {
  object.id = id;
}

extension BriefingCacheByIndex on IsarCollection<BriefingCache> {
  Future<BriefingCache?> getByLeadId(String leadId) {
    return getByIndex(r'l1', [leadId]);
  }

  BriefingCache? getByLeadIdSync(String leadId) {
    return getByIndexSync(r'l1', [leadId]);
  }

  Future<bool> deleteByLeadId(String leadId) {
    return deleteByIndex(r'l1', [leadId]);
  }

  bool deleteByLeadIdSync(String leadId) {
    return deleteByIndexSync(r'l1', [leadId]);
  }

  Future<List<BriefingCache?>> getAllByLeadId(List<String> leadIdValues) {
    final values = leadIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'l1', values);
  }

  List<BriefingCache?> getAllByLeadIdSync(List<String> leadIdValues) {
    final values = leadIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'l1', values);
  }

  Future<int> deleteAllByLeadId(List<String> leadIdValues) {
    final values = leadIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'l1', values);
  }

  int deleteAllByLeadIdSync(List<String> leadIdValues) {
    final values = leadIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'l1', values);
  }

  Future<Id> putByLeadId(BriefingCache object) {
    return putByIndex(r'l1', object);
  }

  Id putByLeadIdSync(BriefingCache object, {bool saveLinks = true}) {
    return putByIndexSync(r'l1', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByLeadId(List<BriefingCache> objects) {
    return putAllByIndex(r'l1', objects);
  }

  List<Id> putAllByLeadIdSync(List<BriefingCache> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'l1', objects, saveLinks: saveLinks);
  }
}

extension BriefingCacheQueryWhereSort
    on QueryBuilder<BriefingCache, BriefingCache, QWhere> {
  QueryBuilder<BriefingCache, BriefingCache, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BriefingCacheQueryWhere
    on QueryBuilder<BriefingCache, BriefingCache, QWhereClause> {
  QueryBuilder<BriefingCache, BriefingCache, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterWhereClause> leadIdEqualTo(
      String leadId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'l1',
        value: [leadId],
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterWhereClause>
      leadIdNotEqualTo(String leadId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'l1',
              lower: [],
              upper: [leadId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'l1',
              lower: [leadId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'l1',
              lower: [leadId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'l1',
              lower: [],
              upper: [leadId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension BriefingCacheQueryFilter
    on QueryBuilder<BriefingCache, BriefingCache, QFilterCondition> {
  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      cachedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cachedAt',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      cachedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cachedAt',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      cachedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      cachedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      cachedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      cachedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cachedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      completudePctEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completudePct',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      completudePctGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completudePct',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      completudePctLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completudePct',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      completudePctBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completudePct',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      dataIdaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dataIda',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      dataIdaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dataIda',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      dataIdaEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dataIda',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      dataIdaGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dataIda',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      dataIdaLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dataIda',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      dataIdaBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dataIda',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      dataVoltaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dataVolta',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      dataVoltaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dataVolta',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      dataVoltaEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dataVolta',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      dataVoltaGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dataVolta',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      dataVoltaLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dataVolta',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      dataVoltaBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dataVolta',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      destinoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'destino',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      destinoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'destino',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      destinoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'destino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      destinoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'destino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      destinoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'destino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      destinoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'destino',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      destinoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'destino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      destinoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'destino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      destinoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'destino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      destinoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'destino',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      destinoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'destino',
        value: '',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      destinoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'destino',
        value: '',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      experienciaInternacionalIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'experienciaInternacional',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      experienciaInternacionalIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'experienciaInternacional',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      experienciaInternacionalEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'experienciaInternacional',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition> idEqualTo(
      Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      idGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition> idLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition> idBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      leadIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'leadId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      leadIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'leadId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      leadIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'leadId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      leadIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'leadId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      leadIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'leadId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      leadIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'leadId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      leadIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'leadId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      leadIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'leadId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      leadIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'leadId',
        value: '',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      leadIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'leadId',
        value: '',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      numPessoasIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'numPessoas',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      numPessoasIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'numPessoas',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      numPessoasEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'numPessoas',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      numPessoasGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'numPessoas',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      numPessoasLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'numPessoas',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      numPessoasBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'numPessoas',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      orcamentoFaixaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'orcamentoFaixa',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      orcamentoFaixaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'orcamentoFaixa',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      orcamentoFaixaEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orcamentoFaixa',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      orcamentoFaixaGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orcamentoFaixa',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      orcamentoFaixaLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orcamentoFaixa',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      orcamentoFaixaBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orcamentoFaixa',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      orcamentoFaixaStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'orcamentoFaixa',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      orcamentoFaixaEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'orcamentoFaixa',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      orcamentoFaixaContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'orcamentoFaixa',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      orcamentoFaixaMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'orcamentoFaixa',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      orcamentoFaixaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orcamentoFaixa',
        value: '',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      orcamentoFaixaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'orcamentoFaixa',
        value: '',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      passaporteValidoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'passaporteValido',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      passaporteValidoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'passaporteValido',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      passaporteValidoEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'passaporteValido',
        value: value,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      perfilIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'perfil',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      perfilIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'perfil',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      perfilEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'perfil',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      perfilGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'perfil',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      perfilLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'perfil',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      perfilBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'perfil',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      perfilStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'perfil',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      perfilEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'perfil',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      perfilContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'perfil',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      perfilMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'perfil',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      perfilIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'perfil',
        value: '',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      perfilIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'perfil',
        value: '',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      preferenciasIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'preferencias',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      preferenciasIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'preferencias',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      preferenciasEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'preferencias',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      preferenciasGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'preferencias',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      preferenciasLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'preferencias',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      preferenciasBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'preferencias',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      preferenciasStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'preferencias',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      preferenciasEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'preferencias',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      preferenciasContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'preferencias',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      preferenciasMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'preferencias',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      preferenciasIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'preferencias',
        value: '',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      preferenciasIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'preferencias',
        value: '',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      resumoConversaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'resumoConversa',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      resumoConversaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'resumoConversa',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      resumoConversaEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'resumoConversa',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      resumoConversaGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'resumoConversa',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      resumoConversaLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'resumoConversa',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      resumoConversaBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'resumoConversa',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      resumoConversaStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'resumoConversa',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      resumoConversaEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'resumoConversa',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      resumoConversaContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'resumoConversa',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      resumoConversaMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'resumoConversa',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      resumoConversaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'resumoConversa',
        value: '',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      resumoConversaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'resumoConversa',
        value: '',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      tipoViagemIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tipoViagem',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      tipoViagemIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tipoViagem',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      tipoViagemEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tipoViagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      tipoViagemGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tipoViagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      tipoViagemLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tipoViagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      tipoViagemBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tipoViagem',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      tipoViagemStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tipoViagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      tipoViagemEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tipoViagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      tipoViagemContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tipoViagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      tipoViagemMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tipoViagem',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      tipoViagemIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tipoViagem',
        value: '',
      ));
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterFilterCondition>
      tipoViagemIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tipoViagem',
        value: '',
      ));
    });
  }
}

extension BriefingCacheQueryObject
    on QueryBuilder<BriefingCache, BriefingCache, QFilterCondition> {}

extension BriefingCacheQueryLinks
    on QueryBuilder<BriefingCache, BriefingCache, QFilterCondition> {}

extension BriefingCacheQuerySortBy
    on QueryBuilder<BriefingCache, BriefingCache, QSortBy> {
  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      sortByCompletudePct() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completudePct', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      sortByCompletudePctDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completudePct', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> sortByDataIda() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataIda', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> sortByDataIdaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataIda', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> sortByDataVolta() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataVolta', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      sortByDataVoltaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataVolta', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> sortByDestino() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destino', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> sortByDestinoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destino', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      sortByExperienciaInternacional() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'experienciaInternacional', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      sortByExperienciaInternacionalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'experienciaInternacional', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> sortByLeadId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadId', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> sortByLeadIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadId', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> sortByNumPessoas() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPessoas', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      sortByNumPessoasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPessoas', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      sortByOrcamentoFaixa() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orcamentoFaixa', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      sortByOrcamentoFaixaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orcamentoFaixa', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      sortByPassaporteValido() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passaporteValido', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      sortByPassaporteValidoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passaporteValido', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> sortByPerfil() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perfil', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> sortByPerfilDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perfil', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      sortByPreferencias() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferencias', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      sortByPreferenciasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferencias', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      sortByResumoConversa() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resumoConversa', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      sortByResumoConversaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resumoConversa', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> sortByTipoViagem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoViagem', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      sortByTipoViagemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoViagem', Sort.desc);
    });
  }
}

extension BriefingCacheQuerySortThenBy
    on QueryBuilder<BriefingCache, BriefingCache, QSortThenBy> {
  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      thenByCompletudePct() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completudePct', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      thenByCompletudePctDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completudePct', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> thenByDataIda() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataIda', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> thenByDataIdaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataIda', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> thenByDataVolta() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataVolta', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      thenByDataVoltaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataVolta', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> thenByDestino() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destino', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> thenByDestinoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destino', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      thenByExperienciaInternacional() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'experienciaInternacional', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      thenByExperienciaInternacionalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'experienciaInternacional', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> thenByLeadId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadId', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> thenByLeadIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadId', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> thenByNumPessoas() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPessoas', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      thenByNumPessoasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPessoas', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      thenByOrcamentoFaixa() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orcamentoFaixa', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      thenByOrcamentoFaixaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orcamentoFaixa', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      thenByPassaporteValido() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passaporteValido', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      thenByPassaporteValidoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passaporteValido', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> thenByPerfil() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perfil', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> thenByPerfilDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perfil', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      thenByPreferencias() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferencias', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      thenByPreferenciasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferencias', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      thenByResumoConversa() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resumoConversa', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      thenByResumoConversaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resumoConversa', Sort.desc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy> thenByTipoViagem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoViagem', Sort.asc);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QAfterSortBy>
      thenByTipoViagemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoViagem', Sort.desc);
    });
  }
}

extension BriefingCacheQueryWhereDistinct
    on QueryBuilder<BriefingCache, BriefingCache, QDistinct> {
  QueryBuilder<BriefingCache, BriefingCache, QDistinct> distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QDistinct>
      distinctByCompletudePct() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completudePct');
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QDistinct> distinctByDataIda() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dataIda');
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QDistinct> distinctByDataVolta() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dataVolta');
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QDistinct> distinctByDestino(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'destino', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QDistinct>
      distinctByExperienciaInternacional() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'experienciaInternacional');
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QDistinct> distinctByLeadId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'leadId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QDistinct> distinctByNumPessoas() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'numPessoas');
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QDistinct>
      distinctByOrcamentoFaixa({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orcamentoFaixa',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QDistinct>
      distinctByPassaporteValido() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'passaporteValido');
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QDistinct> distinctByPerfil(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'perfil', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QDistinct> distinctByPreferencias(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'preferencias', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QDistinct>
      distinctByResumoConversa({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'resumoConversa',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BriefingCache, BriefingCache, QDistinct> distinctByTipoViagem(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tipoViagem', caseSensitive: caseSensitive);
    });
  }
}

extension BriefingCacheQueryProperty
    on QueryBuilder<BriefingCache, BriefingCache, QQueryProperty> {
  QueryBuilder<BriefingCache, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BriefingCache, DateTime?, QQueryOperations> cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<BriefingCache, int, QQueryOperations> completudePctProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completudePct');
    });
  }

  QueryBuilder<BriefingCache, DateTime?, QQueryOperations> dataIdaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dataIda');
    });
  }

  QueryBuilder<BriefingCache, DateTime?, QQueryOperations> dataVoltaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dataVolta');
    });
  }

  QueryBuilder<BriefingCache, String?, QQueryOperations> destinoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'destino');
    });
  }

  QueryBuilder<BriefingCache, bool?, QQueryOperations>
      experienciaInternacionalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'experienciaInternacional');
    });
  }

  QueryBuilder<BriefingCache, String, QQueryOperations> leadIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'leadId');
    });
  }

  QueryBuilder<BriefingCache, int?, QQueryOperations> numPessoasProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'numPessoas');
    });
  }

  QueryBuilder<BriefingCache, String?, QQueryOperations>
      orcamentoFaixaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orcamentoFaixa');
    });
  }

  QueryBuilder<BriefingCache, bool?, QQueryOperations>
      passaporteValidoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'passaporteValido');
    });
  }

  QueryBuilder<BriefingCache, String?, QQueryOperations> perfilProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'perfil');
    });
  }

  QueryBuilder<BriefingCache, String?, QQueryOperations>
      preferenciasProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferencias');
    });
  }

  QueryBuilder<BriefingCache, String?, QQueryOperations>
      resumoConversaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'resumoConversa');
    });
  }

  QueryBuilder<BriefingCache, String?, QQueryOperations> tipoViagemProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tipoViagem');
    });
  }
}
