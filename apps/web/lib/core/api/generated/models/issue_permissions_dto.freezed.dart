// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issue_permissions_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IssuePermissionsDto {

/// Менять поля, название, описание и ссылки. Участник может менять **любую** задачу проекта, а не только свою (D-11). У читателя — `false`.
 bool get canEdit;/// Удалить задачу. Только у администратора проекта (D-12).
 bool get canDelete;
/// Create a copy of IssuePermissionsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssuePermissionsDtoCopyWith<IssuePermissionsDto> get copyWith => _$IssuePermissionsDtoCopyWithImpl<IssuePermissionsDto>(this as IssuePermissionsDto, _$identity);

  /// Serializes this IssuePermissionsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IssuePermissionsDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssuePermissionsDto&&(identical(other.canEdit, _this.canEdit) || other.canEdit == _this.canEdit)&&(identical(other.canDelete, _this.canDelete) || other.canDelete == _this.canDelete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IssuePermissionsDto;
  return Object.hash(runtimeType,_this.canEdit,_this.canDelete);
}

@override
String toString() {
  final _this = this as IssuePermissionsDto;
  return 'IssuePermissionsDto(canEdit: ${_this.canEdit}, canDelete: ${_this.canDelete})';
}


}

/// @nodoc
abstract mixin class $IssuePermissionsDtoCopyWith<$Res>  {
  factory $IssuePermissionsDtoCopyWith(IssuePermissionsDto value, $Res Function(IssuePermissionsDto) _then) = _$IssuePermissionsDtoCopyWithImpl;
@useResult
$Res call({
 bool canEdit, bool canDelete
});




}
/// @nodoc
class _$IssuePermissionsDtoCopyWithImpl<$Res>
    implements $IssuePermissionsDtoCopyWith<$Res> {
  _$IssuePermissionsDtoCopyWithImpl(this._self, this._then);

  final IssuePermissionsDto _self;
  final $Res Function(IssuePermissionsDto) _then;

/// Create a copy of IssuePermissionsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? canEdit = null,Object? canDelete = null,}) {
  return _then(IssuePermissionsDto(
canEdit: null == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool,canDelete: null == canDelete ? _self.canDelete : canDelete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [IssuePermissionsDto].
extension IssuePermissionsDtoPatterns on IssuePermissionsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssuePermissionsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssuePermissionsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssuePermissionsDto value)  $default,){
final _that = this;
switch (_that) {
case _IssuePermissionsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssuePermissionsDto value)?  $default,){
final _that = this;
switch (_that) {
case _IssuePermissionsDto() when $default != null:
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
case _IssuePermissionsDto() when $default != null:
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
case _IssuePermissionsDto():
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
case _IssuePermissionsDto() when $default != null:
return $default(_that.canEdit,_that.canDelete);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssuePermissionsDto implements IssuePermissionsDto {
  const _IssuePermissionsDto({required this.canEdit, required this.canDelete});
  factory _IssuePermissionsDto.fromJson(Map<String, dynamic> json) => _$IssuePermissionsDtoFromJson(json);

/// Менять поля, название, описание и ссылки. Участник может менять **любую** задачу проекта, а не только свою (D-11). У читателя — `false`.
@override final  bool canEdit;
/// Удалить задачу. Только у администратора проекта (D-12).
@override final  bool canDelete;

/// Create a copy of IssuePermissionsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssuePermissionsDtoCopyWith<_IssuePermissionsDto> get copyWith => __$IssuePermissionsDtoCopyWithImpl<_IssuePermissionsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssuePermissionsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssuePermissionsDto&&(identical(other.canEdit, canEdit) || other.canEdit == canEdit)&&(identical(other.canDelete, canDelete) || other.canDelete == canDelete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,canEdit,canDelete);
}

@override
String toString() {
    return 'IssuePermissionsDto(canEdit: $canEdit, canDelete: $canDelete)';
}


}

/// @nodoc
abstract mixin class _$IssuePermissionsDtoCopyWith<$Res> implements $IssuePermissionsDtoCopyWith<$Res> {
  factory _$IssuePermissionsDtoCopyWith(_IssuePermissionsDto value, $Res Function(_IssuePermissionsDto) _then) = __$IssuePermissionsDtoCopyWithImpl;
@override @useResult
$Res call({
 bool canEdit, bool canDelete
});




}
/// @nodoc
class __$IssuePermissionsDtoCopyWithImpl<$Res>
    implements _$IssuePermissionsDtoCopyWith<$Res> {
  __$IssuePermissionsDtoCopyWithImpl(this._self, this._then);

  final _IssuePermissionsDto _self;
  final $Res Function(_IssuePermissionsDto) _then;

/// Create a copy of IssuePermissionsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? canEdit = null,Object? canDelete = null,}) {
  return _then(_IssuePermissionsDto(
canEdit: null == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool,canDelete: null == canDelete ? _self.canDelete : canDelete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
