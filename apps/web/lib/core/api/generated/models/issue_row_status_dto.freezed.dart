// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issue_row_status_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IssueRowStatusDto {

 String get id; String get key; String get name; IssueRowStatusDtoCategory get category;
/// Create a copy of IssueRowStatusDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueRowStatusDtoCopyWith<IssueRowStatusDto> get copyWith => _$IssueRowStatusDtoCopyWithImpl<IssueRowStatusDto>(this as IssueRowStatusDto, _$identity);

  /// Serializes this IssueRowStatusDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IssueRowStatusDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssueRowStatusDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.category, _this.category) || other.category == _this.category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IssueRowStatusDto;
  return Object.hash(runtimeType,_this.id,_this.key,_this.name,_this.category);
}

@override
String toString() {
  final _this = this as IssueRowStatusDto;
  return 'IssueRowStatusDto(id: ${_this.id}, key: ${_this.key}, name: ${_this.name}, category: ${_this.category})';
}


}

/// @nodoc
abstract mixin class $IssueRowStatusDtoCopyWith<$Res>  {
  factory $IssueRowStatusDtoCopyWith(IssueRowStatusDto value, $Res Function(IssueRowStatusDto) _then) = _$IssueRowStatusDtoCopyWithImpl;
@useResult
$Res call({
 String id, String key, String name, IssueRowStatusDtoCategory category
});




}
/// @nodoc
class _$IssueRowStatusDtoCopyWithImpl<$Res>
    implements $IssueRowStatusDtoCopyWith<$Res> {
  _$IssueRowStatusDtoCopyWithImpl(this._self, this._then);

  final IssueRowStatusDto _self;
  final $Res Function(IssueRowStatusDto) _then;

/// Create a copy of IssueRowStatusDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? key = null,Object? name = null,Object? category = null,}) {
  return _then(IssueRowStatusDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as IssueRowStatusDtoCategory,
  ));
}

}


/// Adds pattern-matching-related methods to [IssueRowStatusDto].
extension IssueRowStatusDtoPatterns on IssueRowStatusDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssueRowStatusDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssueRowStatusDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssueRowStatusDto value)  $default,){
final _that = this;
switch (_that) {
case _IssueRowStatusDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssueRowStatusDto value)?  $default,){
final _that = this;
switch (_that) {
case _IssueRowStatusDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String key,  String name,  IssueRowStatusDtoCategory category)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssueRowStatusDto() when $default != null:
return $default(_that.id,_that.key,_that.name,_that.category);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String key,  String name,  IssueRowStatusDtoCategory category)  $default,) {final _that = this;
switch (_that) {
case _IssueRowStatusDto():
return $default(_that.id,_that.key,_that.name,_that.category);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String key,  String name,  IssueRowStatusDtoCategory category)?  $default,) {final _that = this;
switch (_that) {
case _IssueRowStatusDto() when $default != null:
return $default(_that.id,_that.key,_that.name,_that.category);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssueRowStatusDto implements IssueRowStatusDto {
  const _IssueRowStatusDto({required this.id, required this.key, required this.name, required this.category});
  factory _IssueRowStatusDto.fromJson(Map<String, dynamic> json) => _$IssueRowStatusDtoFromJson(json);

@override final  String id;
@override final  String key;
@override final  String name;
@override final  IssueRowStatusDtoCategory category;

/// Create a copy of IssueRowStatusDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueRowStatusDtoCopyWith<_IssueRowStatusDto> get copyWith => __$IssueRowStatusDtoCopyWithImpl<_IssueRowStatusDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueRowStatusDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssueRowStatusDto&&(identical(other.id, id) || other.id == id)&&(identical(other.key, key) || other.key == key)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,key,name,category);
}

@override
String toString() {
    return 'IssueRowStatusDto(id: $id, key: $key, name: $name, category: $category)';
}


}

/// @nodoc
abstract mixin class _$IssueRowStatusDtoCopyWith<$Res> implements $IssueRowStatusDtoCopyWith<$Res> {
  factory _$IssueRowStatusDtoCopyWith(_IssueRowStatusDto value, $Res Function(_IssueRowStatusDto) _then) = __$IssueRowStatusDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String key, String name, IssueRowStatusDtoCategory category
});




}
/// @nodoc
class __$IssueRowStatusDtoCopyWithImpl<$Res>
    implements _$IssueRowStatusDtoCopyWith<$Res> {
  __$IssueRowStatusDtoCopyWithImpl(this._self, this._then);

  final _IssueRowStatusDto _self;
  final $Res Function(_IssueRowStatusDto) _then;

/// Create a copy of IssueRowStatusDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? key = null,Object? name = null,Object? category = null,}) {
  return _then(_IssueRowStatusDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as IssueRowStatusDtoCategory,
  ));
}


}

// dart format on
