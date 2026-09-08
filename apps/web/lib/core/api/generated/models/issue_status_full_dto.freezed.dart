// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issue_status_full_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IssueStatusFullDto {

 String get id; String get key; String get name; IssueStatusFullDtoCategory get category; num get position;
/// Create a copy of IssueStatusFullDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueStatusFullDtoCopyWith<IssueStatusFullDto> get copyWith => _$IssueStatusFullDtoCopyWithImpl<IssueStatusFullDto>(this as IssueStatusFullDto, _$identity);

  /// Serializes this IssueStatusFullDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IssueStatusFullDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssueStatusFullDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.position, _this.position) || other.position == _this.position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IssueStatusFullDto;
  return Object.hash(runtimeType,_this.id,_this.key,_this.name,_this.category,_this.position);
}

@override
String toString() {
  final _this = this as IssueStatusFullDto;
  return 'IssueStatusFullDto(id: ${_this.id}, key: ${_this.key}, name: ${_this.name}, category: ${_this.category}, position: ${_this.position})';
}


}

/// @nodoc
abstract mixin class $IssueStatusFullDtoCopyWith<$Res>  {
  factory $IssueStatusFullDtoCopyWith(IssueStatusFullDto value, $Res Function(IssueStatusFullDto) _then) = _$IssueStatusFullDtoCopyWithImpl;
@useResult
$Res call({
 String id, String key, String name, IssueStatusFullDtoCategory category, num position
});




}
/// @nodoc
class _$IssueStatusFullDtoCopyWithImpl<$Res>
    implements $IssueStatusFullDtoCopyWith<$Res> {
  _$IssueStatusFullDtoCopyWithImpl(this._self, this._then);

  final IssueStatusFullDto _self;
  final $Res Function(IssueStatusFullDto) _then;

/// Create a copy of IssueStatusFullDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? key = null,Object? name = null,Object? category = null,Object? position = null,}) {
  return _then(IssueStatusFullDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as IssueStatusFullDtoCategory,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [IssueStatusFullDto].
extension IssueStatusFullDtoPatterns on IssueStatusFullDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssueStatusFullDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssueStatusFullDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssueStatusFullDto value)  $default,){
final _that = this;
switch (_that) {
case _IssueStatusFullDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssueStatusFullDto value)?  $default,){
final _that = this;
switch (_that) {
case _IssueStatusFullDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String key,  String name,  IssueStatusFullDtoCategory category,  num position)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssueStatusFullDto() when $default != null:
return $default(_that.id,_that.key,_that.name,_that.category,_that.position);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String key,  String name,  IssueStatusFullDtoCategory category,  num position)  $default,) {final _that = this;
switch (_that) {
case _IssueStatusFullDto():
return $default(_that.id,_that.key,_that.name,_that.category,_that.position);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String key,  String name,  IssueStatusFullDtoCategory category,  num position)?  $default,) {final _that = this;
switch (_that) {
case _IssueStatusFullDto() when $default != null:
return $default(_that.id,_that.key,_that.name,_that.category,_that.position);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssueStatusFullDto implements IssueStatusFullDto {
  const _IssueStatusFullDto({required this.id, required this.key, required this.name, required this.category, required this.position});
  factory _IssueStatusFullDto.fromJson(Map<String, dynamic> json) => _$IssueStatusFullDtoFromJson(json);

@override final  String id;
@override final  String key;
@override final  String name;
@override final  IssueStatusFullDtoCategory category;
@override final  num position;

/// Create a copy of IssueStatusFullDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueStatusFullDtoCopyWith<_IssueStatusFullDto> get copyWith => __$IssueStatusFullDtoCopyWithImpl<_IssueStatusFullDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueStatusFullDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssueStatusFullDto&&(identical(other.id, id) || other.id == id)&&(identical(other.key, key) || other.key == key)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.position, position) || other.position == position));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,key,name,category,position);
}

@override
String toString() {
    return 'IssueStatusFullDto(id: $id, key: $key, name: $name, category: $category, position: $position)';
}


}

/// @nodoc
abstract mixin class _$IssueStatusFullDtoCopyWith<$Res> implements $IssueStatusFullDtoCopyWith<$Res> {
  factory _$IssueStatusFullDtoCopyWith(_IssueStatusFullDto value, $Res Function(_IssueStatusFullDto) _then) = __$IssueStatusFullDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String key, String name, IssueStatusFullDtoCategory category, num position
});




}
/// @nodoc
class __$IssueStatusFullDtoCopyWithImpl<$Res>
    implements _$IssueStatusFullDtoCopyWith<$Res> {
  __$IssueStatusFullDtoCopyWithImpl(this._self, this._then);

  final _IssueStatusFullDto _self;
  final $Res Function(_IssueStatusFullDto) _then;

/// Create a copy of IssueStatusFullDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? key = null,Object? name = null,Object? category = null,Object? position = null,}) {
  return _then(_IssueStatusFullDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as IssueStatusFullDtoCategory,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}

// dart format on
