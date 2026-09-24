// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issued_token_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IssuedTokenDto {

 String get id; String get name; String get prefix;/// Сам токен. **Показывается ровно один раз** — в этом ответе. Предъявляется заголовком `Authorization: Bearer <токен>` и даёт те же права, что у владельца.
 String get token; DateTime get expiresAt; DateTime get createdAt;
/// Create a copy of IssuedTokenDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssuedTokenDtoCopyWith<IssuedTokenDto> get copyWith => _$IssuedTokenDtoCopyWithImpl<IssuedTokenDto>(this as IssuedTokenDto, _$identity);

  /// Serializes this IssuedTokenDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IssuedTokenDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssuedTokenDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.prefix, _this.prefix) || other.prefix == _this.prefix)&&(identical(other.token, _this.token) || other.token == _this.token)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IssuedTokenDto;
  return Object.hash(runtimeType,_this.id,_this.name,_this.prefix,_this.token,_this.expiresAt,_this.createdAt);
}

@override
String toString() {
  final _this = this as IssuedTokenDto;
  return 'IssuedTokenDto(id: ${_this.id}, name: ${_this.name}, prefix: ${_this.prefix}, token: ${_this.token}, expiresAt: ${_this.expiresAt}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $IssuedTokenDtoCopyWith<$Res>  {
  factory $IssuedTokenDtoCopyWith(IssuedTokenDto value, $Res Function(IssuedTokenDto) _then) = _$IssuedTokenDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String prefix, String token, DateTime expiresAt, DateTime createdAt
});




}
/// @nodoc
class _$IssuedTokenDtoCopyWithImpl<$Res>
    implements $IssuedTokenDtoCopyWith<$Res> {
  _$IssuedTokenDtoCopyWithImpl(this._self, this._then);

  final IssuedTokenDto _self;
  final $Res Function(IssuedTokenDto) _then;

/// Create a copy of IssuedTokenDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? prefix = null,Object? token = null,Object? expiresAt = null,Object? createdAt = null,}) {
  return _then(IssuedTokenDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,prefix: null == prefix ? _self.prefix : prefix // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [IssuedTokenDto].
extension IssuedTokenDtoPatterns on IssuedTokenDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssuedTokenDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssuedTokenDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssuedTokenDto value)  $default,){
final _that = this;
switch (_that) {
case _IssuedTokenDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssuedTokenDto value)?  $default,){
final _that = this;
switch (_that) {
case _IssuedTokenDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String prefix,  String token,  DateTime expiresAt,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssuedTokenDto() when $default != null:
return $default(_that.id,_that.name,_that.prefix,_that.token,_that.expiresAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String prefix,  String token,  DateTime expiresAt,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _IssuedTokenDto():
return $default(_that.id,_that.name,_that.prefix,_that.token,_that.expiresAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String prefix,  String token,  DateTime expiresAt,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _IssuedTokenDto() when $default != null:
return $default(_that.id,_that.name,_that.prefix,_that.token,_that.expiresAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssuedTokenDto implements IssuedTokenDto {
  const _IssuedTokenDto({required this.id, required this.name, required this.prefix, required this.token, required this.expiresAt, required this.createdAt});
  factory _IssuedTokenDto.fromJson(Map<String, dynamic> json) => _$IssuedTokenDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  String prefix;
/// Сам токен. **Показывается ровно один раз** — в этом ответе. Предъявляется заголовком `Authorization: Bearer <токен>` и даёт те же права, что у владельца.
@override final  String token;
@override final  DateTime expiresAt;
@override final  DateTime createdAt;

/// Create a copy of IssuedTokenDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssuedTokenDtoCopyWith<_IssuedTokenDto> get copyWith => __$IssuedTokenDtoCopyWithImpl<_IssuedTokenDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssuedTokenDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssuedTokenDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.prefix, prefix) || other.prefix == prefix)&&(identical(other.token, token) || other.token == token)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,prefix,token,expiresAt,createdAt);
}

@override
String toString() {
    return 'IssuedTokenDto(id: $id, name: $name, prefix: $prefix, token: $token, expiresAt: $expiresAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$IssuedTokenDtoCopyWith<$Res> implements $IssuedTokenDtoCopyWith<$Res> {
  factory _$IssuedTokenDtoCopyWith(_IssuedTokenDto value, $Res Function(_IssuedTokenDto) _then) = __$IssuedTokenDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String prefix, String token, DateTime expiresAt, DateTime createdAt
});




}
/// @nodoc
class __$IssuedTokenDtoCopyWithImpl<$Res>
    implements _$IssuedTokenDtoCopyWith<$Res> {
  __$IssuedTokenDtoCopyWithImpl(this._self, this._then);

  final _IssuedTokenDto _self;
  final $Res Function(_IssuedTokenDto) _then;

/// Create a copy of IssuedTokenDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? prefix = null,Object? token = null,Object? expiresAt = null,Object? createdAt = null,}) {
  return _then(_IssuedTokenDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,prefix: null == prefix ? _self.prefix : prefix // ignore: cast_nullable_to_non_nullable
as String,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
