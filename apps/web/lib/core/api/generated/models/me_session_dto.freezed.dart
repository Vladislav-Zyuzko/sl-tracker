// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'me_session_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MeSessionDto {

/// Чем предъявлена сессия. На права не влияет — это транспорт (ADR-0002).
 MeSessionDtoKind get kind;/// Когда сессия истекает
 DateTime get expiresAt;
/// Create a copy of MeSessionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeSessionDtoCopyWith<MeSessionDto> get copyWith => _$MeSessionDtoCopyWithImpl<MeSessionDto>(this as MeSessionDto, _$identity);

  /// Serializes this MeSessionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MeSessionDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MeSessionDto&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MeSessionDto;
  return Object.hash(runtimeType,_this.kind,_this.expiresAt);
}

@override
String toString() {
  final _this = this as MeSessionDto;
  return 'MeSessionDto(kind: ${_this.kind}, expiresAt: ${_this.expiresAt})';
}


}

/// @nodoc
abstract mixin class $MeSessionDtoCopyWith<$Res>  {
  factory $MeSessionDtoCopyWith(MeSessionDto value, $Res Function(MeSessionDto) _then) = _$MeSessionDtoCopyWithImpl;
@useResult
$Res call({
 MeSessionDtoKind kind, DateTime expiresAt
});




}
/// @nodoc
class _$MeSessionDtoCopyWithImpl<$Res>
    implements $MeSessionDtoCopyWith<$Res> {
  _$MeSessionDtoCopyWithImpl(this._self, this._then);

  final MeSessionDto _self;
  final $Res Function(MeSessionDto) _then;

/// Create a copy of MeSessionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? expiresAt = null,}) {
  return _then(MeSessionDto(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MeSessionDtoKind,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MeSessionDto].
extension MeSessionDtoPatterns on MeSessionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MeSessionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MeSessionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MeSessionDto value)  $default,){
final _that = this;
switch (_that) {
case _MeSessionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MeSessionDto value)?  $default,){
final _that = this;
switch (_that) {
case _MeSessionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MeSessionDtoKind kind,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MeSessionDto() when $default != null:
return $default(_that.kind,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MeSessionDtoKind kind,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _MeSessionDto():
return $default(_that.kind,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MeSessionDtoKind kind,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _MeSessionDto() when $default != null:
return $default(_that.kind,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MeSessionDto implements MeSessionDto {
  const _MeSessionDto({required this.kind, required this.expiresAt});
  factory _MeSessionDto.fromJson(Map<String, dynamic> json) => _$MeSessionDtoFromJson(json);

/// Чем предъявлена сессия. На права не влияет — это транспорт (ADR-0002).
@override final  MeSessionDtoKind kind;
/// Когда сессия истекает
@override final  DateTime expiresAt;

/// Create a copy of MeSessionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeSessionDtoCopyWith<_MeSessionDto> get copyWith => __$MeSessionDtoCopyWithImpl<_MeSessionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MeSessionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MeSessionDto&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,expiresAt);
}

@override
String toString() {
    return 'MeSessionDto(kind: $kind, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$MeSessionDtoCopyWith<$Res> implements $MeSessionDtoCopyWith<$Res> {
  factory _$MeSessionDtoCopyWith(_MeSessionDto value, $Res Function(_MeSessionDto) _then) = __$MeSessionDtoCopyWithImpl;
@override @useResult
$Res call({
 MeSessionDtoKind kind, DateTime expiresAt
});




}
/// @nodoc
class __$MeSessionDtoCopyWithImpl<$Res>
    implements _$MeSessionDtoCopyWith<$Res> {
  __$MeSessionDtoCopyWithImpl(this._self, this._then);

  final _MeSessionDto _self;
  final $Res Function(_MeSessionDto) _then;

/// Create a copy of MeSessionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? expiresAt = null,}) {
  return _then(_MeSessionDto(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MeSessionDtoKind,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
