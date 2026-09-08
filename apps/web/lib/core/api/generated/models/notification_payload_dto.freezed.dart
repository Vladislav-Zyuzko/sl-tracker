// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_payload_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationPayloadDto {

/// Ключ задачи на момент события
 String? get issueKey; String? get issueTitle;/// Статус до перехода. Только `issue_status_changed`.
 String? get fromStatusName;/// Статус после перехода. Только `issue_status_changed`.
 String? get toStatusName;/// Начало текста, ~100 символов: комментарий (`issue_commented`) либо текст с упоминанием (`issue_mentioned`). Упоминания развёрнуты в `@Имя`, **разметка Markdown не снята** — её убирает клиент при отрисовке превью (US-102).
 String? get excerpt;/// Где находится упоминание. `description` — в описании задачи: прокручивать надо к описанию, а не к комментарию (US-104). Только `issue_mentioned`.
 NotificationPayloadDtoSource? get source;/// Только `project_member_joined`
 String? get projectSlug;/// Только `project_member_joined`
 String? get projectName;/// Имя вступившего. Только `project_member_joined`.
 String? get memberName;
/// Create a copy of NotificationPayloadDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationPayloadDtoCopyWith<NotificationPayloadDto> get copyWith => _$NotificationPayloadDtoCopyWithImpl<NotificationPayloadDto>(this as NotificationPayloadDto, _$identity);

  /// Serializes this NotificationPayloadDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationPayloadDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationPayloadDto&&(identical(other.issueKey, _this.issueKey) || other.issueKey == _this.issueKey)&&(identical(other.issueTitle, _this.issueTitle) || other.issueTitle == _this.issueTitle)&&(identical(other.fromStatusName, _this.fromStatusName) || other.fromStatusName == _this.fromStatusName)&&(identical(other.toStatusName, _this.toStatusName) || other.toStatusName == _this.toStatusName)&&(identical(other.excerpt, _this.excerpt) || other.excerpt == _this.excerpt)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.projectSlug, _this.projectSlug) || other.projectSlug == _this.projectSlug)&&(identical(other.projectName, _this.projectName) || other.projectName == _this.projectName)&&(identical(other.memberName, _this.memberName) || other.memberName == _this.memberName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationPayloadDto;
  return Object.hash(runtimeType,_this.issueKey,_this.issueTitle,_this.fromStatusName,_this.toStatusName,_this.excerpt,_this.source,_this.projectSlug,_this.projectName,_this.memberName);
}

@override
String toString() {
  final _this = this as NotificationPayloadDto;
  return 'NotificationPayloadDto(issueKey: ${_this.issueKey}, issueTitle: ${_this.issueTitle}, fromStatusName: ${_this.fromStatusName}, toStatusName: ${_this.toStatusName}, excerpt: ${_this.excerpt}, source: ${_this.source}, projectSlug: ${_this.projectSlug}, projectName: ${_this.projectName}, memberName: ${_this.memberName})';
}


}

/// @nodoc
abstract mixin class $NotificationPayloadDtoCopyWith<$Res>  {
  factory $NotificationPayloadDtoCopyWith(NotificationPayloadDto value, $Res Function(NotificationPayloadDto) _then) = _$NotificationPayloadDtoCopyWithImpl;
@useResult
$Res call({
 String? issueKey, String? issueTitle, String? fromStatusName, String? toStatusName, String? excerpt, NotificationPayloadDtoSource? source, String? projectSlug, String? projectName, String? memberName
});




}
/// @nodoc
class _$NotificationPayloadDtoCopyWithImpl<$Res>
    implements $NotificationPayloadDtoCopyWith<$Res> {
  _$NotificationPayloadDtoCopyWithImpl(this._self, this._then);

  final NotificationPayloadDto _self;
  final $Res Function(NotificationPayloadDto) _then;

/// Create a copy of NotificationPayloadDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? issueKey = freezed,Object? issueTitle = freezed,Object? fromStatusName = freezed,Object? toStatusName = freezed,Object? excerpt = freezed,Object? source = freezed,Object? projectSlug = freezed,Object? projectName = freezed,Object? memberName = freezed,}) {
  return _then(NotificationPayloadDto(
issueKey: freezed == issueKey ? _self.issueKey : issueKey // ignore: cast_nullable_to_non_nullable
as String?,issueTitle: freezed == issueTitle ? _self.issueTitle : issueTitle // ignore: cast_nullable_to_non_nullable
as String?,fromStatusName: freezed == fromStatusName ? _self.fromStatusName : fromStatusName // ignore: cast_nullable_to_non_nullable
as String?,toStatusName: freezed == toStatusName ? _self.toStatusName : toStatusName // ignore: cast_nullable_to_non_nullable
as String?,excerpt: freezed == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as NotificationPayloadDtoSource?,projectSlug: freezed == projectSlug ? _self.projectSlug : projectSlug // ignore: cast_nullable_to_non_nullable
as String?,projectName: freezed == projectName ? _self.projectName : projectName // ignore: cast_nullable_to_non_nullable
as String?,memberName: freezed == memberName ? _self.memberName : memberName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationPayloadDto].
extension NotificationPayloadDtoPatterns on NotificationPayloadDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationPayloadDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationPayloadDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationPayloadDto value)  $default,){
final _that = this;
switch (_that) {
case _NotificationPayloadDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationPayloadDto value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationPayloadDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? issueKey,  String? issueTitle,  String? fromStatusName,  String? toStatusName,  String? excerpt,  NotificationPayloadDtoSource? source,  String? projectSlug,  String? projectName,  String? memberName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationPayloadDto() when $default != null:
return $default(_that.issueKey,_that.issueTitle,_that.fromStatusName,_that.toStatusName,_that.excerpt,_that.source,_that.projectSlug,_that.projectName,_that.memberName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? issueKey,  String? issueTitle,  String? fromStatusName,  String? toStatusName,  String? excerpt,  NotificationPayloadDtoSource? source,  String? projectSlug,  String? projectName,  String? memberName)  $default,) {final _that = this;
switch (_that) {
case _NotificationPayloadDto():
return $default(_that.issueKey,_that.issueTitle,_that.fromStatusName,_that.toStatusName,_that.excerpt,_that.source,_that.projectSlug,_that.projectName,_that.memberName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? issueKey,  String? issueTitle,  String? fromStatusName,  String? toStatusName,  String? excerpt,  NotificationPayloadDtoSource? source,  String? projectSlug,  String? projectName,  String? memberName)?  $default,) {final _that = this;
switch (_that) {
case _NotificationPayloadDto() when $default != null:
return $default(_that.issueKey,_that.issueTitle,_that.fromStatusName,_that.toStatusName,_that.excerpt,_that.source,_that.projectSlug,_that.projectName,_that.memberName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationPayloadDto implements NotificationPayloadDto {
  const _NotificationPayloadDto({this.issueKey, this.issueTitle, this.fromStatusName, this.toStatusName, this.excerpt, this.source, this.projectSlug, this.projectName, this.memberName});
  factory _NotificationPayloadDto.fromJson(Map<String, dynamic> json) => _$NotificationPayloadDtoFromJson(json);

/// Ключ задачи на момент события
@override final  String? issueKey;
@override final  String? issueTitle;
/// Статус до перехода. Только `issue_status_changed`.
@override final  String? fromStatusName;
/// Статус после перехода. Только `issue_status_changed`.
@override final  String? toStatusName;
/// Начало текста, ~100 символов: комментарий (`issue_commented`) либо текст с упоминанием (`issue_mentioned`). Упоминания развёрнуты в `@Имя`, **разметка Markdown не снята** — её убирает клиент при отрисовке превью (US-102).
@override final  String? excerpt;
/// Где находится упоминание. `description` — в описании задачи: прокручивать надо к описанию, а не к комментарию (US-104). Только `issue_mentioned`.
@override final  NotificationPayloadDtoSource? source;
/// Только `project_member_joined`
@override final  String? projectSlug;
/// Только `project_member_joined`
@override final  String? projectName;
/// Имя вступившего. Только `project_member_joined`.
@override final  String? memberName;

/// Create a copy of NotificationPayloadDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationPayloadDtoCopyWith<_NotificationPayloadDto> get copyWith => __$NotificationPayloadDtoCopyWithImpl<_NotificationPayloadDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationPayloadDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationPayloadDto&&(identical(other.issueKey, issueKey) || other.issueKey == issueKey)&&(identical(other.issueTitle, issueTitle) || other.issueTitle == issueTitle)&&(identical(other.fromStatusName, fromStatusName) || other.fromStatusName == fromStatusName)&&(identical(other.toStatusName, toStatusName) || other.toStatusName == toStatusName)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.source, source) || other.source == source)&&(identical(other.projectSlug, projectSlug) || other.projectSlug == projectSlug)&&(identical(other.projectName, projectName) || other.projectName == projectName)&&(identical(other.memberName, memberName) || other.memberName == memberName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,issueKey,issueTitle,fromStatusName,toStatusName,excerpt,source,projectSlug,projectName,memberName);
}

@override
String toString() {
    return 'NotificationPayloadDto(issueKey: $issueKey, issueTitle: $issueTitle, fromStatusName: $fromStatusName, toStatusName: $toStatusName, excerpt: $excerpt, source: $source, projectSlug: $projectSlug, projectName: $projectName, memberName: $memberName)';
}


}

/// @nodoc
abstract mixin class _$NotificationPayloadDtoCopyWith<$Res> implements $NotificationPayloadDtoCopyWith<$Res> {
  factory _$NotificationPayloadDtoCopyWith(_NotificationPayloadDto value, $Res Function(_NotificationPayloadDto) _then) = __$NotificationPayloadDtoCopyWithImpl;
@override @useResult
$Res call({
 String? issueKey, String? issueTitle, String? fromStatusName, String? toStatusName, String? excerpt, NotificationPayloadDtoSource? source, String? projectSlug, String? projectName, String? memberName
});




}
/// @nodoc
class __$NotificationPayloadDtoCopyWithImpl<$Res>
    implements _$NotificationPayloadDtoCopyWith<$Res> {
  __$NotificationPayloadDtoCopyWithImpl(this._self, this._then);

  final _NotificationPayloadDto _self;
  final $Res Function(_NotificationPayloadDto) _then;

/// Create a copy of NotificationPayloadDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? issueKey = freezed,Object? issueTitle = freezed,Object? fromStatusName = freezed,Object? toStatusName = freezed,Object? excerpt = freezed,Object? source = freezed,Object? projectSlug = freezed,Object? projectName = freezed,Object? memberName = freezed,}) {
  return _then(_NotificationPayloadDto(
issueKey: freezed == issueKey ? _self.issueKey : issueKey // ignore: cast_nullable_to_non_nullable
as String?,issueTitle: freezed == issueTitle ? _self.issueTitle : issueTitle // ignore: cast_nullable_to_non_nullable
as String?,fromStatusName: freezed == fromStatusName ? _self.fromStatusName : fromStatusName // ignore: cast_nullable_to_non_nullable
as String?,toStatusName: freezed == toStatusName ? _self.toStatusName : toStatusName // ignore: cast_nullable_to_non_nullable
as String?,excerpt: freezed == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as NotificationPayloadDtoSource?,projectSlug: freezed == projectSlug ? _self.projectSlug : projectSlug // ignore: cast_nullable_to_non_nullable
as String?,projectName: freezed == projectName ? _self.projectName : projectName // ignore: cast_nullable_to_non_nullable
as String?,memberName: freezed == memberName ? _self.memberName : memberName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
