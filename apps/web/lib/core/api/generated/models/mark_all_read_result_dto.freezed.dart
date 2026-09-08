// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mark_all_read_result_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MarkAllReadResultDto {

/// Сколько уведомлений стало прочитанными
 num get updated;
/// Create a copy of MarkAllReadResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkAllReadResultDtoCopyWith<MarkAllReadResultDto> get copyWith => _$MarkAllReadResultDtoCopyWithImpl<MarkAllReadResultDto>(this as MarkAllReadResultDto, _$identity);

  /// Serializes this MarkAllReadResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MarkAllReadResultDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkAllReadResultDto&&(identical(other.updated, _this.updated) || other.updated == _this.updated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MarkAllReadResultDto;
  return Object.hash(runtimeType,_this.updated);
}

@override
String toString() {
  final _this = this as MarkAllReadResultDto;
  return 'MarkAllReadResultDto(updated: ${_this.updated})';
}


}

/// @nodoc
abstract mixin class $MarkAllReadResultDtoCopyWith<$Res>  {
  factory $MarkAllReadResultDtoCopyWith(MarkAllReadResultDto value, $Res Function(MarkAllReadResultDto) _then) = _$MarkAllReadResultDtoCopyWithImpl;
@useResult
$Res call({
 num updated
});




}
/// @nodoc
class _$MarkAllReadResultDtoCopyWithImpl<$Res>
    implements $MarkAllReadResultDtoCopyWith<$Res> {
  _$MarkAllReadResultDtoCopyWithImpl(this._self, this._then);

  final MarkAllReadResultDto _self;
  final $Res Function(MarkAllReadResultDto) _then;

/// Create a copy of MarkAllReadResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? updated = null,}) {
  return _then(MarkAllReadResultDto(
updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [MarkAllReadResultDto].
extension MarkAllReadResultDtoPatterns on MarkAllReadResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MarkAllReadResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MarkAllReadResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MarkAllReadResultDto value)  $default,){
final _that = this;
switch (_that) {
case _MarkAllReadResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MarkAllReadResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _MarkAllReadResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( num updated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MarkAllReadResultDto() when $default != null:
return $default(_that.updated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( num updated)  $default,) {final _that = this;
switch (_that) {
case _MarkAllReadResultDto():
return $default(_that.updated);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( num updated)?  $default,) {final _that = this;
switch (_that) {
case _MarkAllReadResultDto() when $default != null:
return $default(_that.updated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MarkAllReadResultDto implements MarkAllReadResultDto {
  const _MarkAllReadResultDto({required this.updated});
  factory _MarkAllReadResultDto.fromJson(Map<String, dynamic> json) => _$MarkAllReadResultDtoFromJson(json);

/// Сколько уведомлений стало прочитанными
@override final  num updated;

/// Create a copy of MarkAllReadResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MarkAllReadResultDtoCopyWith<_MarkAllReadResultDto> get copyWith => __$MarkAllReadResultDtoCopyWithImpl<_MarkAllReadResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MarkAllReadResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MarkAllReadResultDto&&(identical(other.updated, updated) || other.updated == updated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,updated);
}

@override
String toString() {
    return 'MarkAllReadResultDto(updated: $updated)';
}


}

/// @nodoc
abstract mixin class _$MarkAllReadResultDtoCopyWith<$Res> implements $MarkAllReadResultDtoCopyWith<$Res> {
  factory _$MarkAllReadResultDtoCopyWith(_MarkAllReadResultDto value, $Res Function(_MarkAllReadResultDto) _then) = __$MarkAllReadResultDtoCopyWithImpl;
@override @useResult
$Res call({
 num updated
});




}
/// @nodoc
class __$MarkAllReadResultDtoCopyWithImpl<$Res>
    implements _$MarkAllReadResultDtoCopyWith<$Res> {
  __$MarkAllReadResultDtoCopyWithImpl(this._self, this._then);

  final _MarkAllReadResultDto _self;
  final $Res Function(_MarkAllReadResultDto) _then;

/// Create a copy of MarkAllReadResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? updated = null,}) {
  return _then(_MarkAllReadResultDto(
updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}

// dart format on
