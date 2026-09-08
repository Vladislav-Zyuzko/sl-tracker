// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_member_preview_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectMemberPreviewDto {

 String get id; String get displayName; String? get avatarUrl; ProjectMemberPreviewDtoRole get role;
/// Create a copy of ProjectMemberPreviewDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectMemberPreviewDtoCopyWith<ProjectMemberPreviewDto> get copyWith => _$ProjectMemberPreviewDtoCopyWithImpl<ProjectMemberPreviewDto>(this as ProjectMemberPreviewDto, _$identity);

  /// Serializes this ProjectMemberPreviewDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProjectMemberPreviewDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectMemberPreviewDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl)&&(identical(other.role, _this.role) || other.role == _this.role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProjectMemberPreviewDto;
  return Object.hash(runtimeType,_this.id,_this.displayName,_this.avatarUrl,_this.role);
}

@override
String toString() {
  final _this = this as ProjectMemberPreviewDto;
  return 'ProjectMemberPreviewDto(id: ${_this.id}, displayName: ${_this.displayName}, avatarUrl: ${_this.avatarUrl}, role: ${_this.role})';
}


}

/// @nodoc
abstract mixin class $ProjectMemberPreviewDtoCopyWith<$Res>  {
  factory $ProjectMemberPreviewDtoCopyWith(ProjectMemberPreviewDto value, $Res Function(ProjectMemberPreviewDto) _then) = _$ProjectMemberPreviewDtoCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String? avatarUrl, ProjectMemberPreviewDtoRole role
});




}
/// @nodoc
class _$ProjectMemberPreviewDtoCopyWithImpl<$Res>
    implements $ProjectMemberPreviewDtoCopyWith<$Res> {
  _$ProjectMemberPreviewDtoCopyWithImpl(this._self, this._then);

  final ProjectMemberPreviewDto _self;
  final $Res Function(ProjectMemberPreviewDto) _then;

/// Create a copy of ProjectMemberPreviewDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? avatarUrl = freezed,Object? role = null,}) {
  return _then(ProjectMemberPreviewDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ProjectMemberPreviewDtoRole,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectMemberPreviewDto].
extension ProjectMemberPreviewDtoPatterns on ProjectMemberPreviewDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectMemberPreviewDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectMemberPreviewDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectMemberPreviewDto value)  $default,){
final _that = this;
switch (_that) {
case _ProjectMemberPreviewDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectMemberPreviewDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectMemberPreviewDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String? avatarUrl,  ProjectMemberPreviewDtoRole role)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectMemberPreviewDto() when $default != null:
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.role);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String? avatarUrl,  ProjectMemberPreviewDtoRole role)  $default,) {final _that = this;
switch (_that) {
case _ProjectMemberPreviewDto():
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.role);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String? avatarUrl,  ProjectMemberPreviewDtoRole role)?  $default,) {final _that = this;
switch (_that) {
case _ProjectMemberPreviewDto() when $default != null:
return $default(_that.id,_that.displayName,_that.avatarUrl,_that.role);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectMemberPreviewDto implements ProjectMemberPreviewDto {
  const _ProjectMemberPreviewDto({required this.id, required this.displayName, required this.avatarUrl, required this.role});
  factory _ProjectMemberPreviewDto.fromJson(Map<String, dynamic> json) => _$ProjectMemberPreviewDtoFromJson(json);

@override final  String id;
@override final  String displayName;
@override final  String? avatarUrl;
@override final  ProjectMemberPreviewDtoRole role;

/// Create a copy of ProjectMemberPreviewDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectMemberPreviewDtoCopyWith<_ProjectMemberPreviewDto> get copyWith => __$ProjectMemberPreviewDtoCopyWithImpl<_ProjectMemberPreviewDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectMemberPreviewDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectMemberPreviewDto&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,displayName,avatarUrl,role);
}

@override
String toString() {
    return 'ProjectMemberPreviewDto(id: $id, displayName: $displayName, avatarUrl: $avatarUrl, role: $role)';
}


}

/// @nodoc
abstract mixin class _$ProjectMemberPreviewDtoCopyWith<$Res> implements $ProjectMemberPreviewDtoCopyWith<$Res> {
  factory _$ProjectMemberPreviewDtoCopyWith(_ProjectMemberPreviewDto value, $Res Function(_ProjectMemberPreviewDto) _then) = __$ProjectMemberPreviewDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String? avatarUrl, ProjectMemberPreviewDtoRole role
});




}
/// @nodoc
class __$ProjectMemberPreviewDtoCopyWithImpl<$Res>
    implements _$ProjectMemberPreviewDtoCopyWith<$Res> {
  __$ProjectMemberPreviewDtoCopyWithImpl(this._self, this._then);

  final _ProjectMemberPreviewDto _self;
  final $Res Function(_ProjectMemberPreviewDto) _then;

/// Create a copy of ProjectMemberPreviewDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? avatarUrl = freezed,Object? role = null,}) {
  return _then(_ProjectMemberPreviewDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ProjectMemberPreviewDtoRole,
  ));
}


}

// dart format on
