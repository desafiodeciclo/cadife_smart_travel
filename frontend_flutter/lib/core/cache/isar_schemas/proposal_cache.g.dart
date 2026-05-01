// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proposal_cache.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProposalCacheCollection on Isar {
  IsarCollection<ProposalCache> get proposalCaches => this.collection();
}

const ProposalCacheSchema = CollectionSchema(
  name: r'pr',
  id: 1004,
  properties: {
    r'cachedAt': PropertySchema(
      id: 0,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'consultorId': PropertySchema(
      id: 1,
      name: r'consultorId',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'dataIda': PropertySchema(
      id: 3,
      name: r'dataIda',
      type: IsarType.dateTime,
    ),
    r'dataVolta': PropertySchema(
      id: 4,
      name: r'dataVolta',
      type: IsarType.dateTime,
    ),
    r'destino': PropertySchema(
      id: 5,
      name: r'destino',
      type: IsarType.string,
    ),
    r'leadId': PropertySchema(
      id: 6,
      name: r'leadId',
      type: IsarType.string,
    ),
    r'notes': PropertySchema(
      id: 7,
      name: r'notes',
      type: IsarType.string,
    ),
    r'numPessoas': PropertySchema(
      id: 8,
      name: r'numPessoas',
      type: IsarType.long,
    ),
    r'pdfUrl': PropertySchema(
      id: 9,
      name: r'pdfUrl',
      type: IsarType.string,
    ),
    r'serverId': PropertySchema(
      id: 10,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 11,
      name: r'status',
      type: IsarType.string,
    ),
    r'totalValue': PropertySchema(
      id: 12,
      name: r'totalValue',
      type: IsarType.double,
    ),
    r'updatedAt': PropertySchema(
      id: 13,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _proposalCacheEstimateSize,
  serialize: _proposalCacheSerialize,
  deserialize: _proposalCacheDeserialize,
  deserializeProp: _proposalCacheDeserializeProp,
  idName: r'id',
  indexes: {
    r's3': IndexSchema(
      id: 2004,
      name: r's3',
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
  getId: _proposalCacheGetId,
  getLinks: _proposalCacheGetLinks,
  attach: _proposalCacheAttach,
  version: '3.1.0+1',
);

int _proposalCacheEstimateSize(
  ProposalCache object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.consultorId.length * 3;
  {
    final value = object.destino;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.leadId.length * 3;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.pdfUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.serverId.length * 3;
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _proposalCacheSerialize(
  ProposalCache object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.cachedAt);
  writer.writeString(offsets[1], object.consultorId);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeDateTime(offsets[3], object.dataIda);
  writer.writeDateTime(offsets[4], object.dataVolta);
  writer.writeString(offsets[5], object.destino);
  writer.writeString(offsets[6], object.leadId);
  writer.writeString(offsets[7], object.notes);
  writer.writeLong(offsets[8], object.numPessoas);
  writer.writeString(offsets[9], object.pdfUrl);
  writer.writeString(offsets[10], object.serverId);
  writer.writeString(offsets[11], object.status);
  writer.writeDouble(offsets[12], object.totalValue);
  writer.writeDateTime(offsets[13], object.updatedAt);
}

ProposalCache _proposalCacheDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ProposalCache(
    cachedAt: reader.readDateTimeOrNull(offsets[0]),
    consultorId: reader.readString(offsets[1]),
    createdAt: reader.readDateTimeOrNull(offsets[2]),
    dataIda: reader.readDateTimeOrNull(offsets[3]),
    dataVolta: reader.readDateTimeOrNull(offsets[4]),
    destino: reader.readStringOrNull(offsets[5]),
    id: id,
    leadId: reader.readString(offsets[6]),
    notes: reader.readStringOrNull(offsets[7]),
    numPessoas: reader.readLongOrNull(offsets[8]),
    pdfUrl: reader.readStringOrNull(offsets[9]),
    serverId: reader.readString(offsets[10]),
    status: reader.readString(offsets[11]),
    totalValue: reader.readDouble(offsets[12]),
    updatedAt: reader.readDateTimeOrNull(offsets[13]),
  );
  return object;
}

P _proposalCacheDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readDouble(offset)) as P;
    case 13:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _proposalCacheGetId(ProposalCache object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _proposalCacheGetLinks(ProposalCache object) {
  return [];
}

void _proposalCacheAttach(
    IsarCollection<dynamic> col, Id id, ProposalCache object) {
  object.id = id;
}

extension ProposalCacheByIndex on IsarCollection<ProposalCache> {
  Future<ProposalCache?> getByServerId(String serverId) {
    return getByIndex(r's3', [serverId]);
  }

  ProposalCache? getByServerIdSync(String serverId) {
    return getByIndexSync(r's3', [serverId]);
  }

  Future<bool> deleteByServerId(String serverId) {
    return deleteByIndex(r's3', [serverId]);
  }

  bool deleteByServerIdSync(String serverId) {
    return deleteByIndexSync(r's3', [serverId]);
  }

  Future<List<ProposalCache?>> getAllByServerId(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndex(r's3', values);
  }

  List<ProposalCache?> getAllByServerIdSync(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r's3', values);
  }

  Future<int> deleteAllByServerId(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r's3', values);
  }

  int deleteAllByServerIdSync(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r's3', values);
  }

  Future<Id> putByServerId(ProposalCache object) {
    return putByIndex(r's3', object);
  }

  Id putByServerIdSync(ProposalCache object, {bool saveLinks = true}) {
    return putByIndexSync(r's3', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerId(List<ProposalCache> objects) {
    return putAllByIndex(r's3', objects);
  }

  List<Id> putAllByServerIdSync(List<ProposalCache> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r's3', objects, saveLinks: saveLinks);
  }
}

extension ProposalCacheQueryWhereSort
    on QueryBuilder<ProposalCache, ProposalCache, QWhere> {
  QueryBuilder<ProposalCache, ProposalCache, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ProposalCacheQueryWhere
    on QueryBuilder<ProposalCache, ProposalCache, QWhereClause> {
  QueryBuilder<ProposalCache, ProposalCache, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterWhereClause> idBetween(
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterWhereClause> serverIdEqualTo(
      String serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r's3',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterWhereClause>
      serverIdNotEqualTo(String serverId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r's3',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r's3',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r's3',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r's3',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ProposalCacheQueryFilter
    on QueryBuilder<ProposalCache, ProposalCache, QFilterCondition> {
  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      cachedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cachedAt',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      cachedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cachedAt',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      cachedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      consultorIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'consultorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      consultorIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'consultorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      consultorIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'consultorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      consultorIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'consultorId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      consultorIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'consultorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      consultorIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'consultorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      consultorIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'consultorId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      consultorIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'consultorId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      consultorIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'consultorId',
        value: '',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      consultorIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'consultorId',
        value: '',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'createdAt',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      createdAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      createdAtLessThan(
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      createdAtBetween(
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      dataIdaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dataIda',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      dataIdaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dataIda',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      dataIdaEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dataIda',
        value: value,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      dataVoltaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dataVolta',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      dataVoltaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dataVolta',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      dataVoltaEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dataVolta',
        value: value,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      destinoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'destino',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      destinoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'destino',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      destinoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'destino',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      destinoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'destino',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      destinoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'destino',
        value: '',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      destinoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'destino',
        value: '',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition> idEqualTo(
      Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      leadIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'leadId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      leadIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'leadId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      leadIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'leadId',
        value: '',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      leadIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'leadId',
        value: '',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      numPessoasIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'numPessoas',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      numPessoasIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'numPessoas',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      numPessoasEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'numPessoas',
        value: value,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      pdfUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pdfUrl',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      pdfUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pdfUrl',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      pdfUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pdfUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      pdfUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pdfUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      pdfUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pdfUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      pdfUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pdfUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      pdfUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'pdfUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      pdfUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'pdfUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      pdfUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pdfUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      pdfUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pdfUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      pdfUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pdfUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      pdfUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pdfUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      serverIdEqualTo(
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      serverIdGreaterThan(
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      serverIdLessThan(
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      serverIdBetween(
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      serverIdStartsWith(
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      serverIdEndsWith(
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      statusEqualTo(
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      statusGreaterThan(
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      statusLessThan(
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      statusBetween(
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      statusStartsWith(
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      statusEndsWith(
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      totalValueEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      totalValueGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      totalValueLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      totalValueBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      updatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      updatedAtLessThan(
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

  QueryBuilder<ProposalCache, ProposalCache, QAfterFilterCondition>
      updatedAtBetween(
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

extension ProposalCacheQueryObject
    on QueryBuilder<ProposalCache, ProposalCache, QFilterCondition> {}

extension ProposalCacheQueryLinks
    on QueryBuilder<ProposalCache, ProposalCache, QFilterCondition> {}

extension ProposalCacheQuerySortBy
    on QueryBuilder<ProposalCache, ProposalCache, QSortBy> {
  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy>
      sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByConsultorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consultorId', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy>
      sortByConsultorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consultorId', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByDataIda() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataIda', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByDataIdaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataIda', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByDataVolta() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataVolta', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy>
      sortByDataVoltaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataVolta', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByDestino() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destino', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByDestinoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destino', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByLeadId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadId', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByLeadIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadId', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByNumPessoas() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPessoas', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy>
      sortByNumPessoasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPessoas', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByPdfUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pdfUrl', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByPdfUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pdfUrl', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByTotalValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalValue', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy>
      sortByTotalValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalValue', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ProposalCacheQuerySortThenBy
    on QueryBuilder<ProposalCache, ProposalCache, QSortThenBy> {
  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy>
      thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByConsultorId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consultorId', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy>
      thenByConsultorIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consultorId', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByDataIda() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataIda', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByDataIdaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataIda', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByDataVolta() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataVolta', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy>
      thenByDataVoltaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dataVolta', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByDestino() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destino', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByDestinoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destino', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByLeadId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadId', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByLeadIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadId', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByNumPessoas() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPessoas', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy>
      thenByNumPessoasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numPessoas', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByPdfUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pdfUrl', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByPdfUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pdfUrl', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByTotalValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalValue', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy>
      thenByTotalValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalValue', Sort.desc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ProposalCacheQueryWhereDistinct
    on QueryBuilder<ProposalCache, ProposalCache, QDistinct> {
  QueryBuilder<ProposalCache, ProposalCache, QDistinct> distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QDistinct> distinctByConsultorId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'consultorId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QDistinct> distinctByDataIda() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dataIda');
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QDistinct> distinctByDataVolta() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dataVolta');
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QDistinct> distinctByDestino(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'destino', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QDistinct> distinctByLeadId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'leadId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QDistinct> distinctByNumPessoas() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'numPessoas');
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QDistinct> distinctByPdfUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pdfUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QDistinct> distinctByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QDistinct> distinctByTotalValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalValue');
    });
  }

  QueryBuilder<ProposalCache, ProposalCache, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension ProposalCacheQueryProperty
    on QueryBuilder<ProposalCache, ProposalCache, QQueryProperty> {
  QueryBuilder<ProposalCache, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ProposalCache, DateTime?, QQueryOperations> cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<ProposalCache, String, QQueryOperations> consultorIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'consultorId');
    });
  }

  QueryBuilder<ProposalCache, DateTime?, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ProposalCache, DateTime?, QQueryOperations> dataIdaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dataIda');
    });
  }

  QueryBuilder<ProposalCache, DateTime?, QQueryOperations> dataVoltaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dataVolta');
    });
  }

  QueryBuilder<ProposalCache, String?, QQueryOperations> destinoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'destino');
    });
  }

  QueryBuilder<ProposalCache, String, QQueryOperations> leadIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'leadId');
    });
  }

  QueryBuilder<ProposalCache, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<ProposalCache, int?, QQueryOperations> numPessoasProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'numPessoas');
    });
  }

  QueryBuilder<ProposalCache, String?, QQueryOperations> pdfUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pdfUrl');
    });
  }

  QueryBuilder<ProposalCache, String, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<ProposalCache, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<ProposalCache, double, QQueryOperations> totalValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalValue');
    });
  }

  QueryBuilder<ProposalCache, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
