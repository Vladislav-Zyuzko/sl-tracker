// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'me_response_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MeResponseDto {

 String get id;/// Имя из Яндекс ID, обновляется при входе
 String get displayName; String get email;/// Аватар из Яндекс ID
 String? get avatarUrl;/// Владелец трекера — единственная глобальная роль (permissions.md, п. 1.2). Прав внутри проектов не даёт.
 bool get isInstanceOwner;/// Показывать ли пункт «Доступ к трекеру». Флаг приходит с сервера готовым: клиент не вычисляет право сам (design/screens/access-list.md, Q-D30).
 bool get canManageAccessList; MeSessionDto get session;
/// Create a copy of MeResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MeResponseDtoCopyWith<MeResponseDto> get copyWith => _$MeResponseDtoCopyWithImpl<MeResponseDto>(this as MeResponseDto, _$identity);

  /// Serializes this MeResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MeResponseDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MeResponseDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl)&&(identical(other.isInstanceOwner, _this.isInstanceOwner) || other.isInstanceOwner == _this.isInstanceOwner)&&(identical(other.canManageAccessList, _this.canManageAccessList) || other.canManageAccessList == _this.canManageAccessList)&&(identical(other.session, _this.session) || other.session == _this.session));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MeResponseDto;
  return Object.hash(runtimeType,_this.id,_this.displayName,_this.email,_this.avatarUrl,_this.isInstanceOwner,_this.canManageAccessList,_this.session);
}

@override
String toString() {
  final _this = this as MeResponseDto;
  return 'MeResponseDto(id: ${_this.id}, displayName: ${_this.displayName}, email: ${_this.email}, avatarUrl: ${_this.avatarUrl}, isInstanceOwner: ${_this.isInstanceOwner}, canManageAccessList: ${_this.canManageAccessList}, session: ${_this.session})';
}


}

/// @nodoc
abstract mixin class $MeResponseDtoCopyWith<$Res>  {
  factory $MeResponseDtoCopyWith(MeResponseDto value, $Res Function(MeResponseDto) _then) = _$MeResponseDtoCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String email, String? avatarUrl, bool isInstanceOwner, bool canManageAccessList, MeSessionDto session
});


$MeSessionDtoCopyWith<$Res> get session;

}
/// @nodoc
class _$MeResponseDtoCopyWithImpl<$Res>
    implements $MeResponseDtoCopyWith<$Res> {
  _$MeResponseDtoCopyWithImpl(this._self, this._then);

  final MeResponseDto _self;
  final $Res Function(MeResponseDto) _then;

/// Create a copy of MeResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? email = null,Object? avatarUrl = freezed,Object? isInstanceOwner = null,Object? canManageAccessList = null,Object? session = null,}) {
  return _then(MeResponseDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isInstanceOwner: null == isInstanceOwner ? _self.isInstanceOwner : isInstanceOwner // ignore: cast_nullable_to_non_nullable
as bool,canManageAccessList: null == canManageAccessList ? _self.canManageAccessList : canManageAccessList // ignore: cast_nullable_to_non_nullable
as bool,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as MeSessionDto,
  ));
}
/// Create a copy of MeResponseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeSessionDtoCopyWith<$Res> get session {
  
  return $MeSessionDtoCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}


/// Adds pattern-matching-related methods to [MeResponseDto].
extension MeResponseDtoPatterns on MeResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MeResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MeResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MeResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _MeResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MeResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _MeResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String email,  String? avatarUrl,  bool isInstanceOwner,  bool canManageAccessList,  MeSessionDto session)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MeResponseDto() when $default != null:
return $default(_that.id,_that.displayName,_that.email,_that.avatarUrl,_that.isInstanceOwner,_that.canManageAccessList,_that.session);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String email,  String? avatarUrl,  bool isInstanceOwner,  bool canManageAccessList,  MeSessionDto session)  $default,) {final _that = this;
switch (_that) {
case _MeResponseDto():
return $default(_that.id,_that.displayName,_that.email,_that.avatarUrl,_that.isInstanceOwner,_that.canManageAccessList,_that.session);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String email,  String? avatarUrl,  bool isInstanceOwner,  bool canManageAccessList,  MeSessionDto session)?  $default,) {final _that = this;
switch (_that) {
case _MeResponseDto() when $default != null:
return $default(_that.id,_that.displayName,_that.email,_that.avatarUrl,_that.isInstanceOwner,_that.canManageAccessList,_that.session);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MeResponseDto implements MeResponseDto {
  const _MeResponseDto({required this.id, required this.displayName, required this.email, required this.avatarUrl, required this.isInstanceOwner, required this.canManageAccessList, required this.session});
  factory _MeResponseDto.fromJson(Map<String, dynamic> json) => _$MeResponseDtoFromJson(json);

@override final  String id;
/// Имя из Яндекс ID, обновляется при входе
@override final  String displayName;
@override final  String email;
/// Аватар из Яндекс ID
@override final  String? avatarUrl;
/// Владелец трекера — единственная глобальная роль (permissions.md, п. 1.2). Прав внутри проектов не даёт.
@override final  bool isInstanceOwner;
/// Показывать ли пункт «Доступ к трекеру». Флаг приходит с сервера готовым: клиент не вычисляет право сам (design/screens/access-list.md, Q-D30).
@override final  bool canManageAccessList;
@override final  MeSessionDto session;

/// Create a copy of MeResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MeResponseDtoCopyWith<_MeResponseDto> get copyWith => __$MeResponseDtoCopyWithImpl<_MeResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MeResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MeResponseDto&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isInstanceOwner, isInstanceOwner) || other.isInstanceOwner == isInstanceOwner)&&(identical(other.canManageAccessList, canManageAccessList) || other.canManageAccessList == canManageAccessList)&&(identical(other.session, session) || other.session == session));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,displayName,email,avatarUrl,isInstanceOwner,canManageAccessList,session);
}

@override
String toString() {
    return 'MeResponseDto(id: $id, displayName: $displayName, email: $email, avatarUrl: $avatarUrl, isInstanceOwner: $isInstanceOwner, canManageAccessList: $canManageAccessList, session: $session)';
}


}

/// @nodoc
abstract mixin class _$MeResponseDtoCopyWith<$Res> implements $MeResponseDtoCopyWith<$Res> {
  factory _$MeResponseDtoCopyWith(_MeResponseDto value, $Res Function(_MeResponseDto) _then) = __$MeResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String email, String? avatarUrl, bool isInstanceOwner, bool canManageAccessList, MeSessionDto session
});


@override $MeSessionDtoCopyWith<$Res> get session;

}
/// @nodoc
class __$MeResponseDtoCopyWithImpl<$Res>
    implements _$MeResponseDtoCopyWith<$Res> {
  __$MeResponseDtoCopyWithImpl(this._self, this._then);

  final _MeResponseDto _self;
  final $Res Function(_MeResponseDto) _then;

/// Create a copy of MeResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? email = null,Object? avatarUrl = freezed,Object? isInstanceOwner = null,Object? canManageAccessList = null,Object? session = null,}) {
  return _then(_MeResponseDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isInstanceOwner: null == isInstanceOwner ? _self.isInstanceOwner : isInstanceOwner // ignore: cast_nullable_to_non_nullable
as bool,canManageAccessList: null == canManageAccessList ? _self.canManageAccessList : canManageAccessList // ignore: cast_nullable_to_non_nullable
as bool,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as MeSessionDto,
  ));
}

/// Create a copy of MeResponseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MeSessionDtoCopyWith<$Res> get session {
  
  return $MeSessionDtoCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

// dart format on
