// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_response_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HealthResponseDto {

/// `ok` — все зависимости доступны; `degraded` — хотя бы одна нет (HTTP 503)
 HealthResponseDtoStatus get status;/// Время работы процесса, секунды
 num get uptimeSeconds;/// PostgreSQL
 DependencyHealthDto get postgres;/// Redis
 DependencyHealthDto get redis;
/// Create a copy of HealthResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthResponseDtoCopyWith<HealthResponseDto> get copyWith => _$HealthResponseDtoCopyWithImpl<HealthResponseDto>(this as HealthResponseDto, _$identity);

  /// Serializes this HealthResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HealthResponseDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthResponseDto&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.uptimeSeconds, _this.uptimeSeconds) || other.uptimeSeconds == _this.uptimeSeconds)&&(identical(other.postgres, _this.postgres) || other.postgres == _this.postgres)&&(identical(other.redis, _this.redis) || other.redis == _this.redis));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HealthResponseDto;
  return Object.hash(runtimeType,_this.status,_this.uptimeSeconds,_this.postgres,_this.redis);
}

@override
String toString() {
  final _this = this as HealthResponseDto;
  return 'HealthResponseDto(status: ${_this.status}, uptimeSeconds: ${_this.uptimeSeconds}, postgres: ${_this.postgres}, redis: ${_this.redis})';
}


}

/// @nodoc
abstract mixin class $HealthResponseDtoCopyWith<$Res>  {
  factory $HealthResponseDtoCopyWith(HealthResponseDto value, $Res Function(HealthResponseDto) _then) = _$HealthResponseDtoCopyWithImpl;
@useResult
$Res call({
 HealthResponseDtoStatus status, num uptimeSeconds, DependencyHealthDto postgres, DependencyHealthDto redis
});


$DependencyHealthDtoCopyWith<$Res> get postgres;$DependencyHealthDtoCopyWith<$Res> get redis;

}
/// @nodoc
class _$HealthResponseDtoCopyWithImpl<$Res>
    implements $HealthResponseDtoCopyWith<$Res> {
  _$HealthResponseDtoCopyWithImpl(this._self, this._then);

  final HealthResponseDto _self;
  final $Res Function(HealthResponseDto) _then;

/// Create a copy of HealthResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? uptimeSeconds = null,Object? postgres = null,Object? redis = null,}) {
  return _then(HealthResponseDto(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as HealthResponseDtoStatus,uptimeSeconds: null == uptimeSeconds ? _self.uptimeSeconds : uptimeSeconds // ignore: cast_nullable_to_non_nullable
as num,postgres: null == postgres ? _self.postgres : postgres // ignore: cast_nullable_to_non_nullable
as DependencyHealthDto,redis: null == redis ? _self.redis : redis // ignore: cast_nullable_to_non_nullable
as DependencyHealthDto,
  ));
}
/// Create a copy of HealthResponseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DependencyHealthDtoCopyWith<$Res> get postgres {
  
  return $DependencyHealthDtoCopyWith<$Res>(_self.postgres, (value) {
    return _then(_self.copyWith(postgres: value));
  });
}/// Create a copy of HealthResponseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DependencyHealthDtoCopyWith<$Res> get redis {
  
  return $DependencyHealthDtoCopyWith<$Res>(_self.redis, (value) {
    return _then(_self.copyWith(redis: value));
  });
}
}


/// Adds pattern-matching-related methods to [HealthResponseDto].
extension HealthResponseDtoPatterns on HealthResponseDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HealthResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HealthResponseDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HealthResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _HealthResponseDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HealthResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _HealthResponseDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( HealthResponseDtoStatus status,  num uptimeSeconds,  DependencyHealthDto postgres,  DependencyHealthDto redis)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HealthResponseDto() when $default != null:
return $default(_that.status,_that.uptimeSeconds,_that.postgres,_that.redis);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( HealthResponseDtoStatus status,  num uptimeSeconds,  DependencyHealthDto postgres,  DependencyHealthDto redis)  $default,) {final _that = this;
switch (_that) {
case _HealthResponseDto():
return $default(_that.status,_that.uptimeSeconds,_that.postgres,_that.redis);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( HealthResponseDtoStatus status,  num uptimeSeconds,  DependencyHealthDto postgres,  DependencyHealthDto redis)?  $default,) {final _that = this;
switch (_that) {
case _HealthResponseDto() when $default != null:
return $default(_that.status,_that.uptimeSeconds,_that.postgres,_that.redis);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HealthResponseDto implements HealthResponseDto {
  const _HealthResponseDto({required this.status, required this.uptimeSeconds, required this.postgres, required this.redis});
  factory _HealthResponseDto.fromJson(Map<String, dynamic> json) => _$HealthResponseDtoFromJson(json);

/// `ok` — все зависимости доступны; `degraded` — хотя бы одна нет (HTTP 503)
@override final  HealthResponseDtoStatus status;
/// Время работы процесса, секунды
@override final  num uptimeSeconds;
/// PostgreSQL
@override final  DependencyHealthDto postgres;
/// Redis
@override final  DependencyHealthDto redis;

/// Create a copy of HealthResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HealthResponseDtoCopyWith<_HealthResponseDto> get copyWith => __$HealthResponseDtoCopyWithImpl<_HealthResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HealthResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HealthResponseDto&&(identical(other.status, status) || other.status == status)&&(identical(other.uptimeSeconds, uptimeSeconds) || other.uptimeSeconds == uptimeSeconds)&&(identical(other.postgres, postgres) || other.postgres == postgres)&&(identical(other.redis, redis) || other.redis == redis));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,status,uptimeSeconds,postgres,redis);
}

@override
String toString() {
    return 'HealthResponseDto(status: $status, uptimeSeconds: $uptimeSeconds, postgres: $postgres, redis: $redis)';
}


}

/// @nodoc
abstract mixin class _$HealthResponseDtoCopyWith<$Res> implements $HealthResponseDtoCopyWith<$Res> {
  factory _$HealthResponseDtoCopyWith(_HealthResponseDto value, $Res Function(_HealthResponseDto) _then) = __$HealthResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 HealthResponseDtoStatus status, num uptimeSeconds, DependencyHealthDto postgres, DependencyHealthDto redis
});


@override $DependencyHealthDtoCopyWith<$Res> get postgres;@override $DependencyHealthDtoCopyWith<$Res> get redis;

}
/// @nodoc
class __$HealthResponseDtoCopyWithImpl<$Res>
    implements _$HealthResponseDtoCopyWith<$Res> {
  __$HealthResponseDtoCopyWithImpl(this._self, this._then);

  final _HealthResponseDto _self;
  final $Res Function(_HealthResponseDto) _then;

/// Create a copy of HealthResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? uptimeSeconds = null,Object? postgres = null,Object? redis = null,}) {
  return _then(_HealthResponseDto(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as HealthResponseDtoStatus,uptimeSeconds: null == uptimeSeconds ? _self.uptimeSeconds : uptimeSeconds // ignore: cast_nullable_to_non_nullable
as num,postgres: null == postgres ? _self.postgres : postgres // ignore: cast_nullable_to_non_nullable
as DependencyHealthDto,redis: null == redis ? _self.redis : redis // ignore: cast_nullable_to_non_nullable
as DependencyHealthDto,
  ));
}

/// Create a copy of HealthResponseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DependencyHealthDtoCopyWith<$Res> get postgres {
  
  return $DependencyHealthDtoCopyWith<$Res>(_self.postgres, (value) {
    return _then(_self.copyWith(postgres: value));
  });
}/// Create a copy of HealthResponseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DependencyHealthDtoCopyWith<$Res> get redis {
  
  return $DependencyHealthDtoCopyWith<$Res>(_self.redis, (value) {
    return _then(_self.copyWith(redis: value));
  });
}
}

// dart format on
