// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invitation_preview_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvitationPreviewDto {

 String get projectName; String get projectSlug;/// Подписанная ссылка на обложку
 String? get coverUrl;/// Роль, которую человек получит. Если он уже участник — его текущая роль: приглашение её не меняет и не понижает (US-21).
 InvitationPreviewDtoRole get role;/// Пользователь уже состоит в проекте: экран подтверждения не показывается, клиент сразу открывает проект (US-21).
 bool get alreadyMember;
/// Create a copy of InvitationPreviewDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvitationPreviewDtoCopyWith<InvitationPreviewDto> get copyWith => _$InvitationPreviewDtoCopyWithImpl<InvitationPreviewDto>(this as InvitationPreviewDto, _$identity);

  /// Serializes this InvitationPreviewDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InvitationPreviewDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvitationPreviewDto&&(identical(other.projectName, _this.projectName) || other.projectName == _this.projectName)&&(identical(other.projectSlug, _this.projectSlug) || other.projectSlug == _this.projectSlug)&&(identical(other.coverUrl, _this.coverUrl) || other.coverUrl == _this.coverUrl)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.alreadyMember, _this.alreadyMember) || other.alreadyMember == _this.alreadyMember));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InvitationPreviewDto;
  return Object.hash(runtimeType,_this.projectName,_this.projectSlug,_this.coverUrl,_this.role,_this.alreadyMember);
}

@override
String toString() {
  final _this = this as InvitationPreviewDto;
  return 'InvitationPreviewDto(projectName: ${_this.projectName}, projectSlug: ${_this.projectSlug}, coverUrl: ${_this.coverUrl}, role: ${_this.role}, alreadyMember: ${_this.alreadyMember})';
}


}

/// @nodoc
abstract mixin class $InvitationPreviewDtoCopyWith<$Res>  {
  factory $InvitationPreviewDtoCopyWith(InvitationPreviewDto value, $Res Function(InvitationPreviewDto) _then) = _$InvitationPreviewDtoCopyWithImpl;
@useResult
$Res call({
 String projectName, String projectSlug, String? coverUrl, InvitationPreviewDtoRole role, bool alreadyMember
});




}
/// @nodoc
class _$InvitationPreviewDtoCopyWithImpl<$Res>
    implements $InvitationPreviewDtoCopyWith<$Res> {
  _$InvitationPreviewDtoCopyWithImpl(this._self, this._then);

  final InvitationPreviewDto _self;
  final $Res Function(InvitationPreviewDto) _then;

/// Create a copy of InvitationPreviewDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? projectName = null,Object? projectSlug = null,Object? coverUrl = freezed,Object? role = null,Object? alreadyMember = null,}) {
  return _then(InvitationPreviewDto(
projectName: null == projectName ? _self.projectName : projectName // ignore: cast_nullable_to_non_nullable
as String,projectSlug: null == projectSlug ? _self.projectSlug : projectSlug // ignore: cast_nullable_to_non_nullable
as String,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as InvitationPreviewDtoRole,alreadyMember: null == alreadyMember ? _self.alreadyMember : alreadyMember // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [InvitationPreviewDto].
extension InvitationPreviewDtoPatterns on InvitationPreviewDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvitationPreviewDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvitationPreviewDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvitationPreviewDto value)  $default,){
final _that = this;
switch (_that) {
case _InvitationPreviewDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvitationPreviewDto value)?  $default,){
final _that = this;
switch (_that) {
case _InvitationPreviewDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String projectName,  String projectSlug,  String? coverUrl,  InvitationPreviewDtoRole role,  bool alreadyMember)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvitationPreviewDto() when $default != null:
return $default(_that.projectName,_that.projectSlug,_that.coverUrl,_that.role,_that.alreadyMember);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String projectName,  String projectSlug,  String? coverUrl,  InvitationPreviewDtoRole role,  bool alreadyMember)  $default,) {final _that = this;
switch (_that) {
case _InvitationPreviewDto():
return $default(_that.projectName,_that.projectSlug,_that.coverUrl,_that.role,_that.alreadyMember);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String projectName,  String projectSlug,  String? coverUrl,  InvitationPreviewDtoRole role,  bool alreadyMember)?  $default,) {final _that = this;
switch (_that) {
case _InvitationPreviewDto() when $default != null:
return $default(_that.projectName,_that.projectSlug,_that.coverUrl,_that.role,_that.alreadyMember);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvitationPreviewDto implements InvitationPreviewDto {
  const _InvitationPreviewDto({required this.projectName, required this.projectSlug, required this.coverUrl, required this.role, required this.alreadyMember});
  factory _InvitationPreviewDto.fromJson(Map<String, dynamic> json) => _$InvitationPreviewDtoFromJson(json);

@override final  String projectName;
@override final  String projectSlug;
/// Подписанная ссылка на обложку
@override final  String? coverUrl;
/// Роль, которую человек получит. Если он уже участник — его текущая роль: приглашение её не меняет и не понижает (US-21).
@override final  InvitationPreviewDtoRole role;
/// Пользователь уже состоит в проекте: экран подтверждения не показывается, клиент сразу открывает проект (US-21).
@override final  bool alreadyMember;

/// Create a copy of InvitationPreviewDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvitationPreviewDtoCopyWith<_InvitationPreviewDto> get copyWith => __$InvitationPreviewDtoCopyWithImpl<_InvitationPreviewDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvitationPreviewDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvitationPreviewDto&&(identical(other.projectName, projectName) || other.projectName == projectName)&&(identical(other.projectSlug, projectSlug) || other.projectSlug == projectSlug)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.role, role) || other.role == role)&&(identical(other.alreadyMember, alreadyMember) || other.alreadyMember == alreadyMember));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,projectName,projectSlug,coverUrl,role,alreadyMember);
}

@override
String toString() {
    return 'InvitationPreviewDto(projectName: $projectName, projectSlug: $projectSlug, coverUrl: $coverUrl, role: $role, alreadyMember: $alreadyMember)';
}


}

/// @nodoc
abstract mixin class _$InvitationPreviewDtoCopyWith<$Res> implements $InvitationPreviewDtoCopyWith<$Res> {
  factory _$InvitationPreviewDtoCopyWith(_InvitationPreviewDto value, $Res Function(_InvitationPreviewDto) _then) = __$InvitationPreviewDtoCopyWithImpl;
@override @useResult
$Res call({
 String projectName, String projectSlug, String? coverUrl, InvitationPreviewDtoRole role, bool alreadyMember
});




}
/// @nodoc
class __$InvitationPreviewDtoCopyWithImpl<$Res>
    implements _$InvitationPreviewDtoCopyWith<$Res> {
  __$InvitationPreviewDtoCopyWithImpl(this._self, this._then);

  final _InvitationPreviewDto _self;
  final $Res Function(_InvitationPreviewDto) _then;

/// Create a copy of InvitationPreviewDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? projectName = null,Object? projectSlug = null,Object? coverUrl = freezed,Object? role = null,Object? alreadyMember = null,}) {
  return _then(_InvitationPreviewDto(
projectName: null == projectName ? _self.projectName : projectName // ignore: cast_nullable_to_non_nullable
as String,projectSlug: null == projectSlug ? _self.projectSlug : projectSlug // ignore: cast_nullable_to_non_nullable
as String,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as InvitationPreviewDtoRole,alreadyMember: null == alreadyMember ? _self.alreadyMember : alreadyMember // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
