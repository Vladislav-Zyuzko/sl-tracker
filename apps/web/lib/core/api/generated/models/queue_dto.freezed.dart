// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'queue_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QueueDto {

/// Ключ очереди. Уникален на весь трекер, неизменяем
 String get key; String get name;/// Markdown, до 1000 символов
 String? get description;/// Короткое имя проекта в адресе
 String get projectSlug;/// Название проекта для хлебных крошек
 String get projectName;/// Незавершённые задачи: те, чей статус не в категории `done` (US-31)
 num get openIssueCount;/// Роль запросившего в проекте, которому принадлежит очередь. Права на очередь наследуются от проекта: прав уровня очереди в MVP нет (permissions.md, п. 3).
 QueueDtoRole get role; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of QueueDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueDtoCopyWith<QueueDto> get copyWith => _$QueueDtoCopyWithImpl<QueueDto>(this as QueueDto, _$identity);

  /// Serializes this QueueDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as QueueDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueDto&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.projectSlug, _this.projectSlug) || other.projectSlug == _this.projectSlug)&&(identical(other.projectName, _this.projectName) || other.projectName == _this.projectName)&&(identical(other.openIssueCount, _this.openIssueCount) || other.openIssueCount == _this.openIssueCount)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as QueueDto;
  return Object.hash(runtimeType,_this.key,_this.name,_this.description,_this.projectSlug,_this.projectName,_this.openIssueCount,_this.role,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as QueueDto;
  return 'QueueDto(key: ${_this.key}, name: ${_this.name}, description: ${_this.description}, projectSlug: ${_this.projectSlug}, projectName: ${_this.projectName}, openIssueCount: ${_this.openIssueCount}, role: ${_this.role}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $QueueDtoCopyWith<$Res>  {
  factory $QueueDtoCopyWith(QueueDto value, $Res Function(QueueDto) _then) = _$QueueDtoCopyWithImpl;
@useResult
$Res call({
 String key, String name, String? description, String projectSlug, String projectName, num openIssueCount, QueueDtoRole role, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$QueueDtoCopyWithImpl<$Res>
    implements $QueueDtoCopyWith<$Res> {
  _$QueueDtoCopyWithImpl(this._self, this._then);

  final QueueDto _self;
  final $Res Function(QueueDto) _then;

/// Create a copy of QueueDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? name = null,Object? description = freezed,Object? projectSlug = null,Object? projectName = null,Object? openIssueCount = null,Object? role = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(QueueDto(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,projectSlug: null == projectSlug ? _self.projectSlug : projectSlug // ignore: cast_nullable_to_non_nullable
as String,projectName: null == projectName ? _self.projectName : projectName // ignore: cast_nullable_to_non_nullable
as String,openIssueCount: null == openIssueCount ? _self.openIssueCount : openIssueCount // ignore: cast_nullable_to_non_nullable
as num,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as QueueDtoRole,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [QueueDto].
extension QueueDtoPatterns on QueueDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueueDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueueDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueueDto value)  $default,){
final _that = this;
switch (_that) {
case _QueueDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueueDto value)?  $default,){
final _that = this;
switch (_that) {
case _QueueDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String name,  String? description,  String projectSlug,  String projectName,  num openIssueCount,  QueueDtoRole role,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueueDto() when $default != null:
return $default(_that.key,_that.name,_that.description,_that.projectSlug,_that.projectName,_that.openIssueCount,_that.role,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String name,  String? description,  String projectSlug,  String projectName,  num openIssueCount,  QueueDtoRole role,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _QueueDto():
return $default(_that.key,_that.name,_that.description,_that.projectSlug,_that.projectName,_that.openIssueCount,_that.role,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String name,  String? description,  String projectSlug,  String projectName,  num openIssueCount,  QueueDtoRole role,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _QueueDto() when $default != null:
return $default(_that.key,_that.name,_that.description,_that.projectSlug,_that.projectName,_that.openIssueCount,_that.role,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QueueDto implements QueueDto {
  const _QueueDto({required this.key, required this.name, required this.description, required this.projectSlug, required this.projectName, required this.openIssueCount, required this.role, required this.createdAt, required this.updatedAt});
  factory _QueueDto.fromJson(Map<String, dynamic> json) => _$QueueDtoFromJson(json);

/// Ключ очереди. Уникален на весь трекер, неизменяем
@override final  String key;
@override final  String name;
/// Markdown, до 1000 символов
@override final  String? description;
/// Короткое имя проекта в адресе
@override final  String projectSlug;
/// Название проекта для хлебных крошек
@override final  String projectName;
/// Незавершённые задачи: те, чей статус не в категории `done` (US-31)
@override final  num openIssueCount;
/// Роль запросившего в проекте, которому принадлежит очередь. Права на очередь наследуются от проекта: прав уровня очереди в MVP нет (permissions.md, п. 3).
@override final  QueueDtoRole role;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of QueueDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueDtoCopyWith<_QueueDto> get copyWith => __$QueueDtoCopyWithImpl<_QueueDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QueueDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueueDto&&(identical(other.key, key) || other.key == key)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.projectSlug, projectSlug) || other.projectSlug == projectSlug)&&(identical(other.projectName, projectName) || other.projectName == projectName)&&(identical(other.openIssueCount, openIssueCount) || other.openIssueCount == openIssueCount)&&(identical(other.role, role) || other.role == role)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,key,name,description,projectSlug,projectName,openIssueCount,role,createdAt,updatedAt);
}

@override
String toString() {
    return 'QueueDto(key: $key, name: $name, description: $description, projectSlug: $projectSlug, projectName: $projectName, openIssueCount: $openIssueCount, role: $role, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$QueueDtoCopyWith<$Res> implements $QueueDtoCopyWith<$Res> {
  factory _$QueueDtoCopyWith(_QueueDto value, $Res Function(_QueueDto) _then) = __$QueueDtoCopyWithImpl;
@override @useResult
$Res call({
 String key, String name, String? description, String projectSlug, String projectName, num openIssueCount, QueueDtoRole role, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$QueueDtoCopyWithImpl<$Res>
    implements _$QueueDtoCopyWith<$Res> {
  __$QueueDtoCopyWithImpl(this._self, this._then);

  final _QueueDto _self;
  final $Res Function(_QueueDto) _then;

/// Create a copy of QueueDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? name = null,Object? description = freezed,Object? projectSlug = null,Object? projectName = null,Object? openIssueCount = null,Object? role = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_QueueDto(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,projectSlug: null == projectSlug ? _self.projectSlug : projectSlug // ignore: cast_nullable_to_non_nullable
as String,projectName: null == projectName ? _self.projectName : projectName // ignore: cast_nullable_to_non_nullable
as String,openIssueCount: null == openIssueCount ? _self.openIssueCount : openIssueCount // ignore: cast_nullable_to_non_nullable
as num,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as QueueDtoRole,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
