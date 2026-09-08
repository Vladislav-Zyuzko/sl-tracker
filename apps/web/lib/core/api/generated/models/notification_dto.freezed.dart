// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationDto {

 String get id;/// Тип события. От него зависит текст строки и то, какие поля заполнены в `payload` (design/screens/notifications.md).
 NotificationDtoType get type;/// Канал доставки. В MVP всегда `in_app` (D-18).
 NotificationDtoChannel get channel;/// Кто инициировал событие. `null` — системное событие: в ленте вместо аватара иконка, а не случайный пользователь.
 IssueUserDto? get actor;/// Ключ задачи **сейчас**. `null` означает, что задачи больше нет или она в проекте, из которого пользователя исключили: переход по такому уведомлению показывает «Задача не найдена» (US-103). Текст строки берётся из `payload.issueKey`.
 String? get issueKey;/// Короткое имя проекта — адрес перехода для `project_member_joined` (US-23)
 String? get projectSlug;/// Комментарий, к которому нужно прокрутить задачу (`/issues/DEV-42?comment=<id>`). `null` у удалённого комментария — тогда открывается сама задача, и клиент показывает «Комментарий удалён» (US-102).
 String? get commentId; NotificationPayloadDto get payload;/// `null` — непрочитанное: точка слева и жирное имя инициатора
 DateTime? get readAt; DateTime get createdAt;
/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationDtoCopyWith<NotificationDto> get copyWith => _$NotificationDtoCopyWithImpl<NotificationDto>(this as NotificationDto, _$identity);

  /// Serializes this NotificationDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.channel, _this.channel) || other.channel == _this.channel)&&(identical(other.actor, _this.actor) || other.actor == _this.actor)&&(identical(other.issueKey, _this.issueKey) || other.issueKey == _this.issueKey)&&(identical(other.projectSlug, _this.projectSlug) || other.projectSlug == _this.projectSlug)&&(identical(other.commentId, _this.commentId) || other.commentId == _this.commentId)&&(identical(other.payload, _this.payload) || other.payload == _this.payload)&&(identical(other.readAt, _this.readAt) || other.readAt == _this.readAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationDto;
  return Object.hash(runtimeType,_this.id,_this.type,_this.channel,_this.actor,_this.issueKey,_this.projectSlug,_this.commentId,_this.payload,_this.readAt,_this.createdAt);
}

@override
String toString() {
  final _this = this as NotificationDto;
  return 'NotificationDto(id: ${_this.id}, type: ${_this.type}, channel: ${_this.channel}, actor: ${_this.actor}, issueKey: ${_this.issueKey}, projectSlug: ${_this.projectSlug}, commentId: ${_this.commentId}, payload: ${_this.payload}, readAt: ${_this.readAt}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $NotificationDtoCopyWith<$Res>  {
  factory $NotificationDtoCopyWith(NotificationDto value, $Res Function(NotificationDto) _then) = _$NotificationDtoCopyWithImpl;
@useResult
$Res call({
 String id, NotificationDtoType type, NotificationDtoChannel channel, IssueUserDto? actor, String? issueKey, String? projectSlug, String? commentId, NotificationPayloadDto payload, DateTime? readAt, DateTime createdAt
});


$IssueUserDtoCopyWith<$Res>? get actor;$NotificationPayloadDtoCopyWith<$Res> get payload;

}
/// @nodoc
class _$NotificationDtoCopyWithImpl<$Res>
    implements $NotificationDtoCopyWith<$Res> {
  _$NotificationDtoCopyWithImpl(this._self, this._then);

  final NotificationDto _self;
  final $Res Function(NotificationDto) _then;

/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? channel = null,Object? actor = freezed,Object? issueKey = freezed,Object? projectSlug = freezed,Object? commentId = freezed,Object? payload = null,Object? readAt = freezed,Object? createdAt = null,}) {
  return _then(NotificationDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NotificationDtoType,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as NotificationDtoChannel,actor: freezed == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as IssueUserDto?,issueKey: freezed == issueKey ? _self.issueKey : issueKey // ignore: cast_nullable_to_non_nullable
as String?,projectSlug: freezed == projectSlug ? _self.projectSlug : projectSlug // ignore: cast_nullable_to_non_nullable
as String?,commentId: freezed == commentId ? _self.commentId : commentId // ignore: cast_nullable_to_non_nullable
as String?,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as NotificationPayloadDto,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueUserDtoCopyWith<$Res>? get actor {
    if (_self.actor == null) {
    return null;
  }

  return $IssueUserDtoCopyWith<$Res>(_self.actor!, (value) {
    return _then(_self.copyWith(actor: value));
  });
}/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPayloadDtoCopyWith<$Res> get payload {
  
  return $NotificationPayloadDtoCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}


/// Adds pattern-matching-related methods to [NotificationDto].
extension NotificationDtoPatterns on NotificationDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationDto value)  $default,){
final _that = this;
switch (_that) {
case _NotificationDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationDto value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  NotificationDtoType type,  NotificationDtoChannel channel,  IssueUserDto? actor,  String? issueKey,  String? projectSlug,  String? commentId,  NotificationPayloadDto payload,  DateTime? readAt,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationDto() when $default != null:
return $default(_that.id,_that.type,_that.channel,_that.actor,_that.issueKey,_that.projectSlug,_that.commentId,_that.payload,_that.readAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  NotificationDtoType type,  NotificationDtoChannel channel,  IssueUserDto? actor,  String? issueKey,  String? projectSlug,  String? commentId,  NotificationPayloadDto payload,  DateTime? readAt,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _NotificationDto():
return $default(_that.id,_that.type,_that.channel,_that.actor,_that.issueKey,_that.projectSlug,_that.commentId,_that.payload,_that.readAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  NotificationDtoType type,  NotificationDtoChannel channel,  IssueUserDto? actor,  String? issueKey,  String? projectSlug,  String? commentId,  NotificationPayloadDto payload,  DateTime? readAt,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _NotificationDto() when $default != null:
return $default(_that.id,_that.type,_that.channel,_that.actor,_that.issueKey,_that.projectSlug,_that.commentId,_that.payload,_that.readAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationDto implements NotificationDto {
  const _NotificationDto({required this.id, required this.type, required this.channel, required this.actor, required this.issueKey, required this.projectSlug, required this.commentId, required this.payload, required this.readAt, required this.createdAt});
  factory _NotificationDto.fromJson(Map<String, dynamic> json) => _$NotificationDtoFromJson(json);

@override final  String id;
/// Тип события. От него зависит текст строки и то, какие поля заполнены в `payload` (design/screens/notifications.md).
@override final  NotificationDtoType type;
/// Канал доставки. В MVP всегда `in_app` (D-18).
@override final  NotificationDtoChannel channel;
/// Кто инициировал событие. `null` — системное событие: в ленте вместо аватара иконка, а не случайный пользователь.
@override final  IssueUserDto? actor;
/// Ключ задачи **сейчас**. `null` означает, что задачи больше нет или она в проекте, из которого пользователя исключили: переход по такому уведомлению показывает «Задача не найдена» (US-103). Текст строки берётся из `payload.issueKey`.
@override final  String? issueKey;
/// Короткое имя проекта — адрес перехода для `project_member_joined` (US-23)
@override final  String? projectSlug;
/// Комментарий, к которому нужно прокрутить задачу (`/issues/DEV-42?comment=<id>`). `null` у удалённого комментария — тогда открывается сама задача, и клиент показывает «Комментарий удалён» (US-102).
@override final  String? commentId;
@override final  NotificationPayloadDto payload;
/// `null` — непрочитанное: точка слева и жирное имя инициатора
@override final  DateTime? readAt;
@override final  DateTime createdAt;

/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationDtoCopyWith<_NotificationDto> get copyWith => __$NotificationDtoCopyWithImpl<_NotificationDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationDto&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.issueKey, issueKey) || other.issueKey == issueKey)&&(identical(other.projectSlug, projectSlug) || other.projectSlug == projectSlug)&&(identical(other.commentId, commentId) || other.commentId == commentId)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,type,channel,actor,issueKey,projectSlug,commentId,payload,readAt,createdAt);
}

@override
String toString() {
    return 'NotificationDto(id: $id, type: $type, channel: $channel, actor: $actor, issueKey: $issueKey, projectSlug: $projectSlug, commentId: $commentId, payload: $payload, readAt: $readAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$NotificationDtoCopyWith<$Res> implements $NotificationDtoCopyWith<$Res> {
  factory _$NotificationDtoCopyWith(_NotificationDto value, $Res Function(_NotificationDto) _then) = __$NotificationDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, NotificationDtoType type, NotificationDtoChannel channel, IssueUserDto? actor, String? issueKey, String? projectSlug, String? commentId, NotificationPayloadDto payload, DateTime? readAt, DateTime createdAt
});


@override $IssueUserDtoCopyWith<$Res>? get actor;@override $NotificationPayloadDtoCopyWith<$Res> get payload;

}
/// @nodoc
class __$NotificationDtoCopyWithImpl<$Res>
    implements _$NotificationDtoCopyWith<$Res> {
  __$NotificationDtoCopyWithImpl(this._self, this._then);

  final _NotificationDto _self;
  final $Res Function(_NotificationDto) _then;

/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? channel = null,Object? actor = freezed,Object? issueKey = freezed,Object? projectSlug = freezed,Object? commentId = freezed,Object? payload = null,Object? readAt = freezed,Object? createdAt = null,}) {
  return _then(_NotificationDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NotificationDtoType,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as NotificationDtoChannel,actor: freezed == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as IssueUserDto?,issueKey: freezed == issueKey ? _self.issueKey : issueKey // ignore: cast_nullable_to_non_nullable
as String?,projectSlug: freezed == projectSlug ? _self.projectSlug : projectSlug // ignore: cast_nullable_to_non_nullable
as String?,commentId: freezed == commentId ? _self.commentId : commentId // ignore: cast_nullable_to_non_nullable
as String?,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as NotificationPayloadDto,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueUserDtoCopyWith<$Res>? get actor {
    if (_self.actor == null) {
    return null;
  }

  return $IssueUserDtoCopyWith<$Res>(_self.actor!, (value) {
    return _then(_self.copyWith(actor: value));
  });
}/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPayloadDtoCopyWith<$Res> get payload {
  
  return $NotificationPayloadDtoCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

// dart format on
