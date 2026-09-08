// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment_permissions_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CommentPermissionsDto {

/// Править может **только автор**, независимо от роли: администратор чужой комментарий не редактирует (US-72).
 bool get canEdit;/// Свой комментарий удаляет автор, чужой — только администратор проекта (US-73).
 bool get canDelete;
/// Create a copy of CommentPermissionsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentPermissionsDtoCopyWith<CommentPermissionsDto> get copyWith => _$CommentPermissionsDtoCopyWithImpl<CommentPermissionsDto>(this as CommentPermissionsDto, _$identity);

  /// Serializes this CommentPermissionsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CommentPermissionsDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentPermissionsDto&&(identical(other.canEdit, _this.canEdit) || other.canEdit == _this.canEdit)&&(identical(other.canDelete, _this.canDelete) || other.canDelete == _this.canDelete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CommentPermissionsDto;
  return Object.hash(runtimeType,_this.canEdit,_this.canDelete);
}

@override
String toString() {
  final _this = this as CommentPermissionsDto;
  return 'CommentPermissionsDto(canEdit: ${_this.canEdit}, canDelete: ${_this.canDelete})';
}


}

/// @nodoc
abstract mixin class $CommentPermissionsDtoCopyWith<$Res>  {
  factory $CommentPermissionsDtoCopyWith(CommentPermissionsDto value, $Res Function(CommentPermissionsDto) _then) = _$CommentPermissionsDtoCopyWithImpl;
@useResult
$Res call({
 bool canEdit, bool canDelete
});




}
/// @nodoc
class _$CommentPermissionsDtoCopyWithImpl<$Res>
    implements $CommentPermissionsDtoCopyWith<$Res> {
  _$CommentPermissionsDtoCopyWithImpl(this._self, this._then);

  final CommentPermissionsDto _self;
  final $Res Function(CommentPermissionsDto) _then;

/// Create a copy of CommentPermissionsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? canEdit = null,Object? canDelete = null,}) {
  return _then(CommentPermissionsDto(
canEdit: null == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool,canDelete: null == canDelete ? _self.canDelete : canDelete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentPermissionsDto].
extension CommentPermissionsDtoPatterns on CommentPermissionsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentPermissionsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentPermissionsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentPermissionsDto value)  $default,){
final _that = this;
switch (_that) {
case _CommentPermissionsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentPermissionsDto value)?  $default,){
final _that = this;
switch (_that) {
case _CommentPermissionsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool canEdit,  bool canDelete)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentPermissionsDto() when $default != null:
return $default(_that.canEdit,_that.canDelete);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool canEdit,  bool canDelete)  $default,) {final _that = this;
switch (_that) {
case _CommentPermissionsDto():
return $default(_that.canEdit,_that.canDelete);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool canEdit,  bool canDelete)?  $default,) {final _that = this;
switch (_that) {
case _CommentPermissionsDto() when $default != null:
return $default(_that.canEdit,_that.canDelete);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentPermissionsDto implements CommentPermissionsDto {
  const _CommentPermissionsDto({required this.canEdit, required this.canDelete});
  factory _CommentPermissionsDto.fromJson(Map<String, dynamic> json) => _$CommentPermissionsDtoFromJson(json);

/// Править может **только автор**, независимо от роли: администратор чужой комментарий не редактирует (US-72).
@override final  bool canEdit;
/// Свой комментарий удаляет автор, чужой — только администратор проекта (US-73).
@override final  bool canDelete;

/// Create a copy of CommentPermissionsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentPermissionsDtoCopyWith<_CommentPermissionsDto> get copyWith => __$CommentPermissionsDtoCopyWithImpl<_CommentPermissionsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentPermissionsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentPermissionsDto&&(identical(other.canEdit, canEdit) || other.canEdit == canEdit)&&(identical(other.canDelete, canDelete) || other.canDelete == canDelete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,canEdit,canDelete);
}

@override
String toString() {
    return 'CommentPermissionsDto(canEdit: $canEdit, canDelete: $canDelete)';
}


}

/// @nodoc
abstract mixin class _$CommentPermissionsDtoCopyWith<$Res> implements $CommentPermissionsDtoCopyWith<$Res> {
  factory _$CommentPermissionsDtoCopyWith(_CommentPermissionsDto value, $Res Function(_CommentPermissionsDto) _then) = __$CommentPermissionsDtoCopyWithImpl;
@override @useResult
$Res call({
 bool canEdit, bool canDelete
});




}
/// @nodoc
class __$CommentPermissionsDtoCopyWithImpl<$Res>
    implements _$CommentPermissionsDtoCopyWith<$Res> {
  __$CommentPermissionsDtoCopyWithImpl(this._self, this._then);

  final _CommentPermissionsDto _self;
  final $Res Function(_CommentPermissionsDto) _then;

/// Create a copy of CommentPermissionsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? canEdit = null,Object? canDelete = null,}) {
  return _then(_CommentPermissionsDto(
canEdit: null == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool,canDelete: null == canDelete ? _self.canDelete : canDelete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
