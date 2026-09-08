// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_issue_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateIssueDto {

 String? get title;/// Markdown, хранится как текст и рендерится клиентом. Сервер разметку не обрабатывает и не санитизирует: исполняемое содержимое (сырой HTML, скрипты, схемы ссылок кроме `http`, `https`, `mailto`) в трекере недопустимо, и не исполнять его — обязанность клиента при рендере (D-22, US-43). `null` или пустая строка очищают описание.
 String? get description;/// Новый статус. Переход разрешён из любого статуса очереди в любой другой, включая возврат назад и закрытие из любого состояния (D-10). Статус чужой очереди отклоняется.
 String? get statusId; UpdateIssueDtoPriority? get priority;/// `null` снимает оценку и возвращает «не оценено» (US-51).
 UpdateIssueDtoStoryPoints? get storyPoints;/// Новый автор — любой участник проекта. Очистить поле нельзя. Смена автора логируется отдельной записью истории; создатель задачи при этом не меняется (D-13).
 String? get authorId;/// `null` снимает исполнителя и возвращает «Не назначен».
 String? get assigneeId;
/// Create a copy of UpdateIssueDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateIssueDtoCopyWith<UpdateIssueDto> get copyWith => _$UpdateIssueDtoCopyWithImpl<UpdateIssueDto>(this as UpdateIssueDto, _$identity);

  /// Serializes this UpdateIssueDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UpdateIssueDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateIssueDto&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.statusId, _this.statusId) || other.statusId == _this.statusId)&&(identical(other.priority, _this.priority) || other.priority == _this.priority)&&(identical(other.storyPoints, _this.storyPoints) || other.storyPoints == _this.storyPoints)&&(identical(other.authorId, _this.authorId) || other.authorId == _this.authorId)&&(identical(other.assigneeId, _this.assigneeId) || other.assigneeId == _this.assigneeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UpdateIssueDto;
  return Object.hash(runtimeType,_this.title,_this.description,_this.statusId,_this.priority,_this.storyPoints,_this.authorId,_this.assigneeId);
}

@override
String toString() {
  final _this = this as UpdateIssueDto;
  return 'UpdateIssueDto(title: ${_this.title}, description: ${_this.description}, statusId: ${_this.statusId}, priority: ${_this.priority}, storyPoints: ${_this.storyPoints}, authorId: ${_this.authorId}, assigneeId: ${_this.assigneeId})';
}


}

/// @nodoc
abstract mixin class $UpdateIssueDtoCopyWith<$Res>  {
  factory $UpdateIssueDtoCopyWith(UpdateIssueDto value, $Res Function(UpdateIssueDto) _then) = _$UpdateIssueDtoCopyWithImpl;
@useResult
$Res call({
 String? title, String? description, String? statusId, UpdateIssueDtoPriority? priority, UpdateIssueDtoStoryPoints? storyPoints, String? authorId, String? assigneeId
});




}
/// @nodoc
class _$UpdateIssueDtoCopyWithImpl<$Res>
    implements $UpdateIssueDtoCopyWith<$Res> {
  _$UpdateIssueDtoCopyWithImpl(this._self, this._then);

  final UpdateIssueDto _self;
  final $Res Function(UpdateIssueDto) _then;

/// Create a copy of UpdateIssueDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? description = freezed,Object? statusId = freezed,Object? priority = freezed,Object? storyPoints = freezed,Object? authorId = freezed,Object? assigneeId = freezed,}) {
  return _then(UpdateIssueDto(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,statusId: freezed == statusId ? _self.statusId : statusId // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as UpdateIssueDtoPriority?,storyPoints: freezed == storyPoints ? _self.storyPoints : storyPoints // ignore: cast_nullable_to_non_nullable
as UpdateIssueDtoStoryPoints?,authorId: freezed == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String?,assigneeId: freezed == assigneeId ? _self.assigneeId : assigneeId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateIssueDto].
extension UpdateIssueDtoPatterns on UpdateIssueDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateIssueDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateIssueDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateIssueDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdateIssueDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateIssueDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateIssueDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  String? description,  String? statusId,  UpdateIssueDtoPriority? priority,  UpdateIssueDtoStoryPoints? storyPoints,  String? authorId,  String? assigneeId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateIssueDto() when $default != null:
return $default(_that.title,_that.description,_that.statusId,_that.priority,_that.storyPoints,_that.authorId,_that.assigneeId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  String? description,  String? statusId,  UpdateIssueDtoPriority? priority,  UpdateIssueDtoStoryPoints? storyPoints,  String? authorId,  String? assigneeId)  $default,) {final _that = this;
switch (_that) {
case _UpdateIssueDto():
return $default(_that.title,_that.description,_that.statusId,_that.priority,_that.storyPoints,_that.authorId,_that.assigneeId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  String? description,  String? statusId,  UpdateIssueDtoPriority? priority,  UpdateIssueDtoStoryPoints? storyPoints,  String? authorId,  String? assigneeId)?  $default,) {final _that = this;
switch (_that) {
case _UpdateIssueDto() when $default != null:
return $default(_that.title,_that.description,_that.statusId,_that.priority,_that.storyPoints,_that.authorId,_that.assigneeId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateIssueDto implements UpdateIssueDto {
  const _UpdateIssueDto({this.title, this.description, this.statusId, this.priority, this.storyPoints, this.authorId, this.assigneeId});
  factory _UpdateIssueDto.fromJson(Map<String, dynamic> json) => _$UpdateIssueDtoFromJson(json);

@override final  String? title;
/// Markdown, хранится как текст и рендерится клиентом. Сервер разметку не обрабатывает и не санитизирует: исполняемое содержимое (сырой HTML, скрипты, схемы ссылок кроме `http`, `https`, `mailto`) в трекере недопустимо, и не исполнять его — обязанность клиента при рендере (D-22, US-43). `null` или пустая строка очищают описание.
@override final  String? description;
/// Новый статус. Переход разрешён из любого статуса очереди в любой другой, включая возврат назад и закрытие из любого состояния (D-10). Статус чужой очереди отклоняется.
@override final  String? statusId;
@override final  UpdateIssueDtoPriority? priority;
/// `null` снимает оценку и возвращает «не оценено» (US-51).
@override final  UpdateIssueDtoStoryPoints? storyPoints;
/// Новый автор — любой участник проекта. Очистить поле нельзя. Смена автора логируется отдельной записью истории; создатель задачи при этом не меняется (D-13).
@override final  String? authorId;
/// `null` снимает исполнителя и возвращает «Не назначен».
@override final  String? assigneeId;

/// Create a copy of UpdateIssueDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateIssueDtoCopyWith<_UpdateIssueDto> get copyWith => __$UpdateIssueDtoCopyWithImpl<_UpdateIssueDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateIssueDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateIssueDto&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.statusId, statusId) || other.statusId == statusId)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.storyPoints, storyPoints) || other.storyPoints == storyPoints)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.assigneeId, assigneeId) || other.assigneeId == assigneeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,description,statusId,priority,storyPoints,authorId,assigneeId);
}

@override
String toString() {
    return 'UpdateIssueDto(title: $title, description: $description, statusId: $statusId, priority: $priority, storyPoints: $storyPoints, authorId: $authorId, assigneeId: $assigneeId)';
}


}

/// @nodoc
abstract mixin class _$UpdateIssueDtoCopyWith<$Res> implements $UpdateIssueDtoCopyWith<$Res> {
  factory _$UpdateIssueDtoCopyWith(_UpdateIssueDto value, $Res Function(_UpdateIssueDto) _then) = __$UpdateIssueDtoCopyWithImpl;
@override @useResult
$Res call({
 String? title, String? description, String? statusId, UpdateIssueDtoPriority? priority, UpdateIssueDtoStoryPoints? storyPoints, String? authorId, String? assigneeId
});




}
/// @nodoc
class __$UpdateIssueDtoCopyWithImpl<$Res>
    implements _$UpdateIssueDtoCopyWith<$Res> {
  __$UpdateIssueDtoCopyWithImpl(this._self, this._then);

  final _UpdateIssueDto _self;
  final $Res Function(_UpdateIssueDto) _then;

/// Create a copy of UpdateIssueDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? description = freezed,Object? statusId = freezed,Object? priority = freezed,Object? storyPoints = freezed,Object? authorId = freezed,Object? assigneeId = freezed,}) {
  return _then(_UpdateIssueDto(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,statusId: freezed == statusId ? _self.statusId : statusId // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as UpdateIssueDtoPriority?,storyPoints: freezed == storyPoints ? _self.storyPoints : storyPoints // ignore: cast_nullable_to_non_nullable
as UpdateIssueDtoStoryPoints?,authorId: freezed == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String?,assigneeId: freezed == assigneeId ? _self.assigneeId : assigneeId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
