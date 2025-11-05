// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'energy_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EnergyData _$EnergyDataFromJson(Map<String, dynamic> json) {
  return _EnergyData.fromJson(json);
}

/// @nodoc
mixin _$EnergyData {
  String get timestamp => throw _privateConstructorUsedError;
  double get watts => throw _privateConstructorUsedError;
  int get applianceId => throw _privateConstructorUsedError;

  /// Serializes this EnergyData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EnergyData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EnergyDataCopyWith<EnergyData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EnergyDataCopyWith<$Res> {
  factory $EnergyDataCopyWith(
          EnergyData value, $Res Function(EnergyData) then) =
      _$EnergyDataCopyWithImpl<$Res, EnergyData>;
  @useResult
  $Res call({String timestamp, double watts, int applianceId});
}

/// @nodoc
class _$EnergyDataCopyWithImpl<$Res, $Val extends EnergyData>
    implements $EnergyDataCopyWith<$Res> {
  _$EnergyDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EnergyData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? watts = null,
    Object? applianceId = null,
  }) {
    return _then(_value.copyWith(
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as String,
      watts: null == watts
          ? _value.watts
          : watts // ignore: cast_nullable_to_non_nullable
              as double,
      applianceId: null == applianceId
          ? _value.applianceId
          : applianceId // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EnergyDataImplCopyWith<$Res>
    implements $EnergyDataCopyWith<$Res> {
  factory _$$EnergyDataImplCopyWith(
          _$EnergyDataImpl value, $Res Function(_$EnergyDataImpl) then) =
      __$$EnergyDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String timestamp, double watts, int applianceId});
}

/// @nodoc
class __$$EnergyDataImplCopyWithImpl<$Res>
    extends _$EnergyDataCopyWithImpl<$Res, _$EnergyDataImpl>
    implements _$$EnergyDataImplCopyWith<$Res> {
  __$$EnergyDataImplCopyWithImpl(
      _$EnergyDataImpl _value, $Res Function(_$EnergyDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of EnergyData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? watts = null,
    Object? applianceId = null,
  }) {
    return _then(_$EnergyDataImpl(
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as String,
      watts: null == watts
          ? _value.watts
          : watts // ignore: cast_nullable_to_non_nullable
              as double,
      applianceId: null == applianceId
          ? _value.applianceId
          : applianceId // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EnergyDataImpl implements _EnergyData {
  const _$EnergyDataImpl(
      {required this.timestamp, required this.watts, this.applianceId = 1});

  factory _$EnergyDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$EnergyDataImplFromJson(json);

  @override
  final String timestamp;
  @override
  final double watts;
  @override
  @JsonKey()
  final int applianceId;

  @override
  String toString() {
    return 'EnergyData(timestamp: $timestamp, watts: $watts, applianceId: $applianceId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EnergyDataImpl &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.watts, watts) || other.watts == watts) &&
            (identical(other.applianceId, applianceId) ||
                other.applianceId == applianceId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, timestamp, watts, applianceId);

  /// Create a copy of EnergyData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EnergyDataImplCopyWith<_$EnergyDataImpl> get copyWith =>
      __$$EnergyDataImplCopyWithImpl<_$EnergyDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EnergyDataImplToJson(
      this,
    );
  }
}

abstract class _EnergyData implements EnergyData {
  const factory _EnergyData(
      {required final String timestamp,
      required final double watts,
      final int applianceId}) = _$EnergyDataImpl;

  factory _EnergyData.fromJson(Map<String, dynamic> json) =
      _$EnergyDataImpl.fromJson;

  @override
  String get timestamp;
  @override
  double get watts;
  @override
  int get applianceId;

  /// Create a copy of EnergyData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EnergyDataImplCopyWith<_$EnergyDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
