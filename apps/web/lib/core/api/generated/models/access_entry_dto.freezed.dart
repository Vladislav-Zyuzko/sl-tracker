// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'access_entry_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AccessEntryDto {

 String get id;/// Всегда в нижнем регистре
 String get email;/// Откуда запись: `config` — из конфигурации инстанса, `manual` — добавлена владельцем вручную, `invitation` — появилась при приёме приглашения (ADR-0006).
 AccessEntryDtoSource get source;/// Владелец трекера — единственная глобальная роль. Даёт право вести список доступа и не даёт никаких прав внутри проектов.
 bool get isInstanceOwner; DateTime get createdAt;/// Когда этот адрес впервые вошёл. `null` — «ещё не входил» (US-07).
 DateTime? get firstLoginAt;/// Пользователь, которым оказался адрес. `null` — человек ещё не входил.
 AccessEntryUserDto? get user;/// Кто добавил запись вручную. Для `config` и `invitation` — `null`.
 AccessEntryUserDto? get addedBy;/// Запись текущего пользователя: удалить её нельзя (US-09, ответ 409).
 bool get isSelf;
/// Create a copy of AccessEntryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccessEntryDtoCopyWith<AccessEntryDto> get copyWith => _$AccessEntryDtoCopyWithImpl<AccessEntryDto>(this as AccessEntryDto, _$identity);

  /// Serializes this AccessEntryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AccessEntryDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccessEntryDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.isInstanceOwner, _this.isInstanceOwner) || other.isInstanceOwner == _this.isInstanceOwner)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.firstLoginAt, _this.firstLoginAt) || other.firstLoginAt == _this.firstLoginAt)&&(identical(other.user, _this.user) || other.user == _this.user)&&(identical(other.addedBy, _this.addedBy) || other.addedBy == _this.addedBy)&&(identical(other.isSelf, _this.isSelf) || other.isSelf == _this.isSelf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AccessEntryDto;
  return Object.hash(runtimeType,_this.id,_this.email,_this.source,_this.isInstanceOwner,_this.createdAt,_this.firstLoginAt,_this.user,_this.addedBy,_this.isSelf);
}

@override
String toString() {
  final _this = this as AccessEntryDto;
  return 'AccessEntryDto(id: ${_this.id}, email: ${_this.email}, source: ${_this.source}, isInstanceOwner: ${_this.isInstanceOwner}, createdAt: ${_this.createdAt}, firstLoginAt: ${_this.firstLoginAt}, user: ${_this.user}, addedBy: ${_this.addedBy}, isSelf: ${_this.isSelf})';
}


}

/// @nodoc
abstract mixin class $AccessEntryDtoCopyWith<$Res>  {
  factory $AccessEntryDtoCopyWith(AccessEntryDto value, $Res Function(AccessEntryDto) _then) = _$AccessEntryDtoCopyWithImpl;
@useResult
$Res call({
 String id, String email, AccessEntryDtoSource source, bool isInstanceOwner, DateTime createdAt, DateTime? firstLoginAt, AccessEntryUserDto? user, AccessEntryUserDto? addedBy, bool isSelf
});


$AccessEntryUserDtoCopyWith<$Res>? get user;$AccessEntryUserDtoCopyWith<$Res>? get addedBy;

}
/// @nodoc
class _$AccessEntryDtoCopyWithImpl<$Res>
    implements $AccessEntryDtoCopyWith<$Res> {
  _$AccessEntryDtoCopyWithImpl(this._self, this._then);

  final AccessEntryDto _self;
  final $Res Function(AccessEntryDto) _then;

/// Create a copy of AccessEntryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = null,Object? source = null,Object? isInstanceOwner = null,Object? createdAt = null,Object? firstLoginAt = freezed,Object? user = freezed,Object? addedBy = freezed,Object? isSelf = null,}) {
  return _then(AccessEntryDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as AccessEntryDtoSource,isInstanceOwner: null == isInstanceOwner ? _self.isInstanceOwner : isInstanceOwner // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,firstLoginAt: freezed == firstLoginAt ? _self.firstLoginAt : firstLoginAt // ignore: cast_nullable_to_non_nullable
as DateTime?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AccessEntryUserDto?,addedBy: freezed == addedBy ? _self.addedBy : addedBy // ignore: cast_nullable_to_non_nullable
as AccessEntryUserDto?,isSelf: null == isSelf ? _self.isSelf : isSelf // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of AccessEntryDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccessEntryUserDtoCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $AccessEntryUserDtoCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of AccessEntryDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccessEntryUserDtoCopyWith<$Res>? get addedBy {
    if (_self.addedBy == null) {
    return null;
  }

  return $AccessEntryUserDtoCopyWith<$Res>(_self.addedBy!, (value) {
    return _then(_self.copyWith(addedBy: value));
  });
}
}


/// Adds pattern-matching-related methods to [AccessEntryDto].
extension AccessEntryDtoPatterns on AccessEntryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccessEntryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccessEntryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccessEntryDto value)  $default,){
final _that = this;
switch (_that) {
case _AccessEntryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccessEntryDto value)?  $default,){
final _that = this;
switch (_that) {
case _AccessEntryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String email,  AccessEntryDtoSource source,  bool isInstanceOwner,  DateTime createdAt,  DateTime? firstLoginAt,  AccessEntryUserDto? user,  AccessEntryUserDto? addedBy,  bool isSelf)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccessEntryDto() when $default != null:
return $default(_that.id,_that.email,_that.source,_that.isInstanceOwner,_that.createdAt,_that.firstLoginAt,_that.user,_that.addedBy,_that.isSelf);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String email,  AccessEntryDtoSource source,  bool isInstanceOwner,  DateTime createdAt,  DateTime? firstLoginAt,  AccessEntryUserDto? user,  AccessEntryUserDto? addedBy,  bool isSelf)  $default,) {final _that = this;
switch (_that) {
case _AccessEntryDto():
return $default(_that.id,_that.email,_that.source,_that.isInstanceOwner,_that.createdAt,_that.firstLoginAt,_that.user,_that.addedBy,_that.isSelf);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String email,  AccessEntryDtoSource source,  bool isInstanceOwner,  DateTime createdAt,  DateTime? firstLoginAt,  AccessEntryUserDto? user,  AccessEntryUserDto? addedBy,  bool isSelf)?  $default,) {final _that = this;
switch (_that) {
case _AccessEntryDto() when $default != null:
return $default(_that.id,_that.email,_that.source,_that.isInstanceOwner,_that.createdAt,_that.firstLoginAt,_that.user,_that.addedBy,_that.isSelf);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AccessEntryDto implements AccessEntryDto {
  const _AccessEntryDto({required this.id, required this.email, required this.source, required this.isInstanceOwner, required this.createdAt, required this.firstLoginAt, required this.user, required this.addedBy, required this.isSelf});
  factory _AccessEntryDto.fromJson(Map<String, dynamic> json) => _$AccessEntryDtoFromJson(json);

@override final  String id;
/// Всегда в нижнем регистре
@override final  String email;
/// Откуда запись: `config` — из конфигурации инстанса, `manual` — добавлена владельцем вручную, `invitation` — появилась при приёме приглашения (ADR-0006).
@override final  AccessEntryDtoSource source;
/// Владелец трекера — единственная глобальная роль. Даёт право вести список доступа и не даёт никаких прав внутри проектов.
@override final  bool isInstanceOwner;
@override final  DateTime createdAt;
/// Когда этот адрес впервые вошёл. `null` — «ещё не входил» (US-07).
@override final  DateTime? firstLoginAt;
/// Пользователь, которым оказался адрес. `null` — человек ещё не входил.
@override final  AccessEntryUserDto? user;
/// Кто добавил запись вручную. Для `config` и `invitation` — `null`.
@override final  AccessEntryUserDto? addedBy;
/// Запись текущего пользователя: удалить её нельзя (US-09, ответ 409).
@override final  bool isSelf;

/// Create a copy of AccessEntryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccessEntryDtoCopyWith<_AccessEntryDto> get copyWith => __$AccessEntryDtoCopyWithImpl<_AccessEntryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccessEntryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccessEntryDto&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.source, source) || other.source == source)&&(identical(other.isInstanceOwner, isInstanceOwner) || other.isInstanceOwner == isInstanceOwner)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.firstLoginAt, firstLoginAt) || other.firstLoginAt == firstLoginAt)&&(identical(other.user, user) || other.user == user)&&(identical(other.addedBy, addedBy) || other.addedBy == addedBy)&&(identical(other.isSelf, isSelf) || other.isSelf == isSelf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,email,source,isInstanceOwner,createdAt,firstLoginAt,user,addedBy,isSelf);
}

@override
String toString() {
    return 'AccessEntryDto(id: $id, email: $email, source: $source, isInstanceOwner: $isInstanceOwner, createdAt: $createdAt, firstLoginAt: $firstLoginAt, user: $user, addedBy: $addedBy, isSelf: $isSelf)';
}


}

/// @nodoc
abstract mixin class _$AccessEntryDtoCopyWith<$Res> implements $AccessEntryDtoCopyWith<$Res> {
  factory _$AccessEntryDtoCopyWith(_AccessEntryDto value, $Res Function(_AccessEntryDto) _then) = __$AccessEntryDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String email, AccessEntryDtoSource source, bool isInstanceOwner, DateTime createdAt, DateTime? firstLoginAt, AccessEntryUserDto? user, AccessEntryUserDto? addedBy, bool isSelf
});


@override $AccessEntryUserDtoCopyWith<$Res>? get user;@override $AccessEntryUserDtoCopyWith<$Res>? get addedBy;

}
/// @nodoc
class __$AccessEntryDtoCopyWithImpl<$Res>
    implements _$AccessEntryDtoCopyWith<$Res> {
  __$AccessEntryDtoCopyWithImpl(this._self, this._then);

  final _AccessEntryDto _self;
  final $Res Function(_AccessEntryDto) _then;

/// Create a copy of AccessEntryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = null,Object? source = null,Object? isInstanceOwner = null,Object? createdAt = null,Object? firstLoginAt = freezed,Object? user = freezed,Object? addedBy = freezed,Object? isSelf = null,}) {
  return _then(_AccessEntryDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as AccessEntryDtoSource,isInstanceOwner: null == isInstanceOwner ? _self.isInstanceOwner : isInstanceOwner // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,firstLoginAt: freezed == firstLoginAt ? _self.firstLoginAt : firstLoginAt // ignore: cast_nullable_to_non_nullable
as DateTime?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AccessEntryUserDto?,addedBy: freezed == addedBy ? _self.addedBy : addedBy // ignore: cast_nullable_to_non_nullable
as AccessEntryUserDto?,isSelf: null == isSelf ? _self.isSelf : isSelf // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of AccessEntryDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccessEntryUserDtoCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $AccessEntryUserDtoCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of AccessEntryDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccessEntryUserDtoCopyWith<$Res>? get addedBy {
    if (_self.addedBy == null) {
    return null;
  }

  return $AccessEntryUserDtoCopyWith<$Res>(_self.addedBy!, (value) {
    return _then(_self.copyWith(addedBy: value));
  });
}
}

// dart format on
