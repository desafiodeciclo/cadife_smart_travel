// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead_cache.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLeadCacheCollection on Isar {
  IsarCollection<LeadCache> get leadCaches => this.collection();
}

const LeadCacheSchema = CollectionSchema(
  name: r'LeadCache',
  id: -3650693060946561480,
  properties: {
    r'assignedTo': PropertySchema(
      id: 0,
      name: r'assignedTo',
      type: IsarType.string,
    ),
    r'cachedAt': PropertySchema(
      id: 1,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'completudePct': PropertySchema(
      id: 2,
      name: r'completudePct',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'dataIda': PropertySchema(
      id: 4,
      name: r'dataIda',
      type: IsarType.dateTime,
    ),
    r'dataVolta': PropertySchema(
      id: 5,
      name: r'dataVolta',
      type: IsarType.dateTime,
    ),
    r'destino': PropertySchema(
      id: 6,
      name: r'destino',
      type: IsarType.string,
    ),
    r'email': PropertySchema(
      id: 7,
      name: r'email',
      type: IsarType.string,
    ),
    r'experienciaInternacional': PropertySchema(
      id: 8,
      name: r'experienciaInternacional',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 9,
      name: r'name',
      type: IsarType.string,
    ),
    r'numPessoas': PropertySchema(
      id: 10,
      name: r'numPessoas',
      type: IsarType.long,
    ),
    r'orcamentoFaixa': PropertySchema(
      id: 11,
      name: r'orcamentoFaixa',
      type: IsarType.string,
    ),
    r'passaporteValido': PropertySchema(
      id: 12,
      name: r'passaporteValido',
      type: IsarType.bool,
    ),
    r'perfil': PropertySchema(
      id: 13,
      name: r'perfil',
      type: IsarType.string,
    ),
    r'phone': PropertySchema(
      id: 14,
      name: r'phone',
      type: IsarType.string,
    ),
    r'preferencias': PropertySchema(
      id: 15,
      name: r'preferencias',
      type: IsarType.string,
    ),
    r'score': PropertySchema(
      id: 16,
      name: r'score',
      type: IsarType.string,
    ),
    r'serverId': PropertySchema(
      id: 17,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 18,
      name: r'status',
      type: IsarType.string,
    ),
    r'tipoViagem': PropertySchema(
      id: 19,
      name: r'tipoViagem',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 20,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _leadCacheEstimateSize,
  serialize: _leadCacheSerialize,
  deserialize: _leadCacheDeserialize,
  deserializeProp: _leadCacheDeserializeProp,
  idName: r'id',
  indexes: {
    r'serverId': IndexSchema(
      id: -7950187970872907662,
      name: r'serverId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'serverId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _leadCacheGetId,
  getLinks: _leadCacheGetLinks,
  attach: _leadCacheAttach,
  version: '3.1.0+1',
);

int _leadCacheEstimateSize(
  LeadCache object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.assignedTo;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.destino;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.email;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
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
  bytesCount += 3 + object.phone.length * 3;
  {
    final value = object.preferencias;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.score.length * 3;
  bytesCount += 3 + object.serverId.length * 3;
  bytesCount += 3 + object.status.length * 3;
  {
    final value = object.tipoViagem;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _leadCacheSerialize(
  LeadCache object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.assignedTo);
  writer.writeDateTime(offsets[1], object.cachedAt);
  writer.writeLong(offsets[2], object.completudePct);
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeDateTime(offsets[4], object.dataIda);
  writer.writeDateTime(offsets[5], object.dataVolta);
  writer.writeString(offsets[6], object.destino);
  writer.writeString(offsets[7], object.email);
  writer.writeBool(offsets[8], object.experienciaInternacional);
  writer.writeString(offsets[9], object.name);
  writer.writeLong(offsets[10], object.numPessoas);
  writer.writeString(offsets[11], object.orcamentoFaixa);
  writer.writeBool(offsets[12], object.passaporteValido);
  writer.writeString(offsets[13], object.perfil);
  writer.writeString(offsets[14], object.phone);
  writer.writeString(offsets[15], object.preferencias);
  writer.writeString(offsets[16], object.score);
  writer.writeString(offsets[17], object.serverId);
  writer.writeString(offsets[18], object.status);
  writer.writeString(offsets[19], object.tipoViagem);
  writer.writeDateTime(offsets[20], object.updatedAt);
}

LeadCache _leadCacheDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LeadCache(
    assignedTo: reader.readStringOrNull(offsets[0]),
    cachedAt: reader.readDateTimeOrNull(offsets[1]),
    completudePct: reader.readLong(offsets[2]),
    createdAt: reader.readDateTimeOrNull(offsets[3]),
    dataIda: reader.readDateTimeOrNull(offsets[4]),
    dataVolta: reader.readDateTimeOrNull(offsets[5]),
    destino: reader.readStringOrNull(offsets[6]),
    email: reader.readStringOrNull(offsets[7]),
    experienciaInternacional: reader.readBoolOrNull(offsets[8]),
    id: id,
    name: reader.readString(offsets[9]),
    numPessoas: reader.readLongOrNull(offsets[10]),
    orcamentoFaixa: reader.readStringOrNull(offsets[11]),
    passaporteValido: reader.readBoolOrNull(offsets[12]),
    perfil: reader.readStringOrNull(offsets[13]),
    phone: reader.readString(offsets[14]),
    preferencias: reader.readStringOrNull(offsets[15]),
    score: reader.readString(offsets[16]),
    serverId: reader.readString(offsets[17]),
    status: reader.readString(offsets[18]),
    tipoViagem: reader.readStringOrNull(offsets[19]),
    updatedAt: reader.readDateTimeOrNull(offsets[20]),
  );
  return object;
}

P _leadCacheDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readBoolOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readBoolOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readString(offset)) as P;
    case 18:
      return (reader.readString(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _leadCacheGetId(LeadCache object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _leadCacheGetLinks(LeadCache object) {
  return [];
}

void _leadCacheAttach(IsarCollection<dynamic> col, Id id, LeadCache object) {
  object.id = id;
}

extension LeadCacheByIndex on IsarCollection<LeadCache> {
  Future<LeadCache?> getByServerId(String serverId) {
    return getByIndex(r'serverId', [serverId]);
  }

  LeadCache? getByServerIdSync(String serverId) {
    return getByIndexSync(r'serverId', [serverId]);
  }

  Future<bool> deleteByServerId(String serverId) {
    return deleteByIndex(r'serverId', [serverId]);
  }

  bool deleteByServerIdSync(String serverId) {
    return deleteByIndexSync(r'serverId', [serverId]);
  }

  Future<List<LeadCache?>> getAllByServerId(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'serverId', values);
  }

  List<LeadCache?> getAllByServerIdSync(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'serverId', values);
  }

  Future<int> deleteAllByServerId(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'serverId', values);
  }

  int deleteAllByServerIdSync(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'serverId', values);
  }

  Future<Id> putByServerId(LeadCache object) {
    return putByIndex(r'serverId', object);
  }

  Id putByServerIdSync(LeadCache object, {bool saveLinks = true}) {
    return putByIndexSync(r'serverId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerId(List<LeadCache> objects) {
    return putAllByIndex(r'serverId', objects);
  }

  List<Id> putAllByServerIdSync(List<LeadCache> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'serverId', objects, saveLinks: saveLinks);
  }
}

extension LeadCacheQueryWhereSort
    on QueryBuilder<LeadCache, LeadCache, QWhere> {
  QueryBuilder<LeadCache, LeadCache, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LeadCacheQueryWhere
    on QueryBuilder<LeadCache, LeadCache, QWhereClause> {
  QueryBuilder<LeadCache, LeadCache, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<LeadCache, LeadCache, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterWhereClause> idBetween(
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

  QueryBuilder<LeadCache, LeadCache, QAfterWhereClause> serverIdEqualTo(
      String serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterWhereClause> serverIdNotEqualTo(
      String serverId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LeadCacheQueryFilter
    on QueryBuilder<LeadCache, LeadCache, QFilterCondition> {
  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> assignedToIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'assignedTo',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      assignedToIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'assignedTo',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> assignedToEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assignedTo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      assignedToGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'assignedTo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> assignedToLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'assignedTo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> assignedToBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'assignedTo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      assignedToStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'assignedTo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> assignedToEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'assignedTo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> assignedToContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'assignedTo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> assignedToMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'assignedTo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      assignedToIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assignedTo',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      assignedToIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'assignedTo',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> cachedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cachedAt',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      cachedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cachedAt',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> cachedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> cachedAtGreaterThan(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> cachedAtLessThan(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> cachedAtBetween(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      completudePctEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completudePct',
        value: value,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> createdAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> createdAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> createdAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> dataIdaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dataIda',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> dataIdaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dataIda',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> dataIdaEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dataIda',
        value: value,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> dataIdaGreaterThan(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> dataIdaLessThan(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> dataIdaBetween(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> dataVoltaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dataVolta',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      dataVoltaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dataVolta',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> dataVoltaEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dataVolta',
        value: value,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> dataVoltaLessThan(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> dataVoltaBetween(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> destinoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'destino',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> destinoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'destino',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> destinoEqualTo(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> destinoGreaterThan(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> destinoLessThan(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> destinoBetween(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> destinoStartsWith(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> destinoEndsWith(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> destinoContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'destino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> destinoMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'destino',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> destinoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'destino',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      destinoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'destino',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> emailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'email',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> emailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'email',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> emailEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> emailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> emailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> emailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'email',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> emailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> emailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> emailContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> emailMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'email',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> emailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> emailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      experienciaInternacionalIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'experienciaInternacional',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      experienciaInternacionalIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'experienciaInternacional',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      experienciaInternacionalEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'experienciaInternacional',
        value: value,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> idEqualTo(
      Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> idBetween(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> numPessoasIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'numPessoas',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      numPessoasIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'numPessoas',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> numPessoasEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'numPessoas',
        value: value,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> numPessoasLessThan(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> numPessoasBetween(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      orcamentoFaixaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'orcamentoFaixa',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      orcamentoFaixaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'orcamentoFaixa',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      orcamentoFaixaContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'orcamentoFaixa',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      orcamentoFaixaMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'orcamentoFaixa',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      orcamentoFaixaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orcamentoFaixa',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      orcamentoFaixaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'orcamentoFaixa',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      passaporteValidoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'passaporteValido',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      passaporteValidoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'passaporteValido',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      passaporteValidoEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'passaporteValido',
        value: value,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> perfilIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'perfil',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> perfilIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'perfil',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> perfilEqualTo(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> perfilGreaterThan(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> perfilLessThan(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> perfilBetween(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> perfilStartsWith(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> perfilEndsWith(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> perfilContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'perfil',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> perfilMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'perfil',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> perfilIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'perfil',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> perfilIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'perfil',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> phoneEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'phone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> phoneGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'phone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> phoneLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'phone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> phoneBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'phone',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> phoneStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'phone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> phoneEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'phone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> phoneContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'phone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> phoneMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'phone',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> phoneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'phone',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> phoneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'phone',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      preferenciasIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'preferencias',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      preferenciasIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'preferencias',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> preferenciasEqualTo(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> preferenciasBetween(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      preferenciasContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'preferencias',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> preferenciasMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'preferencias',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      preferenciasIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'preferencias',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      preferenciasIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'preferencias',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> scoreEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'score',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> scoreGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'score',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> scoreLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'score',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> scoreBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'score',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> scoreStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'score',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> scoreEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'score',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> scoreContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'score',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> scoreMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'score',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> scoreIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'score',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> scoreIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'score',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> serverIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> serverIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> serverIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> serverIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serverId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> serverIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> serverIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> serverIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> serverIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> statusContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> statusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> tipoViagemIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tipoViagem',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      tipoViagemIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tipoViagem',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> tipoViagemEqualTo(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> tipoViagemLessThan(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> tipoViagemBetween(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> tipoViagemEndsWith(
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

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> tipoViagemContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tipoViagem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> tipoViagemMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tipoViagem',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      tipoViagemIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tipoViagem',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      tipoViagemIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tipoViagem',
        value: '',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> updatedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> updatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterFilterCondition> updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension LeadCacheQueryObject
    on QueryBuilder<LeadCache, LeadCache, QFilterCondition> {}

extension LeadCacheQueryLinks
    on QueryBuilder<LeadCache, LeadCache, QFilterCondition> {}

extension LeadCacheQuerySortBy on QueryBuilder<LeadCache, LeadCache, QSortBy> {
  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByAssignedTo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedTo', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByAssignedToDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedTo', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByCompletudePct() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completudePct', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByCompletudePctDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completudePct', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByDataIda() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataIda', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByDataIdaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataIda', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByDataVolta() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataVolta', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByDataVoltaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataVolta', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByDestino() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destino', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByDestinoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destino', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy>
      sortByExperienciaInternacional() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'experienciaInternacional', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy>
      sortByExperienciaInternacionalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'experienciaInternacional', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByNumPessoas() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPessoas', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByNumPessoasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPessoas', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByOrcamentoFaixa() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orcamentoFaixa', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByOrcamentoFaixaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orcamentoFaixa', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByPassaporteValido() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passaporteValido', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy>
      sortByPassaporteValidoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passaporteValido', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByPerfil() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perfil', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByPerfilDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perfil', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByPreferencias() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferencias', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByPreferenciasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferencias', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'score', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'score', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByTipoViagem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoViagem', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByTipoViagemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoViagem', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension LeadCacheQuerySortThenBy
    on QueryBuilder<LeadCache, LeadCache, QSortThenBy> {
  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByAssignedTo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedTo', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByAssignedToDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assignedTo', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByCompletudePct() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completudePct', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByCompletudePctDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completudePct', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByDataIda() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataIda', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByDataIdaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataIda', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByDataVolta() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataVolta', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByDataVoltaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataVolta', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByDestino() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destino', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByDestinoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destino', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy>
      thenByExperienciaInternacional() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'experienciaInternacional', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy>
      thenByExperienciaInternacionalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'experienciaInternacional', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByNumPessoas() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPessoas', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByNumPessoasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPessoas', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByOrcamentoFaixa() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orcamentoFaixa', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByOrcamentoFaixaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orcamentoFaixa', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByPassaporteValido() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passaporteValido', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy>
      thenByPassaporteValidoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'passaporteValido', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByPerfil() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perfil', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByPerfilDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'perfil', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'phone', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByPreferencias() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferencias', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByPreferenciasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferencias', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'score', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'score', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByTipoViagem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoViagem', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByTipoViagemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipoViagem', Sort.desc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension LeadCacheQueryWhereDistinct
    on QueryBuilder<LeadCache, LeadCache, QDistinct> {
  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByAssignedTo(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assignedTo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByCompletudePct() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completudePct');
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByDataIda() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dataIda');
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByDataVolta() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dataVolta');
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByDestino(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'destino', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByEmail(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'email', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct>
      distinctByExperienciaInternacional() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'experienciaInternacional');
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByNumPessoas() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'numPessoas');
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByOrcamentoFaixa(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orcamentoFaixa',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByPassaporteValido() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'passaporteValido');
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByPerfil(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'perfil', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByPhone(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'phone', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByPreferencias(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'preferencias', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByScore(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'score', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByTipoViagem(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tipoViagem', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LeadCache, LeadCache, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension LeadCacheQueryProperty
    on QueryBuilder<LeadCache, LeadCache, QQueryProperty> {
  QueryBuilder<LeadCache, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LeadCache, String?, QQueryOperations> assignedToProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assignedTo');
    });
  }

  QueryBuilder<LeadCache, DateTime?, QQueryOperations> cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<LeadCache, int, QQueryOperations> completudePctProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completudePct');
    });
  }

  QueryBuilder<LeadCache, DateTime?, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<LeadCache, DateTime?, QQueryOperations> dataIdaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dataIda');
    });
  }

  QueryBuilder<LeadCache, DateTime?, QQueryOperations> dataVoltaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dataVolta');
    });
  }

  QueryBuilder<LeadCache, String?, QQueryOperations> destinoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'destino');
    });
  }

  QueryBuilder<LeadCache, String?, QQueryOperations> emailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'email');
    });
  }

  QueryBuilder<LeadCache, bool?, QQueryOperations>
      experienciaInternacionalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'experienciaInternacional');
    });
  }

  QueryBuilder<LeadCache, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<LeadCache, int?, QQueryOperations> numPessoasProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'numPessoas');
    });
  }

  QueryBuilder<LeadCache, String?, QQueryOperations> orcamentoFaixaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orcamentoFaixa');
    });
  }

  QueryBuilder<LeadCache, bool?, QQueryOperations> passaporteValidoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'passaporteValido');
    });
  }

  QueryBuilder<LeadCache, String?, QQueryOperations> perfilProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'perfil');
    });
  }

  QueryBuilder<LeadCache, String, QQueryOperations> phoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'phone');
    });
  }

  QueryBuilder<LeadCache, String?, QQueryOperations> preferenciasProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferencias');
    });
  }

  QueryBuilder<LeadCache, String, QQueryOperations> scoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'score');
    });
  }

  QueryBuilder<LeadCache, String, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<LeadCache, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<LeadCache, String?, QQueryOperations> tipoViagemProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tipoViagem');
    });
  }

  QueryBuilder<LeadCache, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
