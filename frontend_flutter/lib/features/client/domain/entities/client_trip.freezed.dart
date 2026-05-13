// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'client_trip.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ClientTrip {
  String get id => throw _privateConstructorUsedError;
  String get destination => throw _privateConstructorUsedError;
  String get destinationCountry => throw _privateConstructorUsedError;
  String get destinationFlag => throw _privateConstructorUsedError; // emoji
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;
  String get coverImageUrl => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // planejando, confirmado, em andamento, concluído
  double get progressPercentage => throw _privateConstructorUsedError;
  TripCheckpoint get currentCheckpoint => throw _privateConstructorUsedError;
  List<TripCheckpoint> get checkpoints => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ClientTripCopyWith<ClientTrip> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClientTripCopyWith<$Res> {
  factory $ClientTripCopyWith(
          ClientTrip value, $Res Function(ClientTrip) then) =
      _$ClientTripCopyWithImpl<$Res, ClientTrip>;
  @useResult
  $Res call(
      {String id,
      String destination,
      String destinationCountry,
      String destinationFlag,
      DateTime startDate,
      DateTime endDate,
      String coverImageUrl,
      String status,
      double progressPercentage,
      TripCheckpoint currentCheckpoint,
      List<TripCheckpoint> checkpoints});

  $TripCheckpointCopyWith<$Res> get currentCheckpoint;
}

/// @nodoc
class _$ClientTripCopyWithImpl<$Res, $Val extends ClientTrip>
    implements $ClientTripCopyWith<$Res> {
  _$ClientTripCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? destination = null,
    Object? destinationCountry = null,
    Object? destinationFlag = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? coverImageUrl = null,
    Object? status = null,
    Object? progressPercentage = null,
    Object? currentCheckpoint = null,
    Object? checkpoints = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      destination: null == destination
          ? _value.destination
          : destination // ignore: cast_nullable_to_non_nullable
              as String,
      destinationCountry: null == destinationCountry
          ? _value.destinationCountry
          : destinationCountry // ignore: cast_nullable_to_non_nullable
              as String,
      destinationFlag: null == destinationFlag
          ? _value.destinationFlag
          : destinationFlag // ignore: cast_nullable_to_non_nullable
              as String,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      coverImageUrl: null == coverImageUrl
          ? _value.coverImageUrl
          : coverImageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      progressPercentage: null == progressPercentage
          ? _value.progressPercentage
          : progressPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      currentCheckpoint: null == currentCheckpoint
          ? _value.currentCheckpoint
          : currentCheckpoint // ignore: cast_nullable_to_non_nullable
              as TripCheckpoint,
      checkpoints: null == checkpoints
          ? _value.checkpoints
          : checkpoints // ignore: cast_nullable_to_non_nullable
              as List<TripCheckpoint>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $TripCheckpointCopyWith<$Res> get currentCheckpoint {
    return $TripCheckpointCopyWith<$Res>(_value.currentCheckpoint, (value) {
      return _then(_value.copyWith(currentCheckpoint: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ClientTripImplCopyWith<$Res>
    implements $ClientTripCopyWith<$Res> {
  factory _$$ClientTripImplCopyWith(
          _$ClientTripImpl value, $Res Function(_$ClientTripImpl) then) =
      __$$ClientTripImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String destination,
      String destinationCountry,
      String destinationFlag,
      DateTime startDate,
      DateTime endDate,
      String coverImageUrl,
      String status,
      double progressPercentage,
      TripCheckpoint currentCheckpoint,
      List<TripCheckpoint> checkpoints});

  @override
  $TripCheckpointCopyWith<$Res> get currentCheckpoint;
}

/// @nodoc
class __$$ClientTripImplCopyWithImpl<$Res>
    extends _$ClientTripCopyWithImpl<$Res, _$ClientTripImpl>
    implements _$$ClientTripImplCopyWith<$Res> {
  __$$ClientTripImplCopyWithImpl(
      _$ClientTripImpl _value, $Res Function(_$ClientTripImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? destination = null,
    Object? destinationCountry = null,
    Object? destinationFlag = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? coverImageUrl = null,
    Object? status = null,
    Object? progressPercentage = null,
    Object? currentCheckpoint = null,
    Object? checkpoints = null,
  }) {
    return _then(_$ClientTripImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      destination: null == destination
          ? _value.destination
          : destination // ignore: cast_nullable_to_non_nullable
              as String,
      destinationCountry: null == destinationCountry
          ? _value.destinationCountry
          : destinationCountry // ignore: cast_nullable_to_non_nullable
              as String,
      destinationFlag: null == destinationFlag
          ? _value.destinationFlag
          : destinationFlag // ignore: cast_nullable_to_non_nullable
              as String,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      coverImageUrl: null == coverImageUrl
          ? _value.coverImageUrl
          : coverImageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      progressPercentage: null == progressPercentage
          ? _value.progressPercentage
          : progressPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      currentCheckpoint: null == currentCheckpoint
          ? _value.currentCheckpoint
          : currentCheckpoint // ignore: cast_nullable_to_non_nullable
              as TripCheckpoint,
      checkpoints: null == checkpoints
          ? _value._checkpoints
          : checkpoints // ignore: cast_nullable_to_non_nullable
              as List<TripCheckpoint>,
    ));
  }
}

/// @nodoc

class _$ClientTripImpl implements _ClientTrip {
  const _$ClientTripImpl(
      {required this.id,
      required this.destination,
      required this.destinationCountry,
      required this.destinationFlag,
      required this.startDate,
      required this.endDate,
      required this.coverImageUrl,
      required this.status,
      required this.progressPercentage,
      required this.currentCheckpoint,
      required final List<TripCheckpoint> checkpoints})
      : _checkpoints = checkpoints;

  @override
  final String id;
  @override
  final String destination;
  @override
  final String destinationCountry;
  @override
  final String destinationFlag;
// emoji
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  @override
  final String coverImageUrl;
  @override
  final String status;
// planejando, confirmado, em andamento, concluído
  @override
  final double progressPercentage;
  @override
  final TripCheckpoint currentCheckpoint;
  final List<TripCheckpoint> _checkpoints;
  @override
  List<TripCheckpoint> get checkpoints {
    if (_checkpoints is EqualUnmodifiableListView) return _checkpoints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_checkpoints);
  }

  @override
  String toString() {
    return 'ClientTrip(id: $id, destination: $destination, destinationCountry: $destinationCountry, destinationFlag: $destinationFlag, startDate: $startDate, endDate: $endDate, coverImageUrl: $coverImageUrl, status: $status, progressPercentage: $progressPercentage, currentCheckpoint: $currentCheckpoint, checkpoints: $checkpoints)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClientTripImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.destination, destination) ||
                other.destination == destination) &&
            (identical(other.destinationCountry, destinationCountry) ||
                other.destinationCountry == destinationCountry) &&
            (identical(other.destinationFlag, destinationFlag) ||
                other.destinationFlag == destinationFlag) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.coverImageUrl, coverImageUrl) ||
                other.coverImageUrl == coverImageUrl) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.progressPercentage, progressPercentage) ||
                other.progressPercentage == progressPercentage) &&
            (identical(other.currentCheckpoint, currentCheckpoint) ||
                other.currentCheckpoint == currentCheckpoint) &&
            const DeepCollectionEquality()
                .equals(other._checkpoints, _checkpoints));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      destination,
      destinationCountry,
      destinationFlag,
      startDate,
      endDate,
      coverImageUrl,
      status,
      progressPercentage,
      currentCheckpoint,
      const DeepCollectionEquality().hash(_checkpoints));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ClientTripImplCopyWith<_$ClientTripImpl> get copyWith =>
      __$$ClientTripImplCopyWithImpl<_$ClientTripImpl>(this, _$identity);
}

abstract class _ClientTrip implements ClientTrip {
  const factory _ClientTrip(
      {required final String id,
      required final String destination,
      required final String destinationCountry,
      required final String destinationFlag,
      required final DateTime startDate,
      required final DateTime endDate,
      required final String coverImageUrl,
      required final String status,
      required final double progressPercentage,
      required final TripCheckpoint currentCheckpoint,
      required final List<TripCheckpoint> checkpoints}) = _$ClientTripImpl;

  @override
  String get id;
  @override
  String get destination;
  @override
  String get destinationCountry;
  @override
  String get destinationFlag;
  @override // emoji
  DateTime get startDate;
  @override
  DateTime get endDate;
  @override
  String get coverImageUrl;
  @override
  String get status;
  @override // planejando, confirmado, em andamento, concluído
  double get progressPercentage;
  @override
  TripCheckpoint get currentCheckpoint;
  @override
  List<TripCheckpoint> get checkpoints;
  @override
  @JsonKey(ignore: true)
  _$$ClientTripImplCopyWith<_$ClientTripImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$TripCheckpoint {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  bool get completed => throw _privateConstructorUsedError;
  bool get isCurrent => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $TripCheckpointCopyWith<TripCheckpoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TripCheckpointCopyWith<$Res> {
  factory $TripCheckpointCopyWith(
          TripCheckpoint value, $Res Function(TripCheckpoint) then) =
      _$TripCheckpointCopyWithImpl<$Res, TripCheckpoint>;
  @useResult
  $Res call({String id, String name, bool completed, bool isCurrent});
}

/// @nodoc
class _$TripCheckpointCopyWithImpl<$Res, $Val extends TripCheckpoint>
    implements $TripCheckpointCopyWith<$Res> {
  _$TripCheckpointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? completed = null,
    Object? isCurrent = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      completed: null == completed
          ? _value.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as bool,
      isCurrent: null == isCurrent
          ? _value.isCurrent
          : isCurrent // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TripCheckpointImplCopyWith<$Res>
    implements $TripCheckpointCopyWith<$Res> {
  factory _$$TripCheckpointImplCopyWith(_$TripCheckpointImpl value,
          $Res Function(_$TripCheckpointImpl) then) =
      __$$TripCheckpointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, bool completed, bool isCurrent});
}

/// @nodoc
class __$$TripCheckpointImplCopyWithImpl<$Res>
    extends _$TripCheckpointCopyWithImpl<$Res, _$TripCheckpointImpl>
    implements _$$TripCheckpointImplCopyWith<$Res> {
  __$$TripCheckpointImplCopyWithImpl(
      _$TripCheckpointImpl _value, $Res Function(_$TripCheckpointImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? completed = null,
    Object? isCurrent = null,
  }) {
    return _then(_$TripCheckpointImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      completed: null == completed
          ? _value.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as bool,
      isCurrent: null == isCurrent
          ? _value.isCurrent
          : isCurrent // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$TripCheckpointImpl implements _TripCheckpoint {
  const _$TripCheckpointImpl(
      {required this.id,
      required this.name,
      required this.completed,
      required this.isCurrent});

  @override
  final String id;
  @override
  final String name;
  @override
  final bool completed;
  @override
  final bool isCurrent;

  @override
  String toString() {
    return 'TripCheckpoint(id: $id, name: $name, completed: $completed, isCurrent: $isCurrent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TripCheckpointImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.completed, completed) ||
                other.completed == completed) &&
            (identical(other.isCurrent, isCurrent) ||
                other.isCurrent == isCurrent));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, name, completed, isCurrent);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TripCheckpointImplCopyWith<_$TripCheckpointImpl> get copyWith =>
      __$$TripCheckpointImplCopyWithImpl<_$TripCheckpointImpl>(
          this, _$identity);
}

abstract class _TripCheckpoint implements TripCheckpoint {
  const factory _TripCheckpoint(
      {required final String id,
      required final String name,
      required final bool completed,
      required final bool isCurrent}) = _$TripCheckpointImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  bool get completed;
  @override
  bool get isCurrent;
  @override
  @JsonKey(ignore: true)
  _$$TripCheckpointImplCopyWith<_$TripCheckpointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ConsultantInfo {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String get photoUrl => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ConsultantInfoCopyWith<ConsultantInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConsultantInfoCopyWith<$Res> {
  factory $ConsultantInfoCopyWith(
          ConsultantInfo value, $Res Function(ConsultantInfo) then) =
      _$ConsultantInfoCopyWithImpl<$Res, ConsultantInfo>;
  @useResult
  $Res call(
      {String id, String name, String phone, String photoUrl, String email});
}

/// @nodoc
class _$ConsultantInfoCopyWithImpl<$Res, $Val extends ConsultantInfo>
    implements $ConsultantInfoCopyWith<$Res> {
  _$ConsultantInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? phone = null,
    Object? photoUrl = null,
    Object? email = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: null == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConsultantInfoImplCopyWith<$Res>
    implements $ConsultantInfoCopyWith<$Res> {
  factory _$$ConsultantInfoImplCopyWith(_$ConsultantInfoImpl value,
          $Res Function(_$ConsultantInfoImpl) then) =
      __$$ConsultantInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id, String name, String phone, String photoUrl, String email});
}

/// @nodoc
class __$$ConsultantInfoImplCopyWithImpl<$Res>
    extends _$ConsultantInfoCopyWithImpl<$Res, _$ConsultantInfoImpl>
    implements _$$ConsultantInfoImplCopyWith<$Res> {
  __$$ConsultantInfoImplCopyWithImpl(
      _$ConsultantInfoImpl _value, $Res Function(_$ConsultantInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? phone = null,
    Object? photoUrl = null,
    Object? email = null,
  }) {
    return _then(_$ConsultantInfoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: null == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ConsultantInfoImpl implements _ConsultantInfo {
  const _$ConsultantInfoImpl(
      {required this.id,
      required this.name,
      required this.phone,
      required this.photoUrl,
      required this.email});

  @override
  final String id;
  @override
  final String name;
  @override
  final String phone;
  @override
  final String photoUrl;
  @override
  final String email;

  @override
  String toString() {
    return 'ConsultantInfo(id: $id, name: $name, phone: $phone, photoUrl: $photoUrl, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConsultantInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.email, email) || other.email == email));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, phone, photoUrl, email);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ConsultantInfoImplCopyWith<_$ConsultantInfoImpl> get copyWith =>
      __$$ConsultantInfoImplCopyWithImpl<_$ConsultantInfoImpl>(
          this, _$identity);
}

abstract class _ConsultantInfo implements ConsultantInfo {
  const factory _ConsultantInfo(
      {required final String id,
      required final String name,
      required final String phone,
      required final String photoUrl,
      required final String email}) = _$ConsultantInfoImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  String get phone;
  @override
  String get photoUrl;
  @override
  String get email;
  @override
  @JsonKey(ignore: true)
  _$$ConsultantInfoImplCopyWith<_$ConsultantInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ClientDocument {
  String get id => throw _privateConstructorUsedError;
  String get type =>
      throw _privateConstructorUsedError; // passport, proposal, insurance, itinerary
  String get displayName => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  DateTime get uploadedAt => throw _privateConstructorUsedError;
  String? get expiresAt => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ClientDocumentCopyWith<ClientDocument> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClientDocumentCopyWith<$Res> {
  factory $ClientDocumentCopyWith(
          ClientDocument value, $Res Function(ClientDocument) then) =
      _$ClientDocumentCopyWithImpl<$Res, ClientDocument>;
  @useResult
  $Res call(
      {String id,
      String type,
      String displayName,
      String url,
      DateTime uploadedAt,
      String? expiresAt});
}

/// @nodoc
class _$ClientDocumentCopyWithImpl<$Res, $Val extends ClientDocument>
    implements $ClientDocumentCopyWith<$Res> {
  _$ClientDocumentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? displayName = null,
    Object? url = null,
    Object? uploadedAt = null,
    Object? expiresAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      uploadedAt: null == uploadedAt
          ? _value.uploadedAt
          : uploadedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ClientDocumentImplCopyWith<$Res>
    implements $ClientDocumentCopyWith<$Res> {
  factory _$$ClientDocumentImplCopyWith(_$ClientDocumentImpl value,
          $Res Function(_$ClientDocumentImpl) then) =
      __$$ClientDocumentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String type,
      String displayName,
      String url,
      DateTime uploadedAt,
      String? expiresAt});
}

/// @nodoc
class __$$ClientDocumentImplCopyWithImpl<$Res>
    extends _$ClientDocumentCopyWithImpl<$Res, _$ClientDocumentImpl>
    implements _$$ClientDocumentImplCopyWith<$Res> {
  __$$ClientDocumentImplCopyWithImpl(
      _$ClientDocumentImpl _value, $Res Function(_$ClientDocumentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? displayName = null,
    Object? url = null,
    Object? uploadedAt = null,
    Object? expiresAt = freezed,
  }) {
    return _then(_$ClientDocumentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      uploadedAt: null == uploadedAt
          ? _value.uploadedAt
          : uploadedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ClientDocumentImpl implements _ClientDocument {
  const _$ClientDocumentImpl(
      {required this.id,
      required this.type,
      required this.displayName,
      required this.url,
      required this.uploadedAt,
      required this.expiresAt});

  @override
  final String id;
  @override
  final String type;
// passport, proposal, insurance, itinerary
  @override
  final String displayName;
  @override
  final String url;
  @override
  final DateTime uploadedAt;
  @override
  final String? expiresAt;

  @override
  String toString() {
    return 'ClientDocument(id: $id, type: $type, displayName: $displayName, url: $url, uploadedAt: $uploadedAt, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClientDocumentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.uploadedAt, uploadedAt) ||
                other.uploadedAt == uploadedAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, id, type, displayName, url, uploadedAt, expiresAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ClientDocumentImplCopyWith<_$ClientDocumentImpl> get copyWith =>
      __$$ClientDocumentImplCopyWithImpl<_$ClientDocumentImpl>(
          this, _$identity);
}

abstract class _ClientDocument implements ClientDocument {
  const factory _ClientDocument(
      {required final String id,
      required final String type,
      required final String displayName,
      required final String url,
      required final DateTime uploadedAt,
      required final String? expiresAt}) = _$ClientDocumentImpl;

  @override
  String get id;
  @override
  String get type;
  @override // passport, proposal, insurance, itinerary
  String get displayName;
  @override
  String get url;
  @override
  DateTime get uploadedAt;
  @override
  String? get expiresAt;
  @override
  @JsonKey(ignore: true)
  _$$ClientDocumentImplCopyWith<_$ClientDocumentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$TravelRecommendation {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  String get destination => throw _privateConstructorUsedError;
  List<String> get reasons =>
      throw _privateConstructorUsedError; // ["Clima tropical", "Praias"]
  double get rating => throw _privateConstructorUsedError;
  int get numberOfReviews => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $TravelRecommendationCopyWith<TravelRecommendation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TravelRecommendationCopyWith<$Res> {
  factory $TravelRecommendationCopyWith(TravelRecommendation value,
          $Res Function(TravelRecommendation) then) =
      _$TravelRecommendationCopyWithImpl<$Res, TravelRecommendation>;
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      String imageUrl,
      String destination,
      List<String> reasons,
      double rating,
      int numberOfReviews});
}

/// @nodoc
class _$TravelRecommendationCopyWithImpl<$Res,
        $Val extends TravelRecommendation>
    implements $TravelRecommendationCopyWith<$Res> {
  _$TravelRecommendationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? imageUrl = null,
    Object? destination = null,
    Object? reasons = null,
    Object? rating = null,
    Object? numberOfReviews = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      destination: null == destination
          ? _value.destination
          : destination // ignore: cast_nullable_to_non_nullable
              as String,
      reasons: null == reasons
          ? _value.reasons
          : reasons // ignore: cast_nullable_to_non_nullable
              as List<String>,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double,
      numberOfReviews: null == numberOfReviews
          ? _value.numberOfReviews
          : numberOfReviews // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TravelRecommendationImplCopyWith<$Res>
    implements $TravelRecommendationCopyWith<$Res> {
  factory _$$TravelRecommendationImplCopyWith(_$TravelRecommendationImpl value,
          $Res Function(_$TravelRecommendationImpl) then) =
      __$$TravelRecommendationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      String imageUrl,
      String destination,
      List<String> reasons,
      double rating,
      int numberOfReviews});
}

/// @nodoc
class __$$TravelRecommendationImplCopyWithImpl<$Res>
    extends _$TravelRecommendationCopyWithImpl<$Res, _$TravelRecommendationImpl>
    implements _$$TravelRecommendationImplCopyWith<$Res> {
  __$$TravelRecommendationImplCopyWithImpl(_$TravelRecommendationImpl _value,
      $Res Function(_$TravelRecommendationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? imageUrl = null,
    Object? destination = null,
    Object? reasons = null,
    Object? rating = null,
    Object? numberOfReviews = null,
  }) {
    return _then(_$TravelRecommendationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      destination: null == destination
          ? _value.destination
          : destination // ignore: cast_nullable_to_non_nullable
              as String,
      reasons: null == reasons
          ? _value._reasons
          : reasons // ignore: cast_nullable_to_non_nullable
              as List<String>,
      rating: null == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double,
      numberOfReviews: null == numberOfReviews
          ? _value.numberOfReviews
          : numberOfReviews // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$TravelRecommendationImpl implements _TravelRecommendation {
  const _$TravelRecommendationImpl(
      {required this.id,
      required this.title,
      required this.description,
      required this.imageUrl,
      required this.destination,
      required final List<String> reasons,
      required this.rating,
      required this.numberOfReviews})
      : _reasons = reasons;

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final String imageUrl;
  @override
  final String destination;
  final List<String> _reasons;
  @override
  List<String> get reasons {
    if (_reasons is EqualUnmodifiableListView) return _reasons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reasons);
  }

// ["Clima tropical", "Praias"]
  @override
  final double rating;
  @override
  final int numberOfReviews;

  @override
  String toString() {
    return 'TravelRecommendation(id: $id, title: $title, description: $description, imageUrl: $imageUrl, destination: $destination, reasons: $reasons, rating: $rating, numberOfReviews: $numberOfReviews)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TravelRecommendationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.destination, destination) ||
                other.destination == destination) &&
            const DeepCollectionEquality().equals(other._reasons, _reasons) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.numberOfReviews, numberOfReviews) ||
                other.numberOfReviews == numberOfReviews));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      imageUrl,
      destination,
      const DeepCollectionEquality().hash(_reasons),
      rating,
      numberOfReviews);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TravelRecommendationImplCopyWith<_$TravelRecommendationImpl>
      get copyWith =>
          __$$TravelRecommendationImplCopyWithImpl<_$TravelRecommendationImpl>(
              this, _$identity);
}

abstract class _TravelRecommendation implements TravelRecommendation {
  const factory _TravelRecommendation(
      {required final String id,
      required final String title,
      required final String description,
      required final String imageUrl,
      required final String destination,
      required final List<String> reasons,
      required final double rating,
      required final int numberOfReviews}) = _$TravelRecommendationImpl;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  String get imageUrl;
  @override
  String get destination;
  @override
  List<String> get reasons;
  @override // ["Clima tropical", "Praias"]
  double get rating;
  @override
  int get numberOfReviews;
  @override
  @JsonKey(ignore: true)
  _$$TravelRecommendationImplCopyWith<_$TravelRecommendationImpl>
      get copyWith => throw _privateConstructorUsedError;
}
