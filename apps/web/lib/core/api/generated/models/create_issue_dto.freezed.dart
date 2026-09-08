// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_issue_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreateIssueDto {

/// Единственное обязательное поле (US-40)
 String get title;/// 0–100 с шагом 10. По умолчанию 50. `null` недопустим (D-15).
 CreateIssueDtoPriority get priority;/// Markdown, хранится как текст и рендерится клиентом. Сервер разметку не обрабатывает и не санитизирует: исполняемое содержимое (сырой HTML, скрипты, схемы ссылок кроме `http`, `https`, `mailto`) в трекере недопустимо, и не исполнять его — обязанность клиента при рендере (D-22, US-43).
 String? get description;/// Статус из набора этой очереди. По умолчанию — первый статус очереди («Открыт»).
 String? get statusId;/// Шкала Фибоначчи. `null` или отсутствие поля — «не оценено» (D-16).
 CreateIssueDtoStoryPoints? get storyPoints;/// Автор задачи. По умолчанию — создатель. Только участник проекта (US-53).
 String? get authorId;/// Исполнитель. `null` — «Не назначен». Только участник проекта (US-52).
 String? get assigneeId;
/// Create a copy of CreateIssueDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateIssueDtoCopyWith<CreateIssueDto> get copyWith => _$CreateIssueDtoCopyWithImpl<CreateIssueDto>(this as CreateIssueDto, _$identity);

  /// Serializes this CreateIssueDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CreateIssueDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateIssueDto&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.priority, _this.priority) || other.priority == _this.priority)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.statusId, _this.statusId) || other.statusId == _this.statusId)&&(identical(other.storyPoints, _this.storyPoints) || other.storyPoints == _this.storyPoints)&&(identical(other.authorId, _this.authorId) || other.authorId == _this.authorId)&&(identical(other.assigneeId, _this.assigneeId) || other.assigneeId == _this.assigneeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CreateIssueDto;
  return Object.hash(runtimeType,_this.title,_this.priority,_this.description,_this.statusId,_this.storyPoints,_this.authorId,_this.assigneeId);
}

@override
String toString() {
  final _this = this as CreateIssueDto;
  return 'CreateIssueDto(title: ${_this.title}, priority: ${_this.priority}, description: ${_this.description}, statusId: ${_this.statusId}, storyPoints: ${_this.storyPoints}, authorId: ${_this.authorId}, assigneeId: ${_this.assigneeId})';
}


}

/// @nodoc
abstract mixin class $CreateIssueDtoCopyWith<$Res>  {
  factory $CreateIssueDtoCopyWith(CreateIssueDto value, $Res Function(CreateIssueDto) _then) = _$CreateIssueDtoCopyWithImpl;
@useResult
$Res call({
 String title, CreateIssueDtoPriority priority, String? description, String? statusId, CreateIssueDtoStoryPoints? storyPoints, String? authorId, String? assigneeId
});




}
/// @nodoc
class _$CreateIssueDtoCopyWithImpl<$Res>
    implements $CreateIssueDtoCopyWith<$Res> {
  _$CreateIssueDtoCopyWithImpl(this._self, this._then);

  final CreateIssueDto _self;
  final $Res Function(CreateIssueDto) _then;

/// Create a copy of CreateIssueDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? priority = null,Object? description = freezed,Object? statusId = freezed,Object? storyPoints = freezed,Object? authorId = freezed,Object? assigneeId = freezed,}) {
  return _then(CreateIssueDto(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as CreateIssueDtoPriority,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,statusId: freezed == statusId ? _self.statusId : statusId // ignore: cast_nullable_to_non_nullable
as String?,storyPoints: freezed == storyPoints ? _self.storyPoints : storyPoints // ignore: cast_nullable_to_non_nullable
as CreateIssueDtoStoryPoints?,authorId: freezed == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String?,assigneeId: freezed == assigneeId ? _self.assigneeId : assigneeId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateIssueDto].
extension CreateIssueDtoPatterns on CreateIssueDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateIssueDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateIssueDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateIssueDto value)  $default,){
final _that = this;
switch (_that) {
case _CreateIssueDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateIssueDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreateIssueDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  CreateIssueDtoPriority priority,  String? description,  String? statusId,  CreateIssueDtoStoryPoints? storyPoints,  String? authorId,  String? assigneeId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateIssueDto() when $default != null:
return $default(_that.title,_that.priority,_that.description,_that.statusId,_that.storyPoints,_that.authorId,_that.assigneeId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  CreateIssueDtoPriority priority,  String? description,  String? statusId,  CreateIssueDtoStoryPoints? storyPoints,  String? authorId,  String? assigneeId)  $default,) {final _that = this;
switch (_that) {
case _CreateIssueDto():
return $default(_that.title,_that.priority,_that.description,_that.statusId,_that.storyPoints,_that.authorId,_that.assigneeId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  CreateIssueDtoPriority priority,  String? description,  String? statusId,  CreateIssueDtoStoryPoints? storyPoints,  String? authorId,  String? assigneeId)?  $default,) {final _that = this;
switch (_that) {
case _CreateIssueDto() when $default != null:
return $default(_that.title,_that.priority,_that.description,_that.statusId,_that.storyPoints,_that.authorId,_that.assigneeId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateIssueDto implements CreateIssueDto {
  const _CreateIssueDto({required this.title, this.priority = CreateIssueDtoPriority.value50, this.description, this.statusId, this.storyPoints, this.authorId, this.assigneeId});
  factory _CreateIssueDto.fromJson(Map<String, dynamic> json) => _$CreateIssueDtoFromJson(json);

/// Единственное обязательное поле (US-40)
@override final  String title;
/// 0–100 с шагом 10. По умолчанию 50. `null` недопустим (D-15).
@override@JsonKey() final  CreateIssueDtoPriority priority;
/// Markdown, хранится как текст и рендерится клиентом. Сервер разметку не обрабатывает и не санитизирует: исполняемое содержимое (сырой HTML, скрипты, схемы ссылок кроме `http`, `https`, `mailto`) в трекере недопустимо, и не исполнять его — обязанность клиента при рендере (D-22, US-43).
@override final  String? description;
/// Статус из набора этой очереди. По умолчанию — первый статус очереди («Открыт»).
@override final  String? statusId;
/// Шкала Фибоначчи. `null` или отсутствие поля — «не оценено» (D-16).
@override final  CreateIssueDtoStoryPoints? storyPoints;
/// Автор задачи. По умолчанию — создатель. Только участник проекта (US-53).
@override final  String? authorId;
/// Исполнитель. `null` — «Не назначен». Только участник проекта (US-52).
@override final  String? assigneeId;

/// Create a copy of CreateIssueDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateIssueDtoCopyWith<_CreateIssueDto> get copyWith => __$CreateIssueDtoCopyWithImpl<_CreateIssueDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateIssueDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateIssueDto&&(identical(other.title, title) || other.title == title)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.description, description) || other.description == description)&&(identical(other.statusId, statusId) || other.statusId == statusId)&&(identical(other.storyPoints, storyPoints) || other.storyPoints == storyPoints)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.assigneeId, assigneeId) || other.assigneeId == assigneeId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,priority,description,statusId,storyPoints,authorId,assigneeId);
}

@override
String toString() {
    return 'CreateIssueDto(title: $title, priority: $priority, description: $description, statusId: $statusId, storyPoints: $storyPoints, authorId: $authorId, assigneeId: $assigneeId)';
}


}

/// @nodoc
abstract mixin class _$CreateIssueDtoCopyWith<$Res> implements $CreateIssueDtoCopyWith<$Res> {
  factory _$CreateIssueDtoCopyWith(_CreateIssueDto value, $Res Function(_CreateIssueDto) _then) = __$CreateIssueDtoCopyWithImpl;
@override @useResult
$Res call({
 String title, CreateIssueDtoPriority priority, String? description, String? statusId, CreateIssueDtoStoryPoints? storyPoints, String? authorId, String? assigneeId
});




}
/// @nodoc
class __$CreateIssueDtoCopyWithImpl<$Res>
    implements _$CreateIssueDtoCopyWith<$Res> {
  __$CreateIssueDtoCopyWithImpl(this._self, this._then);

  final _CreateIssueDto _self;
  final $Res Function(_CreateIssueDto) _then;

/// Create a copy of CreateIssueDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? priority = null,Object? description = freezed,Object? statusId = freezed,Object? storyPoints = freezed,Object? authorId = freezed,Object? assigneeId = freezed,}) {
  return _then(_CreateIssueDto(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as CreateIssueDtoPriority,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,statusId: freezed == statusId ? _self.statusId : statusId // ignore: cast_nullable_to_non_nullable
as String?,storyPoints: freezed == storyPoints ? _self.storyPoints : storyPoints // ignore: cast_nullable_to_non_nullable
as CreateIssueDtoStoryPoints?,authorId: freezed == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String?,assigneeId: freezed == assigneeId ? _self.assigneeId : assigneeId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
