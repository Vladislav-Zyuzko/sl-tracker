// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issue_queue_ref_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IssueQueueRefDto {

 String get key; String get name;
/// Create a copy of IssueQueueRefDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueQueueRefDtoCopyWith<IssueQueueRefDto> get copyWith => _$IssueQueueRefDtoCopyWithImpl<IssueQueueRefDto>(this as IssueQueueRefDto, _$identity);

  /// Serializes this IssueQueueRefDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IssueQueueRefDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssueQueueRefDto&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.name, _this.name) || other.name == _this.name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IssueQueueRefDto;
  return Object.hash(runtimeType,_this.key,_this.name);
}

@override
String toString() {
  final _this = this as IssueQueueRefDto;
  return 'IssueQueueRefDto(key: ${_this.key}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $IssueQueueRefDtoCopyWith<$Res>  {
  factory $IssueQueueRefDtoCopyWith(IssueQueueRefDto value, $Res Function(IssueQueueRefDto) _then) = _$IssueQueueRefDtoCopyWithImpl;
@useResult
$Res call({
 String key, String name
});




}
/// @nodoc
class _$IssueQueueRefDtoCopyWithImpl<$Res>
    implements $IssueQueueRefDtoCopyWith<$Res> {
  _$IssueQueueRefDtoCopyWithImpl(this._self, this._then);

  final IssueQueueRefDto _self;
  final $Res Function(IssueQueueRefDto) _then;

/// Create a copy of IssueQueueRefDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? name = null,}) {
  return _then(IssueQueueRefDto(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [IssueQueueRefDto].
extension IssueQueueRefDtoPatterns on IssueQueueRefDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssueQueueRefDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssueQueueRefDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssueQueueRefDto value)  $default,){
final _that = this;
switch (_that) {
case _IssueQueueRefDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssueQueueRefDto value)?  $default,){
final _that = this;
switch (_that) {
case _IssueQueueRefDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssueQueueRefDto() when $default != null:
return $default(_that.key,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String name)  $default,) {final _that = this;
switch (_that) {
case _IssueQueueRefDto():
return $default(_that.key,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String name)?  $default,) {final _that = this;
switch (_that) {
case _IssueQueueRefDto() when $default != null:
return $default(_that.key,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssueQueueRefDto implements IssueQueueRefDto {
  const _IssueQueueRefDto({required this.key, required this.name});
  factory _IssueQueueRefDto.fromJson(Map<String, dynamic> json) => _$IssueQueueRefDtoFromJson(json);

@override final  String key;
@override final  String name;

/// Create a copy of IssueQueueRefDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueQueueRefDtoCopyWith<_IssueQueueRefDto> get copyWith => __$IssueQueueRefDtoCopyWithImpl<_IssueQueueRefDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueQueueRefDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssueQueueRefDto&&(identical(other.key, key) || other.key == key)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,key,name);
}

@override
String toString() {
    return 'IssueQueueRefDto(key: $key, name: $name)';
}


}

/// @nodoc
abstract mixin class _$IssueQueueRefDtoCopyWith<$Res> implements $IssueQueueRefDtoCopyWith<$Res> {
  factory _$IssueQueueRefDtoCopyWith(_IssueQueueRefDto value, $Res Function(_IssueQueueRefDto) _then) = __$IssueQueueRefDtoCopyWithImpl;
@override @useResult
$Res call({
 String key, String name
});




}
/// @nodoc
class __$IssueQueueRefDtoCopyWithImpl<$Res>
    implements _$IssueQueueRefDtoCopyWith<$Res> {
  __$IssueQueueRefDtoCopyWithImpl(this._self, this._then);

  final _IssueQueueRefDto _self;
  final $Res Function(_IssueQueueRefDto) _then;

/// Create a copy of IssueQueueRefDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? name = null,}) {
  return _then(_IssueQueueRefDto(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
