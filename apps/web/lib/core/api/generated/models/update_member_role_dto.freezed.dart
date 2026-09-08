// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_member_role_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateMemberRoleDto {

/// Новая роль. Понизить последнего администратора нельзя — 409 `last_project_admin` (permissions.md, п. 7).
 UpdateMemberRoleDtoRole get role;
/// Create a copy of UpdateMemberRoleDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateMemberRoleDtoCopyWith<UpdateMemberRoleDto> get copyWith => _$UpdateMemberRoleDtoCopyWithImpl<UpdateMemberRoleDto>(this as UpdateMemberRoleDto, _$identity);

  /// Serializes this UpdateMemberRoleDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UpdateMemberRoleDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateMemberRoleDto&&(identical(other.role, _this.role) || other.role == _this.role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UpdateMemberRoleDto;
  return Object.hash(runtimeType,_this.role);
}

@override
String toString() {
  final _this = this as UpdateMemberRoleDto;
  return 'UpdateMemberRoleDto(role: ${_this.role})';
}


}

/// @nodoc
abstract mixin class $UpdateMemberRoleDtoCopyWith<$Res>  {
  factory $UpdateMemberRoleDtoCopyWith(UpdateMemberRoleDto value, $Res Function(UpdateMemberRoleDto) _then) = _$UpdateMemberRoleDtoCopyWithImpl;
@useResult
$Res call({
 UpdateMemberRoleDtoRole role
});




}
/// @nodoc
class _$UpdateMemberRoleDtoCopyWithImpl<$Res>
    implements $UpdateMemberRoleDtoCopyWith<$Res> {
  _$UpdateMemberRoleDtoCopyWithImpl(this._self, this._then);

  final UpdateMemberRoleDto _self;
  final $Res Function(UpdateMemberRoleDto) _then;

/// Create a copy of UpdateMemberRoleDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? role = null,}) {
  return _then(UpdateMemberRoleDto(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UpdateMemberRoleDtoRole,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateMemberRoleDto].
extension UpdateMemberRoleDtoPatterns on UpdateMemberRoleDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateMemberRoleDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateMemberRoleDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateMemberRoleDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdateMemberRoleDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateMemberRoleDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateMemberRoleDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UpdateMemberRoleDtoRole role)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateMemberRoleDto() when $default != null:
return $default(_that.role);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UpdateMemberRoleDtoRole role)  $default,) {final _that = this;
switch (_that) {
case _UpdateMemberRoleDto():
return $default(_that.role);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UpdateMemberRoleDtoRole role)?  $default,) {final _that = this;
switch (_that) {
case _UpdateMemberRoleDto() when $default != null:
return $default(_that.role);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateMemberRoleDto implements UpdateMemberRoleDto {
  const _UpdateMemberRoleDto({required this.role});
  factory _UpdateMemberRoleDto.fromJson(Map<String, dynamic> json) => _$UpdateMemberRoleDtoFromJson(json);

/// Новая роль. Понизить последнего администратора нельзя — 409 `last_project_admin` (permissions.md, п. 7).
@override final  UpdateMemberRoleDtoRole role;

/// Create a copy of UpdateMemberRoleDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateMemberRoleDtoCopyWith<_UpdateMemberRoleDto> get copyWith => __$UpdateMemberRoleDtoCopyWithImpl<_UpdateMemberRoleDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateMemberRoleDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateMemberRoleDto&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,role);
}

@override
String toString() {
    return 'UpdateMemberRoleDto(role: $role)';
}


}

/// @nodoc
abstract mixin class _$UpdateMemberRoleDtoCopyWith<$Res> implements $UpdateMemberRoleDtoCopyWith<$Res> {
  factory _$UpdateMemberRoleDtoCopyWith(_UpdateMemberRoleDto value, $Res Function(_UpdateMemberRoleDto) _then) = __$UpdateMemberRoleDtoCopyWithImpl;
@override @useResult
$Res call({
 UpdateMemberRoleDtoRole role
});




}
/// @nodoc
class __$UpdateMemberRoleDtoCopyWithImpl<$Res>
    implements _$UpdateMemberRoleDtoCopyWith<$Res> {
  __$UpdateMemberRoleDtoCopyWithImpl(this._self, this._then);

  final _UpdateMemberRoleDto _self;
  final $Res Function(_UpdateMemberRoleDto) _then;

/// Create a copy of UpdateMemberRoleDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? role = null,}) {
  return _then(_UpdateMemberRoleDto(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UpdateMemberRoleDtoRole,
  ));
}


}

// dart format on
