// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'remove_member_result_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RemoveMemberResultDto {

/// Сколько задач осталось без исполнителя: у задач исключённого поле «Исполнитель» очищается, и на каждую пишется запись истории (D-31).
 num get unassignedIssues;
/// Create a copy of RemoveMemberResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RemoveMemberResultDtoCopyWith<RemoveMemberResultDto> get copyWith => _$RemoveMemberResultDtoCopyWithImpl<RemoveMemberResultDto>(this as RemoveMemberResultDto, _$identity);

  /// Serializes this RemoveMemberResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RemoveMemberResultDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RemoveMemberResultDto&&(identical(other.unassignedIssues, _this.unassignedIssues) || other.unassignedIssues == _this.unassignedIssues));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RemoveMemberResultDto;
  return Object.hash(runtimeType,_this.unassignedIssues);
}

@override
String toString() {
  final _this = this as RemoveMemberResultDto;
  return 'RemoveMemberResultDto(unassignedIssues: ${_this.unassignedIssues})';
}


}

/// @nodoc
abstract mixin class $RemoveMemberResultDtoCopyWith<$Res>  {
  factory $RemoveMemberResultDtoCopyWith(RemoveMemberResultDto value, $Res Function(RemoveMemberResultDto) _then) = _$RemoveMemberResultDtoCopyWithImpl;
@useResult
$Res call({
 num unassignedIssues
});




}
/// @nodoc
class _$RemoveMemberResultDtoCopyWithImpl<$Res>
    implements $RemoveMemberResultDtoCopyWith<$Res> {
  _$RemoveMemberResultDtoCopyWithImpl(this._self, this._then);

  final RemoveMemberResultDto _self;
  final $Res Function(RemoveMemberResultDto) _then;

/// Create a copy of RemoveMemberResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? unassignedIssues = null,}) {
  return _then(RemoveMemberResultDto(
unassignedIssues: null == unassignedIssues ? _self.unassignedIssues : unassignedIssues // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [RemoveMemberResultDto].
extension RemoveMemberResultDtoPatterns on RemoveMemberResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RemoveMemberResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RemoveMemberResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RemoveMemberResultDto value)  $default,){
final _that = this;
switch (_that) {
case _RemoveMemberResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RemoveMemberResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _RemoveMemberResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( num unassignedIssues)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RemoveMemberResultDto() when $default != null:
return $default(_that.unassignedIssues);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( num unassignedIssues)  $default,) {final _that = this;
switch (_that) {
case _RemoveMemberResultDto():
return $default(_that.unassignedIssues);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( num unassignedIssues)?  $default,) {final _that = this;
switch (_that) {
case _RemoveMemberResultDto() when $default != null:
return $default(_that.unassignedIssues);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RemoveMemberResultDto implements RemoveMemberResultDto {
  const _RemoveMemberResultDto({required this.unassignedIssues});
  factory _RemoveMemberResultDto.fromJson(Map<String, dynamic> json) => _$RemoveMemberResultDtoFromJson(json);

/// Сколько задач осталось без исполнителя: у задач исключённого поле «Исполнитель» очищается, и на каждую пишется запись истории (D-31).
@override final  num unassignedIssues;

/// Create a copy of RemoveMemberResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RemoveMemberResultDtoCopyWith<_RemoveMemberResultDto> get copyWith => __$RemoveMemberResultDtoCopyWithImpl<_RemoveMemberResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RemoveMemberResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RemoveMemberResultDto&&(identical(other.unassignedIssues, unassignedIssues) || other.unassignedIssues == unassignedIssues));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,unassignedIssues);
}

@override
String toString() {
    return 'RemoveMemberResultDto(unassignedIssues: $unassignedIssues)';
}


}

/// @nodoc
abstract mixin class _$RemoveMemberResultDtoCopyWith<$Res> implements $RemoveMemberResultDtoCopyWith<$Res> {
  factory _$RemoveMemberResultDtoCopyWith(_RemoveMemberResultDto value, $Res Function(_RemoveMemberResultDto) _then) = __$RemoveMemberResultDtoCopyWithImpl;
@override @useResult
$Res call({
 num unassignedIssues
});




}
/// @nodoc
class __$RemoveMemberResultDtoCopyWithImpl<$Res>
    implements _$RemoveMemberResultDtoCopyWith<$Res> {
  __$RemoveMemberResultDtoCopyWithImpl(this._self, this._then);

  final _RemoveMemberResultDto _self;
  final $Res Function(_RemoveMemberResultDto) _then;

/// Create a copy of RemoveMemberResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? unassignedIssues = null,}) {
  return _then(_RemoveMemberResultDto(
unassignedIssues: null == unassignedIssues ? _self.unassignedIssues : unassignedIssues // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}

// dart format on
