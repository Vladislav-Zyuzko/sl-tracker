// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_queue_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateQueueDto {

 String? get name;/// Markdown. `null` или пустая строка очищают описание.
 String? get description;
/// Create a copy of UpdateQueueDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateQueueDtoCopyWith<UpdateQueueDto> get copyWith => _$UpdateQueueDtoCopyWithImpl<UpdateQueueDto>(this as UpdateQueueDto, _$identity);

  /// Serializes this UpdateQueueDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UpdateQueueDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateQueueDto&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UpdateQueueDto;
  return Object.hash(runtimeType,_this.name,_this.description);
}

@override
String toString() {
  final _this = this as UpdateQueueDto;
  return 'UpdateQueueDto(name: ${_this.name}, description: ${_this.description})';
}


}

/// @nodoc
abstract mixin class $UpdateQueueDtoCopyWith<$Res>  {
  factory $UpdateQueueDtoCopyWith(UpdateQueueDto value, $Res Function(UpdateQueueDto) _then) = _$UpdateQueueDtoCopyWithImpl;
@useResult
$Res call({
 String? name, String? description
});




}
/// @nodoc
class _$UpdateQueueDtoCopyWithImpl<$Res>
    implements $UpdateQueueDtoCopyWith<$Res> {
  _$UpdateQueueDtoCopyWithImpl(this._self, this._then);

  final UpdateQueueDto _self;
  final $Res Function(UpdateQueueDto) _then;

/// Create a copy of UpdateQueueDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? description = freezed,}) {
  return _then(UpdateQueueDto(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateQueueDto].
extension UpdateQueueDtoPatterns on UpdateQueueDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateQueueDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateQueueDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateQueueDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdateQueueDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateQueueDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateQueueDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateQueueDto() when $default != null:
return $default(_that.name,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  String? description)  $default,) {final _that = this;
switch (_that) {
case _UpdateQueueDto():
return $default(_that.name,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _UpdateQueueDto() when $default != null:
return $default(_that.name,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateQueueDto implements UpdateQueueDto {
  const _UpdateQueueDto({this.name, this.description});
  factory _UpdateQueueDto.fromJson(Map<String, dynamic> json) => _$UpdateQueueDtoFromJson(json);

@override final  String? name;
/// Markdown. `null` или пустая строка очищают описание.
@override final  String? description;

/// Create a copy of UpdateQueueDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateQueueDtoCopyWith<_UpdateQueueDto> get copyWith => __$UpdateQueueDtoCopyWithImpl<_UpdateQueueDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateQueueDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateQueueDto&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,description);
}

@override
String toString() {
    return 'UpdateQueueDto(name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class _$UpdateQueueDtoCopyWith<$Res> implements $UpdateQueueDtoCopyWith<$Res> {
  factory _$UpdateQueueDtoCopyWith(_UpdateQueueDto value, $Res Function(_UpdateQueueDto) _then) = __$UpdateQueueDtoCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? description
});




}
/// @nodoc
class __$UpdateQueueDtoCopyWithImpl<$Res>
    implements _$UpdateQueueDtoCopyWith<$Res> {
  __$UpdateQueueDtoCopyWithImpl(this._self, this._then);

  final _UpdateQueueDto _self;
  final $Res Function(_UpdateQueueDto) _then;

/// Create a copy of UpdateQueueDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? description = freezed,}) {
  return _then(_UpdateQueueDto(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
