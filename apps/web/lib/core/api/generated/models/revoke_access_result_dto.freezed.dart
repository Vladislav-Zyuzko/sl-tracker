// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'revoke_access_result_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RevokeAccessResultDto {

/// Сколько активных сессий человека погашено немедленно (US-09).
 num get revokedSessions;
/// Create a copy of RevokeAccessResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RevokeAccessResultDtoCopyWith<RevokeAccessResultDto> get copyWith => _$RevokeAccessResultDtoCopyWithImpl<RevokeAccessResultDto>(this as RevokeAccessResultDto, _$identity);

  /// Serializes this RevokeAccessResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RevokeAccessResultDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RevokeAccessResultDto&&(identical(other.revokedSessions, _this.revokedSessions) || other.revokedSessions == _this.revokedSessions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RevokeAccessResultDto;
  return Object.hash(runtimeType,_this.revokedSessions);
}

@override
String toString() {
  final _this = this as RevokeAccessResultDto;
  return 'RevokeAccessResultDto(revokedSessions: ${_this.revokedSessions})';
}


}

/// @nodoc
abstract mixin class $RevokeAccessResultDtoCopyWith<$Res>  {
  factory $RevokeAccessResultDtoCopyWith(RevokeAccessResultDto value, $Res Function(RevokeAccessResultDto) _then) = _$RevokeAccessResultDtoCopyWithImpl;
@useResult
$Res call({
 num revokedSessions
});




}
/// @nodoc
class _$RevokeAccessResultDtoCopyWithImpl<$Res>
    implements $RevokeAccessResultDtoCopyWith<$Res> {
  _$RevokeAccessResultDtoCopyWithImpl(this._self, this._then);

  final RevokeAccessResultDto _self;
  final $Res Function(RevokeAccessResultDto) _then;

/// Create a copy of RevokeAccessResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? revokedSessions = null,}) {
  return _then(RevokeAccessResultDto(
revokedSessions: null == revokedSessions ? _self.revokedSessions : revokedSessions // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [RevokeAccessResultDto].
extension RevokeAccessResultDtoPatterns on RevokeAccessResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RevokeAccessResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RevokeAccessResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RevokeAccessResultDto value)  $default,){
final _that = this;
switch (_that) {
case _RevokeAccessResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RevokeAccessResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _RevokeAccessResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( num revokedSessions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RevokeAccessResultDto() when $default != null:
return $default(_that.revokedSessions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( num revokedSessions)  $default,) {final _that = this;
switch (_that) {
case _RevokeAccessResultDto():
return $default(_that.revokedSessions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( num revokedSessions)?  $default,) {final _that = this;
switch (_that) {
case _RevokeAccessResultDto() when $default != null:
return $default(_that.revokedSessions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RevokeAccessResultDto implements RevokeAccessResultDto {
  const _RevokeAccessResultDto({required this.revokedSessions});
  factory _RevokeAccessResultDto.fromJson(Map<String, dynamic> json) => _$RevokeAccessResultDtoFromJson(json);

/// Сколько активных сессий человека погашено немедленно (US-09).
@override final  num revokedSessions;

/// Create a copy of RevokeAccessResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RevokeAccessResultDtoCopyWith<_RevokeAccessResultDto> get copyWith => __$RevokeAccessResultDtoCopyWithImpl<_RevokeAccessResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RevokeAccessResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RevokeAccessResultDto&&(identical(other.revokedSessions, revokedSessions) || other.revokedSessions == revokedSessions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,revokedSessions);
}

@override
String toString() {
    return 'RevokeAccessResultDto(revokedSessions: $revokedSessions)';
}


}

/// @nodoc
abstract mixin class _$RevokeAccessResultDtoCopyWith<$Res> implements $RevokeAccessResultDtoCopyWith<$Res> {
  factory _$RevokeAccessResultDtoCopyWith(_RevokeAccessResultDto value, $Res Function(_RevokeAccessResultDto) _then) = __$RevokeAccessResultDtoCopyWithImpl;
@override @useResult
$Res call({
 num revokedSessions
});




}
/// @nodoc
class __$RevokeAccessResultDtoCopyWithImpl<$Res>
    implements _$RevokeAccessResultDtoCopyWith<$Res> {
  __$RevokeAccessResultDtoCopyWithImpl(this._self, this._then);

  final _RevokeAccessResultDto _self;
  final $Res Function(_RevokeAccessResultDto) _then;

/// Create a copy of RevokeAccessResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? revokedSessions = null,}) {
  return _then(_RevokeAccessResultDto(
revokedSessions: null == revokedSessions ? _self.revokedSessions : revokedSessions // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}

// dart format on
