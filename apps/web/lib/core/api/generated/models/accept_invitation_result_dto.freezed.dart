// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'accept_invitation_result_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AcceptInvitationResultDto {

/// Куда переходить после вступления
 String get projectSlug;/// Роль пользователя в проекте после приёма
 AcceptInvitationResultDtoRole get role;/// Пользователь уже был участником; роль не изменилась
 bool get alreadyMember;
/// Create a copy of AcceptInvitationResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AcceptInvitationResultDtoCopyWith<AcceptInvitationResultDto> get copyWith => _$AcceptInvitationResultDtoCopyWithImpl<AcceptInvitationResultDto>(this as AcceptInvitationResultDto, _$identity);

  /// Serializes this AcceptInvitationResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AcceptInvitationResultDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AcceptInvitationResultDto&&(identical(other.projectSlug, _this.projectSlug) || other.projectSlug == _this.projectSlug)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.alreadyMember, _this.alreadyMember) || other.alreadyMember == _this.alreadyMember));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AcceptInvitationResultDto;
  return Object.hash(runtimeType,_this.projectSlug,_this.role,_this.alreadyMember);
}

@override
String toString() {
  final _this = this as AcceptInvitationResultDto;
  return 'AcceptInvitationResultDto(projectSlug: ${_this.projectSlug}, role: ${_this.role}, alreadyMember: ${_this.alreadyMember})';
}


}

/// @nodoc
abstract mixin class $AcceptInvitationResultDtoCopyWith<$Res>  {
  factory $AcceptInvitationResultDtoCopyWith(AcceptInvitationResultDto value, $Res Function(AcceptInvitationResultDto) _then) = _$AcceptInvitationResultDtoCopyWithImpl;
@useResult
$Res call({
 String projectSlug, AcceptInvitationResultDtoRole role, bool alreadyMember
});




}
/// @nodoc
class _$AcceptInvitationResultDtoCopyWithImpl<$Res>
    implements $AcceptInvitationResultDtoCopyWith<$Res> {
  _$AcceptInvitationResultDtoCopyWithImpl(this._self, this._then);

  final AcceptInvitationResultDto _self;
  final $Res Function(AcceptInvitationResultDto) _then;

/// Create a copy of AcceptInvitationResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? projectSlug = null,Object? role = null,Object? alreadyMember = null,}) {
  return _then(AcceptInvitationResultDto(
projectSlug: null == projectSlug ? _self.projectSlug : projectSlug // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as AcceptInvitationResultDtoRole,alreadyMember: null == alreadyMember ? _self.alreadyMember : alreadyMember // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AcceptInvitationResultDto].
extension AcceptInvitationResultDtoPatterns on AcceptInvitationResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AcceptInvitationResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AcceptInvitationResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AcceptInvitationResultDto value)  $default,){
final _that = this;
switch (_that) {
case _AcceptInvitationResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AcceptInvitationResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _AcceptInvitationResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String projectSlug,  AcceptInvitationResultDtoRole role,  bool alreadyMember)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AcceptInvitationResultDto() when $default != null:
return $default(_that.projectSlug,_that.role,_that.alreadyMember);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String projectSlug,  AcceptInvitationResultDtoRole role,  bool alreadyMember)  $default,) {final _that = this;
switch (_that) {
case _AcceptInvitationResultDto():
return $default(_that.projectSlug,_that.role,_that.alreadyMember);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String projectSlug,  AcceptInvitationResultDtoRole role,  bool alreadyMember)?  $default,) {final _that = this;
switch (_that) {
case _AcceptInvitationResultDto() when $default != null:
return $default(_that.projectSlug,_that.role,_that.alreadyMember);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AcceptInvitationResultDto implements AcceptInvitationResultDto {
  const _AcceptInvitationResultDto({required this.projectSlug, required this.role, required this.alreadyMember});
  factory _AcceptInvitationResultDto.fromJson(Map<String, dynamic> json) => _$AcceptInvitationResultDtoFromJson(json);

/// Куда переходить после вступления
@override final  String projectSlug;
/// Роль пользователя в проекте после приёма
@override final  AcceptInvitationResultDtoRole role;
/// Пользователь уже был участником; роль не изменилась
@override final  bool alreadyMember;

/// Create a copy of AcceptInvitationResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AcceptInvitationResultDtoCopyWith<_AcceptInvitationResultDto> get copyWith => __$AcceptInvitationResultDtoCopyWithImpl<_AcceptInvitationResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AcceptInvitationResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AcceptInvitationResultDto&&(identical(other.projectSlug, projectSlug) || other.projectSlug == projectSlug)&&(identical(other.role, role) || other.role == role)&&(identical(other.alreadyMember, alreadyMember) || other.alreadyMember == alreadyMember));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,projectSlug,role,alreadyMember);
}

@override
String toString() {
    return 'AcceptInvitationResultDto(projectSlug: $projectSlug, role: $role, alreadyMember: $alreadyMember)';
}


}

/// @nodoc
abstract mixin class _$AcceptInvitationResultDtoCopyWith<$Res> implements $AcceptInvitationResultDtoCopyWith<$Res> {
  factory _$AcceptInvitationResultDtoCopyWith(_AcceptInvitationResultDto value, $Res Function(_AcceptInvitationResultDto) _then) = __$AcceptInvitationResultDtoCopyWithImpl;
@override @useResult
$Res call({
 String projectSlug, AcceptInvitationResultDtoRole role, bool alreadyMember
});




}
/// @nodoc
class __$AcceptInvitationResultDtoCopyWithImpl<$Res>
    implements _$AcceptInvitationResultDtoCopyWith<$Res> {
  __$AcceptInvitationResultDtoCopyWithImpl(this._self, this._then);

  final _AcceptInvitationResultDto _self;
  final $Res Function(_AcceptInvitationResultDto) _then;

/// Create a copy of AcceptInvitationResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? projectSlug = null,Object? role = null,Object? alreadyMember = null,}) {
  return _then(_AcceptInvitationResultDto(
projectSlug: null == projectSlug ? _self.projectSlug : projectSlug // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as AcceptInvitationResultDtoRole,alreadyMember: null == alreadyMember ? _self.alreadyMember : alreadyMember // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
