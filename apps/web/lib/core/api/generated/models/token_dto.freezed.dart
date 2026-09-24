// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'token_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TokenDto {

 String get id;/// Имя, которое дал владелец
 String get name;/// Первые 8 символов токена — чтобы опознать его в списке. Не секрет и не часть проверки: сам секрет не хранится нигде и после выпуска не показывается.
 String get prefix;/// Всегда `pat`: сессии входа через этот раздел не видны и не отзываются.
 TokenDtoPurpose get purpose; DateTime get createdAt;/// Когда токен предъявляли в последний раз, с точностью до суток: чаще раза в день отметка не обновляется. Пока токеном ни разу не пользовались, **не позже** `createdAt` — отметка ставится кодом, а `createdAt` дефолтом базы, и они расходятся на единицы миллисекунд. Признак «ни разу» проверяется как `lastSeenAt <= createdAt`, сравнение на равенство даст ложное «уже пользовались».
 DateTime get lastSeenAt;/// Когда токен перестанет действовать. Срок задаётся при выпуске и **не продлевается** использованием; бессрочных токенов не бывает.
 DateTime get expiresAt;/// Когда токен отозвали. `null` — токен не отозван.
 DateTime? get revokedAt;
/// Create a copy of TokenDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokenDtoCopyWith<TokenDto> get copyWith => _$TokenDtoCopyWithImpl<TokenDto>(this as TokenDto, _$identity);

  /// Serializes this TokenDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TokenDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TokenDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.prefix, _this.prefix) || other.prefix == _this.prefix)&&(identical(other.purpose, _this.purpose) || other.purpose == _this.purpose)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.lastSeenAt, _this.lastSeenAt) || other.lastSeenAt == _this.lastSeenAt)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.revokedAt, _this.revokedAt) || other.revokedAt == _this.revokedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TokenDto;
  return Object.hash(runtimeType,_this.id,_this.name,_this.prefix,_this.purpose,_this.createdAt,_this.lastSeenAt,_this.expiresAt,_this.revokedAt);
}

@override
String toString() {
  final _this = this as TokenDto;
  return 'TokenDto(id: ${_this.id}, name: ${_this.name}, prefix: ${_this.prefix}, purpose: ${_this.purpose}, createdAt: ${_this.createdAt}, lastSeenAt: ${_this.lastSeenAt}, expiresAt: ${_this.expiresAt}, revokedAt: ${_this.revokedAt})';
}


}

/// @nodoc
abstract mixin class $TokenDtoCopyWith<$Res>  {
  factory $TokenDtoCopyWith(TokenDto value, $Res Function(TokenDto) _then) = _$TokenDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, String prefix, TokenDtoPurpose purpose, DateTime createdAt, DateTime lastSeenAt, DateTime expiresAt, DateTime? revokedAt
});




}
/// @nodoc
class _$TokenDtoCopyWithImpl<$Res>
    implements $TokenDtoCopyWith<$Res> {
  _$TokenDtoCopyWithImpl(this._self, this._then);

  final TokenDto _self;
  final $Res Function(TokenDto) _then;

/// Create a copy of TokenDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? prefix = null,Object? purpose = null,Object? createdAt = null,Object? lastSeenAt = null,Object? expiresAt = null,Object? revokedAt = freezed,}) {
  return _then(TokenDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,prefix: null == prefix ? _self.prefix : prefix // ignore: cast_nullable_to_non_nullable
as String,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as TokenDtoPurpose,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastSeenAt: null == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,revokedAt: freezed == revokedAt ? _self.revokedAt : revokedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TokenDto].
extension TokenDtoPatterns on TokenDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TokenDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TokenDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TokenDto value)  $default,){
final _that = this;
switch (_that) {
case _TokenDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TokenDto value)?  $default,){
final _that = this;
switch (_that) {
case _TokenDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String prefix,  TokenDtoPurpose purpose,  DateTime createdAt,  DateTime lastSeenAt,  DateTime expiresAt,  DateTime? revokedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TokenDto() when $default != null:
return $default(_that.id,_that.name,_that.prefix,_that.purpose,_that.createdAt,_that.lastSeenAt,_that.expiresAt,_that.revokedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String prefix,  TokenDtoPurpose purpose,  DateTime createdAt,  DateTime lastSeenAt,  DateTime expiresAt,  DateTime? revokedAt)  $default,) {final _that = this;
switch (_that) {
case _TokenDto():
return $default(_that.id,_that.name,_that.prefix,_that.purpose,_that.createdAt,_that.lastSeenAt,_that.expiresAt,_that.revokedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String prefix,  TokenDtoPurpose purpose,  DateTime createdAt,  DateTime lastSeenAt,  DateTime expiresAt,  DateTime? revokedAt)?  $default,) {final _that = this;
switch (_that) {
case _TokenDto() when $default != null:
return $default(_that.id,_that.name,_that.prefix,_that.purpose,_that.createdAt,_that.lastSeenAt,_that.expiresAt,_that.revokedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TokenDto implements TokenDto {
  const _TokenDto({required this.id, required this.name, required this.prefix, required this.purpose, required this.createdAt, required this.lastSeenAt, required this.expiresAt, required this.revokedAt});
  factory _TokenDto.fromJson(Map<String, dynamic> json) => _$TokenDtoFromJson(json);

@override final  String id;
/// Имя, которое дал владелец
@override final  String name;
/// Первые 8 символов токена — чтобы опознать его в списке. Не секрет и не часть проверки: сам секрет не хранится нигде и после выпуска не показывается.
@override final  String prefix;
/// Всегда `pat`: сессии входа через этот раздел не видны и не отзываются.
@override final  TokenDtoPurpose purpose;
@override final  DateTime createdAt;
/// Когда токен предъявляли в последний раз, с точностью до суток: чаще раза в день отметка не обновляется. Пока токеном ни разу не пользовались, **не позже** `createdAt` — отметка ставится кодом, а `createdAt` дефолтом базы, и они расходятся на единицы миллисекунд. Признак «ни разу» проверяется как `lastSeenAt <= createdAt`, сравнение на равенство даст ложное «уже пользовались».
@override final  DateTime lastSeenAt;
/// Когда токен перестанет действовать. Срок задаётся при выпуске и **не продлевается** использованием; бессрочных токенов не бывает.
@override final  DateTime expiresAt;
/// Когда токен отозвали. `null` — токен не отозван.
@override final  DateTime? revokedAt;

/// Create a copy of TokenDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TokenDtoCopyWith<_TokenDto> get copyWith => __$TokenDtoCopyWithImpl<_TokenDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TokenDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TokenDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.prefix, prefix) || other.prefix == prefix)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.revokedAt, revokedAt) || other.revokedAt == revokedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,prefix,purpose,createdAt,lastSeenAt,expiresAt,revokedAt);
}

@override
String toString() {
    return 'TokenDto(id: $id, name: $name, prefix: $prefix, purpose: $purpose, createdAt: $createdAt, lastSeenAt: $lastSeenAt, expiresAt: $expiresAt, revokedAt: $revokedAt)';
}


}

/// @nodoc
abstract mixin class _$TokenDtoCopyWith<$Res> implements $TokenDtoCopyWith<$Res> {
  factory _$TokenDtoCopyWith(_TokenDto value, $Res Function(_TokenDto) _then) = __$TokenDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String prefix, TokenDtoPurpose purpose, DateTime createdAt, DateTime lastSeenAt, DateTime expiresAt, DateTime? revokedAt
});




}
/// @nodoc
class __$TokenDtoCopyWithImpl<$Res>
    implements _$TokenDtoCopyWith<$Res> {
  __$TokenDtoCopyWithImpl(this._self, this._then);

  final _TokenDto _self;
  final $Res Function(_TokenDto) _then;

/// Create a copy of TokenDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? prefix = null,Object? purpose = null,Object? createdAt = null,Object? lastSeenAt = null,Object? expiresAt = null,Object? revokedAt = freezed,}) {
  return _then(_TokenDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,prefix: null == prefix ? _self.prefix : prefix // ignore: cast_nullable_to_non_nullable
as String,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as TokenDtoPurpose,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastSeenAt: null == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,revokedAt: freezed == revokedAt ? _self.revokedAt : revokedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
