// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_token_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreateTokenDto {

/// Как владелец назвал токен — «dsh-mcp», «ноутбук». Нужно, чтобы через полгода было понятно, что отзывать.
 String get name;/// Срок жизни токена в днях. Поле можно не передавать — тогда 365. Бессрочных токенов не бывает: `null` отклоняется, как и значение вне диапазона.
 num get expiresInDays;
/// Create a copy of CreateTokenDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateTokenDtoCopyWith<CreateTokenDto> get copyWith => _$CreateTokenDtoCopyWithImpl<CreateTokenDto>(this as CreateTokenDto, _$identity);

  /// Serializes this CreateTokenDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CreateTokenDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateTokenDto&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.expiresInDays, _this.expiresInDays) || other.expiresInDays == _this.expiresInDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CreateTokenDto;
  return Object.hash(runtimeType,_this.name,_this.expiresInDays);
}

@override
String toString() {
  final _this = this as CreateTokenDto;
  return 'CreateTokenDto(name: ${_this.name}, expiresInDays: ${_this.expiresInDays})';
}


}

/// @nodoc
abstract mixin class $CreateTokenDtoCopyWith<$Res>  {
  factory $CreateTokenDtoCopyWith(CreateTokenDto value, $Res Function(CreateTokenDto) _then) = _$CreateTokenDtoCopyWithImpl;
@useResult
$Res call({
 String name, num expiresInDays
});




}
/// @nodoc
class _$CreateTokenDtoCopyWithImpl<$Res>
    implements $CreateTokenDtoCopyWith<$Res> {
  _$CreateTokenDtoCopyWithImpl(this._self, this._then);

  final CreateTokenDto _self;
  final $Res Function(CreateTokenDto) _then;

/// Create a copy of CreateTokenDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? expiresInDays = null,}) {
  return _then(CreateTokenDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,expiresInDays: null == expiresInDays ? _self.expiresInDays : expiresInDays // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateTokenDto].
extension CreateTokenDtoPatterns on CreateTokenDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateTokenDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateTokenDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateTokenDto value)  $default,){
final _that = this;
switch (_that) {
case _CreateTokenDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateTokenDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreateTokenDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  num expiresInDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateTokenDto() when $default != null:
return $default(_that.name,_that.expiresInDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  num expiresInDays)  $default,) {final _that = this;
switch (_that) {
case _CreateTokenDto():
return $default(_that.name,_that.expiresInDays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  num expiresInDays)?  $default,) {final _that = this;
switch (_that) {
case _CreateTokenDto() when $default != null:
return $default(_that.name,_that.expiresInDays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateTokenDto implements CreateTokenDto {
  const _CreateTokenDto({required this.name, this.expiresInDays = 365});
  factory _CreateTokenDto.fromJson(Map<String, dynamic> json) => _$CreateTokenDtoFromJson(json);

/// Как владелец назвал токен — «dsh-mcp», «ноутбук». Нужно, чтобы через полгода было понятно, что отзывать.
@override final  String name;
/// Срок жизни токена в днях. Поле можно не передавать — тогда 365. Бессрочных токенов не бывает: `null` отклоняется, как и значение вне диапазона.
@override@JsonKey() final  num expiresInDays;

/// Create a copy of CreateTokenDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateTokenDtoCopyWith<_CreateTokenDto> get copyWith => __$CreateTokenDtoCopyWithImpl<_CreateTokenDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateTokenDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateTokenDto&&(identical(other.name, name) || other.name == name)&&(identical(other.expiresInDays, expiresInDays) || other.expiresInDays == expiresInDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,expiresInDays);
}

@override
String toString() {
    return 'CreateTokenDto(name: $name, expiresInDays: $expiresInDays)';
}


}

/// @nodoc
abstract mixin class _$CreateTokenDtoCopyWith<$Res> implements $CreateTokenDtoCopyWith<$Res> {
  factory _$CreateTokenDtoCopyWith(_CreateTokenDto value, $Res Function(_CreateTokenDto) _then) = __$CreateTokenDtoCopyWithImpl;
@override @useResult
$Res call({
 String name, num expiresInDays
});




}
/// @nodoc
class __$CreateTokenDtoCopyWithImpl<$Res>
    implements _$CreateTokenDtoCopyWith<$Res> {
  __$CreateTokenDtoCopyWithImpl(this._self, this._then);

  final _CreateTokenDto _self;
  final $Res Function(_CreateTokenDto) _then;

/// Create a copy of CreateTokenDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? expiresInDays = null,}) {
  return _then(_CreateTokenDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,expiresInDays: null == expiresInDays ? _self.expiresInDays : expiresInDays // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}

// dart format on
