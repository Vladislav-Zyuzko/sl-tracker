// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_member_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectMemberDto {

/// Идентификатор пользователя
 String get userId; String get displayName; String get email; String? get avatarUrl; ProjectMemberDtoRole get role;/// Когда вступил в проект
 DateTime get joinedAt;/// Это текущий пользователь: в списке помечается «(вы)»
 bool get isSelf;
/// Create a copy of ProjectMemberDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectMemberDtoCopyWith<ProjectMemberDto> get copyWith => _$ProjectMemberDtoCopyWithImpl<ProjectMemberDto>(this as ProjectMemberDto, _$identity);

  /// Serializes this ProjectMemberDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProjectMemberDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectMemberDto&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.joinedAt, _this.joinedAt) || other.joinedAt == _this.joinedAt)&&(identical(other.isSelf, _this.isSelf) || other.isSelf == _this.isSelf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProjectMemberDto;
  return Object.hash(runtimeType,_this.userId,_this.displayName,_this.email,_this.avatarUrl,_this.role,_this.joinedAt,_this.isSelf);
}

@override
String toString() {
  final _this = this as ProjectMemberDto;
  return 'ProjectMemberDto(userId: ${_this.userId}, displayName: ${_this.displayName}, email: ${_this.email}, avatarUrl: ${_this.avatarUrl}, role: ${_this.role}, joinedAt: ${_this.joinedAt}, isSelf: ${_this.isSelf})';
}


}

/// @nodoc
abstract mixin class $ProjectMemberDtoCopyWith<$Res>  {
  factory $ProjectMemberDtoCopyWith(ProjectMemberDto value, $Res Function(ProjectMemberDto) _then) = _$ProjectMemberDtoCopyWithImpl;
@useResult
$Res call({
 String userId, String displayName, String email, String? avatarUrl, ProjectMemberDtoRole role, DateTime joinedAt, bool isSelf
});




}
/// @nodoc
class _$ProjectMemberDtoCopyWithImpl<$Res>
    implements $ProjectMemberDtoCopyWith<$Res> {
  _$ProjectMemberDtoCopyWithImpl(this._self, this._then);

  final ProjectMemberDto _self;
  final $Res Function(ProjectMemberDto) _then;

/// Create a copy of ProjectMemberDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? displayName = null,Object? email = null,Object? avatarUrl = freezed,Object? role = null,Object? joinedAt = null,Object? isSelf = null,}) {
  return _then(ProjectMemberDto(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ProjectMemberDtoRole,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isSelf: null == isSelf ? _self.isSelf : isSelf // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectMemberDto].
extension ProjectMemberDtoPatterns on ProjectMemberDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectMemberDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectMemberDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectMemberDto value)  $default,){
final _that = this;
switch (_that) {
case _ProjectMemberDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectMemberDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectMemberDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String displayName,  String email,  String? avatarUrl,  ProjectMemberDtoRole role,  DateTime joinedAt,  bool isSelf)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectMemberDto() when $default != null:
return $default(_that.userId,_that.displayName,_that.email,_that.avatarUrl,_that.role,_that.joinedAt,_that.isSelf);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String displayName,  String email,  String? avatarUrl,  ProjectMemberDtoRole role,  DateTime joinedAt,  bool isSelf)  $default,) {final _that = this;
switch (_that) {
case _ProjectMemberDto():
return $default(_that.userId,_that.displayName,_that.email,_that.avatarUrl,_that.role,_that.joinedAt,_that.isSelf);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String displayName,  String email,  String? avatarUrl,  ProjectMemberDtoRole role,  DateTime joinedAt,  bool isSelf)?  $default,) {final _that = this;
switch (_that) {
case _ProjectMemberDto() when $default != null:
return $default(_that.userId,_that.displayName,_that.email,_that.avatarUrl,_that.role,_that.joinedAt,_that.isSelf);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectMemberDto implements ProjectMemberDto {
  const _ProjectMemberDto({required this.userId, required this.displayName, required this.email, required this.avatarUrl, required this.role, required this.joinedAt, required this.isSelf});
  factory _ProjectMemberDto.fromJson(Map<String, dynamic> json) => _$ProjectMemberDtoFromJson(json);

/// Идентификатор пользователя
@override final  String userId;
@override final  String displayName;
@override final  String email;
@override final  String? avatarUrl;
@override final  ProjectMemberDtoRole role;
/// Когда вступил в проект
@override final  DateTime joinedAt;
/// Это текущий пользователь: в списке помечается «(вы)»
@override final  bool isSelf;

/// Create a copy of ProjectMemberDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectMemberDtoCopyWith<_ProjectMemberDto> get copyWith => __$ProjectMemberDtoCopyWithImpl<_ProjectMemberDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectMemberDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectMemberDto&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.role, role) || other.role == role)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.isSelf, isSelf) || other.isSelf == isSelf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,userId,displayName,email,avatarUrl,role,joinedAt,isSelf);
}

@override
String toString() {
    return 'ProjectMemberDto(userId: $userId, displayName: $displayName, email: $email, avatarUrl: $avatarUrl, role: $role, joinedAt: $joinedAt, isSelf: $isSelf)';
}


}

/// @nodoc
abstract mixin class _$ProjectMemberDtoCopyWith<$Res> implements $ProjectMemberDtoCopyWith<$Res> {
  factory _$ProjectMemberDtoCopyWith(_ProjectMemberDto value, $Res Function(_ProjectMemberDto) _then) = __$ProjectMemberDtoCopyWithImpl;
@override @useResult
$Res call({
 String userId, String displayName, String email, String? avatarUrl, ProjectMemberDtoRole role, DateTime joinedAt, bool isSelf
});




}
/// @nodoc
class __$ProjectMemberDtoCopyWithImpl<$Res>
    implements _$ProjectMemberDtoCopyWith<$Res> {
  __$ProjectMemberDtoCopyWithImpl(this._self, this._then);

  final _ProjectMemberDto _self;
  final $Res Function(_ProjectMemberDto) _then;

/// Create a copy of ProjectMemberDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? displayName = null,Object? email = null,Object? avatarUrl = freezed,Object? role = null,Object? joinedAt = null,Object? isSelf = null,}) {
  return _then(_ProjectMemberDto(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ProjectMemberDtoRole,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isSelf: null == isSelf ? _self.isSelf : isSelf // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
