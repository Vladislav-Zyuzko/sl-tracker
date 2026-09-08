// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issue_status_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IssueStatusDto {

/// Машинное имя статуса в очереди
 String get key;/// Название для интерфейса
 String get name;/// Категория статуса. Активной считается задача, у которой категория не `done`; в этом списке `done` не встречается.
 IssueStatusDtoCategory get category;
/// Create a copy of IssueStatusDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueStatusDtoCopyWith<IssueStatusDto> get copyWith => _$IssueStatusDtoCopyWithImpl<IssueStatusDto>(this as IssueStatusDto, _$identity);

  /// Serializes this IssueStatusDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IssueStatusDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssueStatusDto&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.category, _this.category) || other.category == _this.category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IssueStatusDto;
  return Object.hash(runtimeType,_this.key,_this.name,_this.category);
}

@override
String toString() {
  final _this = this as IssueStatusDto;
  return 'IssueStatusDto(key: ${_this.key}, name: ${_this.name}, category: ${_this.category})';
}


}

/// @nodoc
abstract mixin class $IssueStatusDtoCopyWith<$Res>  {
  factory $IssueStatusDtoCopyWith(IssueStatusDto value, $Res Function(IssueStatusDto) _then) = _$IssueStatusDtoCopyWithImpl;
@useResult
$Res call({
 String key, String name, IssueStatusDtoCategory category
});




}
/// @nodoc
class _$IssueStatusDtoCopyWithImpl<$Res>
    implements $IssueStatusDtoCopyWith<$Res> {
  _$IssueStatusDtoCopyWithImpl(this._self, this._then);

  final IssueStatusDto _self;
  final $Res Function(IssueStatusDto) _then;

/// Create a copy of IssueStatusDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? name = null,Object? category = null,}) {
  return _then(IssueStatusDto(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as IssueStatusDtoCategory,
  ));
}

}


/// Adds pattern-matching-related methods to [IssueStatusDto].
extension IssueStatusDtoPatterns on IssueStatusDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssueStatusDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssueStatusDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssueStatusDto value)  $default,){
final _that = this;
switch (_that) {
case _IssueStatusDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssueStatusDto value)?  $default,){
final _that = this;
switch (_that) {
case _IssueStatusDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String name,  IssueStatusDtoCategory category)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssueStatusDto() when $default != null:
return $default(_that.key,_that.name,_that.category);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String name,  IssueStatusDtoCategory category)  $default,) {final _that = this;
switch (_that) {
case _IssueStatusDto():
return $default(_that.key,_that.name,_that.category);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String name,  IssueStatusDtoCategory category)?  $default,) {final _that = this;
switch (_that) {
case _IssueStatusDto() when $default != null:
return $default(_that.key,_that.name,_that.category);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssueStatusDto implements IssueStatusDto {
  const _IssueStatusDto({required this.key, required this.name, required this.category});
  factory _IssueStatusDto.fromJson(Map<String, dynamic> json) => _$IssueStatusDtoFromJson(json);

/// Машинное имя статуса в очереди
@override final  String key;
/// Название для интерфейса
@override final  String name;
/// Категория статуса. Активной считается задача, у которой категория не `done`; в этом списке `done` не встречается.
@override final  IssueStatusDtoCategory category;

/// Create a copy of IssueStatusDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueStatusDtoCopyWith<_IssueStatusDto> get copyWith => __$IssueStatusDtoCopyWithImpl<_IssueStatusDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueStatusDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssueStatusDto&&(identical(other.key, key) || other.key == key)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,key,name,category);
}

@override
String toString() {
    return 'IssueStatusDto(key: $key, name: $name, category: $category)';
}


}

/// @nodoc
abstract mixin class _$IssueStatusDtoCopyWith<$Res> implements $IssueStatusDtoCopyWith<$Res> {
  factory _$IssueStatusDtoCopyWith(_IssueStatusDto value, $Res Function(_IssueStatusDto) _then) = __$IssueStatusDtoCopyWithImpl;
@override @useResult
$Res call({
 String key, String name, IssueStatusDtoCategory category
});




}
/// @nodoc
class __$IssueStatusDtoCopyWithImpl<$Res>
    implements _$IssueStatusDtoCopyWith<$Res> {
  __$IssueStatusDtoCopyWithImpl(this._self, this._then);

  final _IssueStatusDto _self;
  final $Res Function(_IssueStatusDto) _then;

/// Create a copy of IssueStatusDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? name = null,Object? category = null,}) {
  return _then(_IssueStatusDto(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as IssueStatusDtoCategory,
  ));
}


}

// dart format on
