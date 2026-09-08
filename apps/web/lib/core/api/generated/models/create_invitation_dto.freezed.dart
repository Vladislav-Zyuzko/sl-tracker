// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_invitation_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreateInvitationDto {

/// Роль для тех, кто вступит. Роли «администратор» в списке нет (D-05).
 CreateInvitationDtoRole get role;/// Срок жизни ссылки в днях. Бессрочных приглашений нет (US-20).
 CreateInvitationDtoExpiresInDays get expiresInDays;
/// Create a copy of CreateInvitationDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateInvitationDtoCopyWith<CreateInvitationDto> get copyWith => _$CreateInvitationDtoCopyWithImpl<CreateInvitationDto>(this as CreateInvitationDto, _$identity);

  /// Serializes this CreateInvitationDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CreateInvitationDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateInvitationDto&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.expiresInDays, _this.expiresInDays) || other.expiresInDays == _this.expiresInDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CreateInvitationDto;
  return Object.hash(runtimeType,_this.role,_this.expiresInDays);
}

@override
String toString() {
  final _this = this as CreateInvitationDto;
  return 'CreateInvitationDto(role: ${_this.role}, expiresInDays: ${_this.expiresInDays})';
}


}

/// @nodoc
abstract mixin class $CreateInvitationDtoCopyWith<$Res>  {
  factory $CreateInvitationDtoCopyWith(CreateInvitationDto value, $Res Function(CreateInvitationDto) _then) = _$CreateInvitationDtoCopyWithImpl;
@useResult
$Res call({
 CreateInvitationDtoRole role, CreateInvitationDtoExpiresInDays expiresInDays
});




}
/// @nodoc
class _$CreateInvitationDtoCopyWithImpl<$Res>
    implements $CreateInvitationDtoCopyWith<$Res> {
  _$CreateInvitationDtoCopyWithImpl(this._self, this._then);

  final CreateInvitationDto _self;
  final $Res Function(CreateInvitationDto) _then;

/// Create a copy of CreateInvitationDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? role = null,Object? expiresInDays = null,}) {
  return _then(CreateInvitationDto(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as CreateInvitationDtoRole,expiresInDays: null == expiresInDays ? _self.expiresInDays : expiresInDays // ignore: cast_nullable_to_non_nullable
as CreateInvitationDtoExpiresInDays,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateInvitationDto].
extension CreateInvitationDtoPatterns on CreateInvitationDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateInvitationDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateInvitationDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateInvitationDto value)  $default,){
final _that = this;
switch (_that) {
case _CreateInvitationDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateInvitationDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreateInvitationDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CreateInvitationDtoRole role,  CreateInvitationDtoExpiresInDays expiresInDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateInvitationDto() when $default != null:
return $default(_that.role,_that.expiresInDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CreateInvitationDtoRole role,  CreateInvitationDtoExpiresInDays expiresInDays)  $default,) {final _that = this;
switch (_that) {
case _CreateInvitationDto():
return $default(_that.role,_that.expiresInDays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CreateInvitationDtoRole role,  CreateInvitationDtoExpiresInDays expiresInDays)?  $default,) {final _that = this;
switch (_that) {
case _CreateInvitationDto() when $default != null:
return $default(_that.role,_that.expiresInDays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateInvitationDto implements CreateInvitationDto {
  const _CreateInvitationDto({required this.role, this.expiresInDays = CreateInvitationDtoExpiresInDays.value7});
  factory _CreateInvitationDto.fromJson(Map<String, dynamic> json) => _$CreateInvitationDtoFromJson(json);

/// Роль для тех, кто вступит. Роли «администратор» в списке нет (D-05).
@override final  CreateInvitationDtoRole role;
/// Срок жизни ссылки в днях. Бессрочных приглашений нет (US-20).
@override@JsonKey() final  CreateInvitationDtoExpiresInDays expiresInDays;

/// Create a copy of CreateInvitationDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateInvitationDtoCopyWith<_CreateInvitationDto> get copyWith => __$CreateInvitationDtoCopyWithImpl<_CreateInvitationDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateInvitationDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateInvitationDto&&(identical(other.role, role) || other.role == role)&&(identical(other.expiresInDays, expiresInDays) || other.expiresInDays == expiresInDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,role,expiresInDays);
}

@override
String toString() {
    return 'CreateInvitationDto(role: $role, expiresInDays: $expiresInDays)';
}


}

/// @nodoc
abstract mixin class _$CreateInvitationDtoCopyWith<$Res> implements $CreateInvitationDtoCopyWith<$Res> {
  factory _$CreateInvitationDtoCopyWith(_CreateInvitationDto value, $Res Function(_CreateInvitationDto) _then) = __$CreateInvitationDtoCopyWithImpl;
@override @useResult
$Res call({
 CreateInvitationDtoRole role, CreateInvitationDtoExpiresInDays expiresInDays
});




}
/// @nodoc
class __$CreateInvitationDtoCopyWithImpl<$Res>
    implements _$CreateInvitationDtoCopyWith<$Res> {
  __$CreateInvitationDtoCopyWithImpl(this._self, this._then);

  final _CreateInvitationDto _self;
  final $Res Function(_CreateInvitationDto) _then;

/// Create a copy of CreateInvitationDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? role = null,Object? expiresInDays = null,}) {
  return _then(_CreateInvitationDto(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as CreateInvitationDtoRole,expiresInDays: null == expiresInDays ? _self.expiresInDays : expiresInDays // ignore: cast_nullable_to_non_nullable
as CreateInvitationDtoExpiresInDays,
  ));
}


}

// dart format on
