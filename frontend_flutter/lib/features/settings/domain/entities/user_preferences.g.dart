// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUserPreferencesIsarCollection on Isar {
  IsarCollection<UserPreferencesIsar> get userPreferencesIsars =>
      this.collection();
}

const UserPreferencesIsarSchema = CollectionSchema(
  name: r'UserPreferencesIsar',
  id: 123456789,
  properties: {
    r'themePreference': PropertySchema(
      id: 0,
      name: r'themePreference',
      type: IsarType.byte,
      enumMap: _UserPreferencesIsarthemePreferenceEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 1,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _userPreferencesIsarEstimateSize,
  serialize: _userPreferencesIsarSerialize,
  deserialize: _userPreferencesIsarDeserialize,
  deserializeProp: _userPreferencesIsarDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _userPreferencesIsarGetId,
  getLinks: _userPreferencesIsarGetLinks,
  attach: _userPreferencesIsarAttach,
  version: '3.1.0+1',
);

int _userPreferencesIsarEstimateSize(
  UserPreferencesIsar object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _userPreferencesIsarSerialize(
  UserPreferencesIsar object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeByte(offsets[0], object.themePreference.index);
  writer.writeDateTime(offsets[1], object.updatedAt);
}

UserPreferencesIsar _userPreferencesIsarDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UserPreferencesIsar();
  object.id = id;
  object.themePreference = _UserPreferencesIsarthemePreferenceValueEnumMap[
          reader.readByteOrNull(offsets[0])] ??
      ThemePreference.light;
  object.updatedAt = reader.readDateTime(offsets[1]);
  return object;
}

P _userPreferencesIsarDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (_UserPreferencesIsarthemePreferenceValueEnumMap[
              reader.readByteOrNull(offset)] ??
          ThemePreference.light) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _UserPreferencesIsarthemePreferenceEnumValueMap = {
  'light': 0,
  'dark': 1,
  'system': 2,
};
const _UserPreferencesIsarthemePreferenceValueEnumMap = {
  0: ThemePreference.light,
  1: ThemePreference.dark,
  2: ThemePreference.system,
};

Id _userPreferencesIsarGetId(UserPreferencesIsar object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _userPreferencesIsarGetLinks(
    UserPreferencesIsar object) {
  return [];
}

void _userPreferencesIsarAttach(
    IsarCollection<dynamic> col, Id id, UserPreferencesIsar object) {
  object.id = id;
}

extension UserPreferencesIsarQueryWhereSort
    on QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QWhere> {
  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UserPreferencesIsarQueryWhere
    on QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QWhereClause> {
  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterWhereClause>
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

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterWhereClause>
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
}

extension UserPreferencesIsarQueryFilter on QueryBuilder<UserPreferencesIsar,
    UserPreferencesIsar, QFilterCondition> {
  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterFilterCondition>
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

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterFilterCondition>
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

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterFilterCondition>
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

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterFilterCondition>
      themePreferenceEqualTo(ThemePreference value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'themePreference',
        value: value,
      ));
    });
  }

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterFilterCondition>
      themePreferenceGreaterThan(
    ThemePreference value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'themePreference',
        value: value,
      ));
    });
  }

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterFilterCondition>
      themePreferenceLessThan(
    ThemePreference value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'themePreference',
        value: value,
      ));
    });
  }

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterFilterCondition>
      themePreferenceBetween(
    ThemePreference lower,
    ThemePreference upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'themePreference',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
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

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
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

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
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

extension UserPreferencesIsarQueryObject on QueryBuilder<UserPreferencesIsar,
    UserPreferencesIsar, QFilterCondition> {}

extension UserPreferencesIsarQueryLinks on QueryBuilder<UserPreferencesIsar,
    UserPreferencesIsar, QFilterCondition> {}

extension UserPreferencesIsarQuerySortBy
    on QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QSortBy> {
  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterSortBy>
      sortByThemePreference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themePreference', Sort.asc);
    });
  }

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterSortBy>
      sortByThemePreferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themePreference', Sort.desc);
    });
  }

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension UserPreferencesIsarQuerySortThenBy
    on QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QSortThenBy> {
  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterSortBy>
      thenByThemePreference() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themePreference', Sort.asc);
    });
  }

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterSortBy>
      thenByThemePreferenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themePreference', Sort.desc);
    });
  }

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension UserPreferencesIsarQueryWhereDistinct
    on QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QDistinct> {
  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QDistinct>
      distinctByThemePreference() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'themePreference');
    });
  }

  QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension UserPreferencesIsarQueryProperty
    on QueryBuilder<UserPreferencesIsar, UserPreferencesIsar, QQueryProperty> {
  QueryBuilder<UserPreferencesIsar, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UserPreferencesIsar, ThemePreference, QQueryOperations>
      themePreferenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'themePreference');
    });
  }

  QueryBuilder<UserPreferencesIsar, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
