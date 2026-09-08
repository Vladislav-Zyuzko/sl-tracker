// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_queue_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreateQueueDto {

/// Ключ очереди: 2–10 латинских букв и цифр, первый символ — буква. Приводится к верхнему регистру. Уникален **на весь трекер**, а не внутри проекта, и не меняется после создания (ADR-0004).
 String get key; String get name;/// Markdown. Исполняемое содержимое недопустимо (D-22).
 String? get description;
/// Create a copy of CreateQueueDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateQueueDtoCopyWith<CreateQueueDto> get copyWith => _$CreateQueueDtoCopyWithImpl<CreateQueueDto>(this as CreateQueueDto, _$identity);

  /// Serializes this CreateQueueDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CreateQueueDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateQueueDto&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CreateQueueDto;
  return Object.hash(runtimeType,_this.key,_this.name,_this.description);
}

@override
String toString() {
  final _this = this as CreateQueueDto;
  return 'CreateQueueDto(key: ${_this.key}, name: ${_this.name}, description: ${_this.description})';
}


}

/// @nodoc
abstract mixin class $CreateQueueDtoCopyWith<$Res>  {
  factory $CreateQueueDtoCopyWith(CreateQueueDto value, $Res Function(CreateQueueDto) _then) = _$CreateQueueDtoCopyWithImpl;
@useResult
$Res call({
 String key, String name, String? description
});




}
/// @nodoc
class _$CreateQueueDtoCopyWithImpl<$Res>
    implements $CreateQueueDtoCopyWith<$Res> {
  _$CreateQueueDtoCopyWithImpl(this._self, this._then);

  final CreateQueueDto _self;
  final $Res Function(CreateQueueDto) _then;

/// Create a copy of CreateQueueDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? name = null,Object? description = freezed,}) {
  return _then(CreateQueueDto(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateQueueDto].
extension CreateQueueDtoPatterns on CreateQueueDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateQueueDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateQueueDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateQueueDto value)  $default,){
final _that = this;
switch (_that) {
case _CreateQueueDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateQueueDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreateQueueDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String name,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateQueueDto() when $default != null:
return $default(_that.key,_that.name,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String name,  String? description)  $default,) {final _that = this;
switch (_that) {
case _CreateQueueDto():
return $default(_that.key,_that.name,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String name,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _CreateQueueDto() when $default != null:
return $default(_that.key,_that.name,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateQueueDto implements CreateQueueDto {
  const _CreateQueueDto({required this.key, required this.name, this.description});
  factory _CreateQueueDto.fromJson(Map<String, dynamic> json) => _$CreateQueueDtoFromJson(json);

/// Ключ очереди: 2–10 латинских букв и цифр, первый символ — буква. Приводится к верхнему регистру. Уникален **на весь трекер**, а не внутри проекта, и не меняется после создания (ADR-0004).
@override final  String key;
@override final  String name;
/// Markdown. Исполняемое содержимое недопустимо (D-22).
@override final  String? description;

/// Create a copy of CreateQueueDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateQueueDtoCopyWith<_CreateQueueDto> get copyWith => __$CreateQueueDtoCopyWithImpl<_CreateQueueDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateQueueDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateQueueDto&&(identical(other.key, key) || other.key == key)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,key,name,description);
}

@override
String toString() {
    return 'CreateQueueDto(key: $key, name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class _$CreateQueueDtoCopyWith<$Res> implements $CreateQueueDtoCopyWith<$Res> {
  factory _$CreateQueueDtoCopyWith(_CreateQueueDto value, $Res Function(_CreateQueueDto) _then) = __$CreateQueueDtoCopyWithImpl;
@override @useResult
$Res call({
 String key, String name, String? description
});




}
/// @nodoc
class __$CreateQueueDtoCopyWithImpl<$Res>
    implements _$CreateQueueDtoCopyWith<$Res> {
  __$CreateQueueDtoCopyWithImpl(this._self, this._then);

  final _CreateQueueDto _self;
  final $Res Function(_CreateQueueDto) _then;

/// Create a copy of CreateQueueDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? name = null,Object? description = freezed,}) {
  return _then(_CreateQueueDto(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
