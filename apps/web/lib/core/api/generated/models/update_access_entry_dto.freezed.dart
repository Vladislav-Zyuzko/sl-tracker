// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_access_entry_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateAccessEntryDto {

/// Признак владельца трекера. Снять его с последнего владельца нельзя — 409 `last_instance_owner`.
 bool get isInstanceOwner;
/// Create a copy of UpdateAccessEntryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateAccessEntryDtoCopyWith<UpdateAccessEntryDto> get copyWith => _$UpdateAccessEntryDtoCopyWithImpl<UpdateAccessEntryDto>(this as UpdateAccessEntryDto, _$identity);

  /// Serializes this UpdateAccessEntryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UpdateAccessEntryDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateAccessEntryDto&&(identical(other.isInstanceOwner, _this.isInstanceOwner) || other.isInstanceOwner == _this.isInstanceOwner));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UpdateAccessEntryDto;
  return Object.hash(runtimeType,_this.isInstanceOwner);
}

@override
String toString() {
  final _this = this as UpdateAccessEntryDto;
  return 'UpdateAccessEntryDto(isInstanceOwner: ${_this.isInstanceOwner})';
}


}

/// @nodoc
abstract mixin class $UpdateAccessEntryDtoCopyWith<$Res>  {
  factory $UpdateAccessEntryDtoCopyWith(UpdateAccessEntryDto value, $Res Function(UpdateAccessEntryDto) _then) = _$UpdateAccessEntryDtoCopyWithImpl;
@useResult
$Res call({
 bool isInstanceOwner
});




}
/// @nodoc
class _$UpdateAccessEntryDtoCopyWithImpl<$Res>
    implements $UpdateAccessEntryDtoCopyWith<$Res> {
  _$UpdateAccessEntryDtoCopyWithImpl(this._self, this._then);

  final UpdateAccessEntryDto _self;
  final $Res Function(UpdateAccessEntryDto) _then;

/// Create a copy of UpdateAccessEntryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isInstanceOwner = null,}) {
  return _then(UpdateAccessEntryDto(
isInstanceOwner: null == isInstanceOwner ? _self.isInstanceOwner : isInstanceOwner // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateAccessEntryDto].
extension UpdateAccessEntryDtoPatterns on UpdateAccessEntryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateAccessEntryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateAccessEntryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateAccessEntryDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdateAccessEntryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateAccessEntryDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateAccessEntryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isInstanceOwner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateAccessEntryDto() when $default != null:
return $default(_that.isInstanceOwner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isInstanceOwner)  $default,) {final _that = this;
switch (_that) {
case _UpdateAccessEntryDto():
return $default(_that.isInstanceOwner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isInstanceOwner)?  $default,) {final _that = this;
switch (_that) {
case _UpdateAccessEntryDto() when $default != null:
return $default(_that.isInstanceOwner);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateAccessEntryDto implements UpdateAccessEntryDto {
  const _UpdateAccessEntryDto({required this.isInstanceOwner});
  factory _UpdateAccessEntryDto.fromJson(Map<String, dynamic> json) => _$UpdateAccessEntryDtoFromJson(json);

/// Признак владельца трекера. Снять его с последнего владельца нельзя — 409 `last_instance_owner`.
@override final  bool isInstanceOwner;

/// Create a copy of UpdateAccessEntryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateAccessEntryDtoCopyWith<_UpdateAccessEntryDto> get copyWith => __$UpdateAccessEntryDtoCopyWithImpl<_UpdateAccessEntryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateAccessEntryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateAccessEntryDto&&(identical(other.isInstanceOwner, isInstanceOwner) || other.isInstanceOwner == isInstanceOwner));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,isInstanceOwner);
}

@override
String toString() {
    return 'UpdateAccessEntryDto(isInstanceOwner: $isInstanceOwner)';
}


}

/// @nodoc
abstract mixin class _$UpdateAccessEntryDtoCopyWith<$Res> implements $UpdateAccessEntryDtoCopyWith<$Res> {
  factory _$UpdateAccessEntryDtoCopyWith(_UpdateAccessEntryDto value, $Res Function(_UpdateAccessEntryDto) _then) = __$UpdateAccessEntryDtoCopyWithImpl;
@override @useResult
$Res call({
 bool isInstanceOwner
});




}
/// @nodoc
class __$UpdateAccessEntryDtoCopyWithImpl<$Res>
    implements _$UpdateAccessEntryDtoCopyWith<$Res> {
  __$UpdateAccessEntryDtoCopyWithImpl(this._self, this._then);

  final _UpdateAccessEntryDto _self;
  final $Res Function(_UpdateAccessEntryDto) _then;

/// Create a copy of UpdateAccessEntryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isInstanceOwner = null,}) {
  return _then(_UpdateAccessEntryDto(
isInstanceOwner: null == isInstanceOwner ? _self.isInstanceOwner : isInstanceOwner // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
