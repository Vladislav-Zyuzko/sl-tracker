// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invitation_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvitationDto {

 String get id;/// Роль, которую получит вступивший. Администратора выдать нельзя (D-05).
 InvitationDtoRole get role;/// Вычисляется из срока и отметки об отзыве, отдельно не хранится. Истёкшие и отозванные остаются в списке, но повторно активировать их нельзя (US-22).
 InvitationDtoState get state;/// Полная ссылка-приглашение. Заполнена только у действующего приглашения: у истёкшего и отозванного её нет и копировать нечего (US-22).
 String? get url; DateTime get expiresAt; DateTime? get revokedAt; DateTime get createdAt;/// Кто создал приглашение
 InvitationAuthorDto get createdBy;/// Сколько человек вступило по этой ссылке (US-22)
 num get acceptedCount;
/// Create a copy of InvitationDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvitationDtoCopyWith<InvitationDto> get copyWith => _$InvitationDtoCopyWithImpl<InvitationDto>(this as InvitationDto, _$identity);

  /// Serializes this InvitationDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InvitationDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvitationDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.revokedAt, _this.revokedAt) || other.revokedAt == _this.revokedAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.acceptedCount, _this.acceptedCount) || other.acceptedCount == _this.acceptedCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InvitationDto;
  return Object.hash(runtimeType,_this.id,_this.role,_this.state,_this.url,_this.expiresAt,_this.revokedAt,_this.createdAt,_this.createdBy,_this.acceptedCount);
}

@override
String toString() {
  final _this = this as InvitationDto;
  return 'InvitationDto(id: ${_this.id}, role: ${_this.role}, state: ${_this.state}, url: ${_this.url}, expiresAt: ${_this.expiresAt}, revokedAt: ${_this.revokedAt}, createdAt: ${_this.createdAt}, createdBy: ${_this.createdBy}, acceptedCount: ${_this.acceptedCount})';
}


}

/// @nodoc
abstract mixin class $InvitationDtoCopyWith<$Res>  {
  factory $InvitationDtoCopyWith(InvitationDto value, $Res Function(InvitationDto) _then) = _$InvitationDtoCopyWithImpl;
@useResult
$Res call({
 String id, InvitationDtoRole role, InvitationDtoState state, String? url, DateTime expiresAt, DateTime? revokedAt, DateTime createdAt, InvitationAuthorDto createdBy, num acceptedCount
});


$InvitationAuthorDtoCopyWith<$Res> get createdBy;

}
/// @nodoc
class _$InvitationDtoCopyWithImpl<$Res>
    implements $InvitationDtoCopyWith<$Res> {
  _$InvitationDtoCopyWithImpl(this._self, this._then);

  final InvitationDto _self;
  final $Res Function(InvitationDto) _then;

/// Create a copy of InvitationDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? role = null,Object? state = null,Object? url = freezed,Object? expiresAt = null,Object? revokedAt = freezed,Object? createdAt = null,Object? createdBy = null,Object? acceptedCount = null,}) {
  return _then(InvitationDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as InvitationDtoRole,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as InvitationDtoState,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,revokedAt: freezed == revokedAt ? _self.revokedAt : revokedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as InvitationAuthorDto,acceptedCount: null == acceptedCount ? _self.acceptedCount : acceptedCount // ignore: cast_nullable_to_non_nullable
as num,
  ));
}
/// Create a copy of InvitationDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvitationAuthorDtoCopyWith<$Res> get createdBy {
  
  return $InvitationAuthorDtoCopyWith<$Res>(_self.createdBy, (value) {
    return _then(_self.copyWith(createdBy: value));
  });
}
}


/// Adds pattern-matching-related methods to [InvitationDto].
extension InvitationDtoPatterns on InvitationDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvitationDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvitationDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvitationDto value)  $default,){
final _that = this;
switch (_that) {
case _InvitationDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvitationDto value)?  $default,){
final _that = this;
switch (_that) {
case _InvitationDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  InvitationDtoRole role,  InvitationDtoState state,  String? url,  DateTime expiresAt,  DateTime? revokedAt,  DateTime createdAt,  InvitationAuthorDto createdBy,  num acceptedCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvitationDto() when $default != null:
return $default(_that.id,_that.role,_that.state,_that.url,_that.expiresAt,_that.revokedAt,_that.createdAt,_that.createdBy,_that.acceptedCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  InvitationDtoRole role,  InvitationDtoState state,  String? url,  DateTime expiresAt,  DateTime? revokedAt,  DateTime createdAt,  InvitationAuthorDto createdBy,  num acceptedCount)  $default,) {final _that = this;
switch (_that) {
case _InvitationDto():
return $default(_that.id,_that.role,_that.state,_that.url,_that.expiresAt,_that.revokedAt,_that.createdAt,_that.createdBy,_that.acceptedCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  InvitationDtoRole role,  InvitationDtoState state,  String? url,  DateTime expiresAt,  DateTime? revokedAt,  DateTime createdAt,  InvitationAuthorDto createdBy,  num acceptedCount)?  $default,) {final _that = this;
switch (_that) {
case _InvitationDto() when $default != null:
return $default(_that.id,_that.role,_that.state,_that.url,_that.expiresAt,_that.revokedAt,_that.createdAt,_that.createdBy,_that.acceptedCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvitationDto implements InvitationDto {
  const _InvitationDto({required this.id, required this.role, required this.state, required this.url, required this.expiresAt, required this.revokedAt, required this.createdAt, required this.createdBy, required this.acceptedCount});
  factory _InvitationDto.fromJson(Map<String, dynamic> json) => _$InvitationDtoFromJson(json);

@override final  String id;
/// Роль, которую получит вступивший. Администратора выдать нельзя (D-05).
@override final  InvitationDtoRole role;
/// Вычисляется из срока и отметки об отзыве, отдельно не хранится. Истёкшие и отозванные остаются в списке, но повторно активировать их нельзя (US-22).
@override final  InvitationDtoState state;
/// Полная ссылка-приглашение. Заполнена только у действующего приглашения: у истёкшего и отозванного её нет и копировать нечего (US-22).
@override final  String? url;
@override final  DateTime expiresAt;
@override final  DateTime? revokedAt;
@override final  DateTime createdAt;
/// Кто создал приглашение
@override final  InvitationAuthorDto createdBy;
/// Сколько человек вступило по этой ссылке (US-22)
@override final  num acceptedCount;

/// Create a copy of InvitationDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvitationDtoCopyWith<_InvitationDto> get copyWith => __$InvitationDtoCopyWithImpl<_InvitationDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvitationDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvitationDto&&(identical(other.id, id) || other.id == id)&&(identical(other.role, role) || other.role == role)&&(identical(other.state, state) || other.state == state)&&(identical(other.url, url) || other.url == url)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.revokedAt, revokedAt) || other.revokedAt == revokedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.acceptedCount, acceptedCount) || other.acceptedCount == acceptedCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,role,state,url,expiresAt,revokedAt,createdAt,createdBy,acceptedCount);
}

@override
String toString() {
    return 'InvitationDto(id: $id, role: $role, state: $state, url: $url, expiresAt: $expiresAt, revokedAt: $revokedAt, createdAt: $createdAt, createdBy: $createdBy, acceptedCount: $acceptedCount)';
}


}

/// @nodoc
abstract mixin class _$InvitationDtoCopyWith<$Res> implements $InvitationDtoCopyWith<$Res> {
  factory _$InvitationDtoCopyWith(_InvitationDto value, $Res Function(_InvitationDto) _then) = __$InvitationDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, InvitationDtoRole role, InvitationDtoState state, String? url, DateTime expiresAt, DateTime? revokedAt, DateTime createdAt, InvitationAuthorDto createdBy, num acceptedCount
});


@override $InvitationAuthorDtoCopyWith<$Res> get createdBy;

}
/// @nodoc
class __$InvitationDtoCopyWithImpl<$Res>
    implements _$InvitationDtoCopyWith<$Res> {
  __$InvitationDtoCopyWithImpl(this._self, this._then);

  final _InvitationDto _self;
  final $Res Function(_InvitationDto) _then;

/// Create a copy of InvitationDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? role = null,Object? state = null,Object? url = freezed,Object? expiresAt = null,Object? revokedAt = freezed,Object? createdAt = null,Object? createdBy = null,Object? acceptedCount = null,}) {
  return _then(_InvitationDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as InvitationDtoRole,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as InvitationDtoState,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,revokedAt: freezed == revokedAt ? _self.revokedAt : revokedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as InvitationAuthorDto,acceptedCount: null == acceptedCount ? _self.acceptedCount : acceptedCount // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

/// Create a copy of InvitationDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvitationAuthorDtoCopyWith<$Res> get createdBy {
  
  return $InvitationAuthorDtoCopyWith<$Res>(_self.createdBy, (value) {
    return _then(_self.copyWith(createdBy: value));
  });
}
}

// dart format on
