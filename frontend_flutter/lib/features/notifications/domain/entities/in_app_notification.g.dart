// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'in_app_notification.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetInAppNotificationCollection on Isar {
  IsarCollection<InAppNotification> get inAppNotifications => this.collection();
}

const InAppNotificationSchema = CollectionSchema(
  name: r'InAppNotification',
  id: -1342329743109158126,
  properties: {
    r'actionUrl': PropertySchema(
      id: 0,
      name: r'actionUrl',
      type: IsarType.string,
    ),
    r'body': PropertySchema(
      id: 1,
      name: r'body',
      type: IsarType.string,
    ),
    r'leadId': PropertySchema(
      id: 2,
      name: r'leadId',
      type: IsarType.string,
    ),
    r'leadIdIndex': PropertySchema(
      id: 3,
      name: r'leadIdIndex',
      type: IsarType.string,
    ),
    r'leadName': PropertySchema(
      id: 4,
      name: r'leadName',
      type: IsarType.string,
    ),
    r'leadPhone': PropertySchema(
      id: 5,
      name: r'leadPhone',
      type: IsarType.string,
    ),
    r'read': PropertySchema(
      id: 6,
      name: r'read',
      type: IsarType.bool,
    ),
    r'readIndex': PropertySchema(
      id: 7,
      name: r'readIndex',
      type: IsarType.bool,
    ),
    r'receivedAt': PropertySchema(
      id: 8,
      name: r'receivedAt',
      type: IsarType.dateTime,
    ),
    r'receivedAtIndex': PropertySchema(
      id: 9,
      name: r'receivedAtIndex',
      type: IsarType.dateTime,
    ),
    r'title': PropertySchema(
      id: 10,
      name: r'title',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 11,
      name: r'type',
      type: IsarType.byte,
      enumMap: _InAppNotificationtypeEnumValueMap,
    ),
    r'uuid': PropertySchema(
      id: 12,
      name: r'uuid',
      type: IsarType.string,
    ),
    r'uuidIndex': PropertySchema(
      id: 13,
      name: r'uuidIndex',
      type: IsarType.string,
    )
  },
  estimateSize: _inAppNotificationEstimateSize,
  serialize: _inAppNotificationSerialize,
  deserialize: _inAppNotificationDeserialize,
  deserializeProp: _inAppNotificationDeserializeProp,
  idName: r'id',
  indexes: {
    r'receivedAtIndex': IndexSchema(
      id: -3656606300830312615,
      name: r'receivedAtIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'receivedAtIndex',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'readIndex': IndexSchema(
      id: -2554399177779050649,
      name: r'readIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'readIndex',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'leadIdIndex': IndexSchema(
      id: 2538614441176257841,
      name: r'leadIdIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'leadIdIndex',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'uuidIndex': IndexSchema(
      id: -7968580825086528144,
      name: r'uuidIndex',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'uuidIndex',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _inAppNotificationGetId,
  getLinks: _inAppNotificationGetLinks,
  attach: _inAppNotificationAttach,
  version: '3.1.0+1',
);

int _inAppNotificationEstimateSize(
  InAppNotification object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.actionUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.body.length * 3;
  bytesCount += 3 + object.leadId.length * 3;
  bytesCount += 3 + object.leadIdIndex.length * 3;
  {
    final value = object.leadName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.leadPhone;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.uuid.length * 3;
  bytesCount += 3 + object.uuidIndex.length * 3;
  return bytesCount;
}

void _inAppNotificationSerialize(
  InAppNotification object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.actionUrl);
  writer.writeString(offsets[1], object.body);
  writer.writeString(offsets[2], object.leadId);
  writer.writeString(offsets[3], object.leadIdIndex);
  writer.writeString(offsets[4], object.leadName);
  writer.writeString(offsets[5], object.leadPhone);
  writer.writeBool(offsets[6], object.read);
  writer.writeBool(offsets[7], object.readIndex);
  writer.writeDateTime(offsets[8], object.receivedAt);
  writer.writeDateTime(offsets[9], object.receivedAtIndex);
  writer.writeString(offsets[10], object.title);
  writer.writeByte(offsets[11], object.type.index);
  writer.writeString(offsets[12], object.uuid);
  writer.writeString(offsets[13], object.uuidIndex);
}

InAppNotification _inAppNotificationDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = InAppNotification(
    actionUrl: reader.readStringOrNull(offsets[0]),
    body: reader.readString(offsets[1]),
    leadId: reader.readString(offsets[2]),
    leadName: reader.readStringOrNull(offsets[4]),
    leadPhone: reader.readStringOrNull(offsets[5]),
    read: reader.readBoolOrNull(offsets[6]) ?? false,
    receivedAt: reader.readDateTime(offsets[8]),
    title: reader.readString(offsets[10]),
    type: _InAppNotificationtypeValueEnumMap[
            reader.readByteOrNull(offsets[11])] ??
        NotificationType.novoLead,
    uuid: reader.readString(offsets[12]),
  );
  object.id = id;
  object.leadIdIndex = reader.readString(offsets[3]);
  object.readIndex = reader.readBool(offsets[7]);
  object.receivedAtIndex = reader.readDateTime(offsets[9]);
  object.uuidIndex = reader.readString(offsets[13]);
  return object;
}

P _inAppNotificationDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (_InAppNotificationtypeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          NotificationType.novoLead) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _InAppNotificationtypeEnumValueMap = {
  'novoLead': 0,
  'leadQualificado': 1,
  'agendamentoConfirmado': 2,
  'leadInativo': 3,
  'propostaEnviada': 4,
  'propostaAprovada': 5,
  'sistemaAlerta': 6,
};
const _InAppNotificationtypeValueEnumMap = {
  0: NotificationType.novoLead,
  1: NotificationType.leadQualificado,
  2: NotificationType.agendamentoConfirmado,
  3: NotificationType.leadInativo,
  4: NotificationType.propostaEnviada,
  5: NotificationType.propostaAprovada,
  6: NotificationType.sistemaAlerta,
};

Id _inAppNotificationGetId(InAppNotification object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _inAppNotificationGetLinks(
    InAppNotification object) {
  return [];
}

void _inAppNotificationAttach(
    IsarCollection<dynamic> col, Id id, InAppNotification object) {
  object.id = id;
}

extension InAppNotificationByIndex on IsarCollection<InAppNotification> {
  Future<InAppNotification?> getByUuidIndex(String uuidIndex) {
    return getByIndex(r'uuidIndex', [uuidIndex]);
  }

  InAppNotification? getByUuidIndexSync(String uuidIndex) {
    return getByIndexSync(r'uuidIndex', [uuidIndex]);
  }

  Future<bool> deleteByUuidIndex(String uuidIndex) {
    return deleteByIndex(r'uuidIndex', [uuidIndex]);
  }

  bool deleteByUuidIndexSync(String uuidIndex) {
    return deleteByIndexSync(r'uuidIndex', [uuidIndex]);
  }

  Future<List<InAppNotification?>> getAllByUuidIndex(
      List<String> uuidIndexValues) {
    final values = uuidIndexValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuidIndex', values);
  }

  List<InAppNotification?> getAllByUuidIndexSync(List<String> uuidIndexValues) {
    final values = uuidIndexValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuidIndex', values);
  }

  Future<int> deleteAllByUuidIndex(List<String> uuidIndexValues) {
    final values = uuidIndexValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuidIndex', values);
  }

  int deleteAllByUuidIndexSync(List<String> uuidIndexValues) {
    final values = uuidIndexValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuidIndex', values);
  }

  Future<Id> putByUuidIndex(InAppNotification object) {
    return putByIndex(r'uuidIndex', object);
  }

  Id putByUuidIndexSync(InAppNotification object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuidIndex', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuidIndex(List<InAppNotification> objects) {
    return putAllByIndex(r'uuidIndex', objects);
  }

  List<Id> putAllByUuidIndexSync(List<InAppNotification> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuidIndex', objects, saveLinks: saveLinks);
  }
}

extension InAppNotificationQueryWhereSort
    on QueryBuilder<InAppNotification, InAppNotification, QWhere> {
  QueryBuilder<InAppNotification, InAppNotification, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterWhere>
      anyReceivedAtIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'receivedAtIndex'),
      );
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterWhere>
      anyReadIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'readIndex'),
      );
    });
  }
}

extension InAppNotificationQueryWhere
    on QueryBuilder<InAppNotification, InAppNotification, QWhereClause> {
  QueryBuilder<InAppNotification, InAppNotification, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<InAppNotification, InAppNotification, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<InAppNotification, InAppNotification, QAfterWhereClause>
      receivedAtIndexEqualTo(DateTime receivedAtIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'receivedAtIndex',
        value: [receivedAtIndex],
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterWhereClause>
      receivedAtIndexNotEqualTo(DateTime receivedAtIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'receivedAtIndex',
              lower: [],
              upper: [receivedAtIndex],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'receivedAtIndex',
              lower: [receivedAtIndex],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'receivedAtIndex',
              lower: [receivedAtIndex],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'receivedAtIndex',
              lower: [],
              upper: [receivedAtIndex],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterWhereClause>
      receivedAtIndexGreaterThan(
    DateTime receivedAtIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'receivedAtIndex',
        lower: [receivedAtIndex],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterWhereClause>
      receivedAtIndexLessThan(
    DateTime receivedAtIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'receivedAtIndex',
        lower: [],
        upper: [receivedAtIndex],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterWhereClause>
      receivedAtIndexBetween(
    DateTime lowerReceivedAtIndex,
    DateTime upperReceivedAtIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'receivedAtIndex',
        lower: [lowerReceivedAtIndex],
        includeLower: includeLower,
        upper: [upperReceivedAtIndex],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterWhereClause>
      readIndexEqualTo(bool readIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'readIndex',
        value: [readIndex],
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterWhereClause>
      readIndexNotEqualTo(bool readIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'readIndex',
              lower: [],
              upper: [readIndex],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'readIndex',
              lower: [readIndex],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'readIndex',
              lower: [readIndex],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'readIndex',
              lower: [],
              upper: [readIndex],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterWhereClause>
      leadIdIndexEqualTo(String leadIdIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'leadIdIndex',
        value: [leadIdIndex],
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterWhereClause>
      leadIdIndexNotEqualTo(String leadIdIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'leadIdIndex',
              lower: [],
              upper: [leadIdIndex],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'leadIdIndex',
              lower: [leadIdIndex],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'leadIdIndex',
              lower: [leadIdIndex],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'leadIdIndex',
              lower: [],
              upper: [leadIdIndex],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterWhereClause>
      uuidIndexEqualTo(String uuidIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuidIndex',
        value: [uuidIndex],
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterWhereClause>
      uuidIndexNotEqualTo(String uuidIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuidIndex',
              lower: [],
              upper: [uuidIndex],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuidIndex',
              lower: [uuidIndex],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuidIndex',
              lower: [uuidIndex],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuidIndex',
              lower: [],
              upper: [uuidIndex],
              includeUpper: false,
            ));
      }
    });
  }
}

extension InAppNotificationQueryFilter
    on QueryBuilder<InAppNotification, InAppNotification, QFilterCondition> {
  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      actionUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'actionUrl',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      actionUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'actionUrl',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      actionUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actionUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      actionUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'actionUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      actionUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'actionUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      actionUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'actionUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      actionUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'actionUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      actionUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'actionUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      actionUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'actionUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      actionUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'actionUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      actionUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actionUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      actionUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'actionUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      bodyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      bodyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      bodyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      bodyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'body',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      bodyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      bodyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      bodyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'body',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      bodyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'body',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      bodyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'body',
        value: '',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      bodyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'body',
        value: '',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
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

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      idLessThan(
    Id value, {
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

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
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

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
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

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
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

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
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

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
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

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
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

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
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

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'leadId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'leadId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'leadId',
        value: '',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'leadId',
        value: '',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadIdIndexEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'leadIdIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadIdIndexGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'leadIdIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadIdIndexLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'leadIdIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadIdIndexBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'leadIdIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadIdIndexStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'leadIdIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadIdIndexEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'leadIdIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadIdIndexContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'leadIdIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadIdIndexMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'leadIdIndex',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadIdIndexIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'leadIdIndex',
        value: '',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadIdIndexIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'leadIdIndex',
        value: '',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'leadName',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'leadName',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'leadName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'leadName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'leadName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'leadName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'leadName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'leadName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'leadName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'leadName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'leadName',
        value: '',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'leadName',
        value: '',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadPhoneIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'leadPhone',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadPhoneIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'leadPhone',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadPhoneEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'leadPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadPhoneGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'leadPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadPhoneLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'leadPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadPhoneBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'leadPhone',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadPhoneStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'leadPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadPhoneEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'leadPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadPhoneContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'leadPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadPhoneMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'leadPhone',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadPhoneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'leadPhone',
        value: '',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      leadPhoneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'leadPhone',
        value: '',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      readEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'read',
        value: value,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      readIndexEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'readIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      receivedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receivedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      receivedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'receivedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      receivedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'receivedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      receivedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'receivedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      receivedAtIndexEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'receivedAtIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      receivedAtIndexGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'receivedAtIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      receivedAtIndexLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'receivedAtIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      receivedAtIndexBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'receivedAtIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      typeEqualTo(NotificationType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      typeGreaterThan(
    NotificationType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      typeLessThan(
    NotificationType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      typeBetween(
    NotificationType lower,
    NotificationType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidIndexEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuidIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidIndexGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uuidIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidIndexLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uuidIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidIndexBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uuidIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidIndexStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uuidIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidIndexEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uuidIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidIndexContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuidIndex',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidIndexMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuidIndex',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidIndexIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuidIndex',
        value: '',
      ));
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterFilterCondition>
      uuidIndexIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuidIndex',
        value: '',
      ));
    });
  }
}

extension InAppNotificationQueryObject
    on QueryBuilder<InAppNotification, InAppNotification, QFilterCondition> {}

extension InAppNotificationQueryLinks
    on QueryBuilder<InAppNotification, InAppNotification, QFilterCondition> {}

extension InAppNotificationQuerySortBy
    on QueryBuilder<InAppNotification, InAppNotification, QSortBy> {
  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByActionUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionUrl', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByActionUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionUrl', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByBody() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByBodyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByLeadId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadId', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByLeadIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadId', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByLeadIdIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadIdIndex', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByLeadIdIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadIdIndex', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByLeadName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadName', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByLeadNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadName', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByLeadPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadPhone', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByLeadPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadPhone', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'read', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByReadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'read', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByReadIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readIndex', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByReadIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readIndex', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByReceivedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedAt', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByReceivedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedAt', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByReceivedAtIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedAtIndex', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByReceivedAtIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedAtIndex', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByUuidIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuidIndex', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      sortByUuidIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuidIndex', Sort.desc);
    });
  }
}

extension InAppNotificationQuerySortThenBy
    on QueryBuilder<InAppNotification, InAppNotification, QSortThenBy> {
  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByActionUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionUrl', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByActionUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionUrl', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByBody() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByBodyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByLeadId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadId', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByLeadIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadId', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByLeadIdIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadIdIndex', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByLeadIdIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadIdIndex', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByLeadName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadName', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByLeadNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadName', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByLeadPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadPhone', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByLeadPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'leadPhone', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'read', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByReadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'read', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByReadIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readIndex', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByReadIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readIndex', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByReceivedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedAt', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByReceivedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedAt', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByReceivedAtIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedAtIndex', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByReceivedAtIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'receivedAtIndex', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByUuidIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuidIndex', Sort.asc);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QAfterSortBy>
      thenByUuidIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuidIndex', Sort.desc);
    });
  }
}

extension InAppNotificationQueryWhereDistinct
    on QueryBuilder<InAppNotification, InAppNotification, QDistinct> {
  QueryBuilder<InAppNotification, InAppNotification, QDistinct>
      distinctByActionUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actionUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QDistinct> distinctByBody(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'body', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QDistinct>
      distinctByLeadId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'leadId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QDistinct>
      distinctByLeadIdIndex({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'leadIdIndex', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QDistinct>
      distinctByLeadName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'leadName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QDistinct>
      distinctByLeadPhone({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'leadPhone', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QDistinct>
      distinctByRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'read');
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QDistinct>
      distinctByReadIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'readIndex');
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QDistinct>
      distinctByReceivedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receivedAt');
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QDistinct>
      distinctByReceivedAtIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'receivedAtIndex');
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QDistinct>
      distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<InAppNotification, InAppNotification, QDistinct>
      distinctByUuidIndex({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuidIndex', caseSensitive: caseSensitive);
    });
  }
}

extension InAppNotificationQueryProperty
    on QueryBuilder<InAppNotification, InAppNotification, QQueryProperty> {
  QueryBuilder<InAppNotification, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<InAppNotification, String?, QQueryOperations>
      actionUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actionUrl');
    });
  }

  QueryBuilder<InAppNotification, String, QQueryOperations> bodyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'body');
    });
  }

  QueryBuilder<InAppNotification, String, QQueryOperations> leadIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'leadId');
    });
  }

  QueryBuilder<InAppNotification, String, QQueryOperations>
      leadIdIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'leadIdIndex');
    });
  }

  QueryBuilder<InAppNotification, String?, QQueryOperations>
      leadNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'leadName');
    });
  }

  QueryBuilder<InAppNotification, String?, QQueryOperations>
      leadPhoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'leadPhone');
    });
  }

  QueryBuilder<InAppNotification, bool, QQueryOperations> readProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'read');
    });
  }

  QueryBuilder<InAppNotification, bool, QQueryOperations> readIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'readIndex');
    });
  }

  QueryBuilder<InAppNotification, DateTime, QQueryOperations>
      receivedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receivedAt');
    });
  }

  QueryBuilder<InAppNotification, DateTime, QQueryOperations>
      receivedAtIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'receivedAtIndex');
    });
  }

  QueryBuilder<InAppNotification, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<InAppNotification, NotificationType, QQueryOperations>
      typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<InAppNotification, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }

  QueryBuilder<InAppNotification, String, QQueryOperations>
      uuidIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuidIndex');
    });
  }
}
