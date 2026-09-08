// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issue_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IssueDto {

/// Публичный ключ задачи, он же адрес
 String get key; String get title;/// Описание в Markdown. Хранится как текст и рендерится клиентом. **Сервер разметку не санитизирует**: клиент обязан рендерить её без исполнения содержимого — сырой HTML и скрипты не исполняются, ссылки со схемами кроме `http`, `https`, `mailto` не становятся кликабельными (D-22, US-43).
 String? get description; IssueStatusFullDto get status;/// Приоритет: 11 значений от 0 до 100 с шагом 10, больше — важнее. Пустым **не бывает никогда**: состояния «не задан» у поля нет, 0 — это «Низкий» (D-15).
 IssueDtoPriority get priority;/// Сложность по шкале Фибоначчи. `null` — «не оценено» (D-16).
 IssueDtoStoryPoints? get storyPoints;/// Автор задачи. Редактируется, пустым не бывает.
 IssueUserDto get author;/// Исполнитель. `null` — «Не назначен».
 IssueUserDto? get assignee; IssueQueueRefDto get queue; IssueProjectRefDto get project;/// Внешние ссылки задачи (US-47)
 List<IssueLinkDto> get links;/// Роль запросившего в проекте задачи
 IssueDtoRole get role; IssuePermissionsDto get permissions; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of IssueDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueDtoCopyWith<IssueDto> get copyWith => _$IssueDtoCopyWithImpl<IssueDto>(this as IssueDto, _$identity);

  /// Serializes this IssueDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IssueDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssueDto&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.priority, _this.priority) || other.priority == _this.priority)&&(identical(other.storyPoints, _this.storyPoints) || other.storyPoints == _this.storyPoints)&&(identical(other.author, _this.author) || other.author == _this.author)&&(identical(other.assignee, _this.assignee) || other.assignee == _this.assignee)&&(identical(other.queue, _this.queue) || other.queue == _this.queue)&&(identical(other.project, _this.project) || other.project == _this.project)&&const DeepCollectionEquality().equals(other.links, _this.links)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.permissions, _this.permissions) || other.permissions == _this.permissions)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IssueDto;
  return Object.hash(runtimeType,_this.key,_this.title,_this.description,_this.status,_this.priority,_this.storyPoints,_this.author,_this.assignee,_this.queue,_this.project,const DeepCollectionEquality().hash(_this.links),_this.role,_this.permissions,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as IssueDto;
  return 'IssueDto(key: ${_this.key}, title: ${_this.title}, description: ${_this.description}, status: ${_this.status}, priority: ${_this.priority}, storyPoints: ${_this.storyPoints}, author: ${_this.author}, assignee: ${_this.assignee}, queue: ${_this.queue}, project: ${_this.project}, links: ${_this.links}, role: ${_this.role}, permissions: ${_this.permissions}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $IssueDtoCopyWith<$Res>  {
  factory $IssueDtoCopyWith(IssueDto value, $Res Function(IssueDto) _then) = _$IssueDtoCopyWithImpl;
@useResult
$Res call({
 String key, String title, String? description, IssueStatusFullDto status, IssueDtoPriority priority, IssueDtoStoryPoints? storyPoints, IssueUserDto author, IssueUserDto? assignee, IssueQueueRefDto queue, IssueProjectRefDto project, List<IssueLinkDto> links, IssueDtoRole role, IssuePermissionsDto permissions, DateTime createdAt, DateTime updatedAt
});


$IssueStatusFullDtoCopyWith<$Res> get status;$IssueUserDtoCopyWith<$Res> get author;$IssueUserDtoCopyWith<$Res>? get assignee;$IssueQueueRefDtoCopyWith<$Res> get queue;$IssueProjectRefDtoCopyWith<$Res> get project;$IssuePermissionsDtoCopyWith<$Res> get permissions;

}
/// @nodoc
class _$IssueDtoCopyWithImpl<$Res>
    implements $IssueDtoCopyWith<$Res> {
  _$IssueDtoCopyWithImpl(this._self, this._then);

  final IssueDto _self;
  final $Res Function(IssueDto) _then;

/// Create a copy of IssueDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? title = null,Object? description = freezed,Object? status = null,Object? priority = null,Object? storyPoints = freezed,Object? author = null,Object? assignee = freezed,Object? queue = null,Object? project = null,Object? links = null,Object? role = null,Object? permissions = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(IssueDto(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IssueStatusFullDto,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as IssueDtoPriority,storyPoints: freezed == storyPoints ? _self.storyPoints : storyPoints // ignore: cast_nullable_to_non_nullable
as IssueDtoStoryPoints?,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as IssueUserDto,assignee: freezed == assignee ? _self.assignee : assignee // ignore: cast_nullable_to_non_nullable
as IssueUserDto?,queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as IssueQueueRefDto,project: null == project ? _self.project : project // ignore: cast_nullable_to_non_nullable
as IssueProjectRefDto,links: null == links ? _self.links : links // ignore: cast_nullable_to_non_nullable
as List<IssueLinkDto>,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as IssueDtoRole,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as IssuePermissionsDto,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of IssueDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueStatusFullDtoCopyWith<$Res> get status {
  
  return $IssueStatusFullDtoCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}/// Create a copy of IssueDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueUserDtoCopyWith<$Res> get author {
  
  return $IssueUserDtoCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of IssueDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueUserDtoCopyWith<$Res>? get assignee {
    if (_self.assignee == null) {
    return null;
  }

  return $IssueUserDtoCopyWith<$Res>(_self.assignee!, (value) {
    return _then(_self.copyWith(assignee: value));
  });
}/// Create a copy of IssueDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueQueueRefDtoCopyWith<$Res> get queue {
  
  return $IssueQueueRefDtoCopyWith<$Res>(_self.queue, (value) {
    return _then(_self.copyWith(queue: value));
  });
}/// Create a copy of IssueDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueProjectRefDtoCopyWith<$Res> get project {
  
  return $IssueProjectRefDtoCopyWith<$Res>(_self.project, (value) {
    return _then(_self.copyWith(project: value));
  });
}/// Create a copy of IssueDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssuePermissionsDtoCopyWith<$Res> get permissions {
  
  return $IssuePermissionsDtoCopyWith<$Res>(_self.permissions, (value) {
    return _then(_self.copyWith(permissions: value));
  });
}
}


/// Adds pattern-matching-related methods to [IssueDto].
extension IssueDtoPatterns on IssueDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssueDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssueDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssueDto value)  $default,){
final _that = this;
switch (_that) {
case _IssueDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssueDto value)?  $default,){
final _that = this;
switch (_that) {
case _IssueDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String title,  String? description,  IssueStatusFullDto status,  IssueDtoPriority priority,  IssueDtoStoryPoints? storyPoints,  IssueUserDto author,  IssueUserDto? assignee,  IssueQueueRefDto queue,  IssueProjectRefDto project,  List<IssueLinkDto> links,  IssueDtoRole role,  IssuePermissionsDto permissions,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssueDto() when $default != null:
return $default(_that.key,_that.title,_that.description,_that.status,_that.priority,_that.storyPoints,_that.author,_that.assignee,_that.queue,_that.project,_that.links,_that.role,_that.permissions,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String title,  String? description,  IssueStatusFullDto status,  IssueDtoPriority priority,  IssueDtoStoryPoints? storyPoints,  IssueUserDto author,  IssueUserDto? assignee,  IssueQueueRefDto queue,  IssueProjectRefDto project,  List<IssueLinkDto> links,  IssueDtoRole role,  IssuePermissionsDto permissions,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _IssueDto():
return $default(_that.key,_that.title,_that.description,_that.status,_that.priority,_that.storyPoints,_that.author,_that.assignee,_that.queue,_that.project,_that.links,_that.role,_that.permissions,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String title,  String? description,  IssueStatusFullDto status,  IssueDtoPriority priority,  IssueDtoStoryPoints? storyPoints,  IssueUserDto author,  IssueUserDto? assignee,  IssueQueueRefDto queue,  IssueProjectRefDto project,  List<IssueLinkDto> links,  IssueDtoRole role,  IssuePermissionsDto permissions,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _IssueDto() when $default != null:
return $default(_that.key,_that.title,_that.description,_that.status,_that.priority,_that.storyPoints,_that.author,_that.assignee,_that.queue,_that.project,_that.links,_that.role,_that.permissions,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssueDto implements IssueDto {
  const _IssueDto({required this.key, required this.title, required this.description, required this.status, required this.priority, required this.storyPoints, required this.author, required this.assignee, required this.queue, required this.project, required  List<IssueLinkDto> links, required this.role, required this.permissions, required this.createdAt, required this.updatedAt}): _links = links;
  factory _IssueDto.fromJson(Map<String, dynamic> json) => _$IssueDtoFromJson(json);

/// Публичный ключ задачи, он же адрес
@override final  String key;
@override final  String title;
/// Описание в Markdown. Хранится как текст и рендерится клиентом. **Сервер разметку не санитизирует**: клиент обязан рендерить её без исполнения содержимого — сырой HTML и скрипты не исполняются, ссылки со схемами кроме `http`, `https`, `mailto` не становятся кликабельными (D-22, US-43).
@override final  String? description;
@override final  IssueStatusFullDto status;
/// Приоритет: 11 значений от 0 до 100 с шагом 10, больше — важнее. Пустым **не бывает никогда**: состояния «не задан» у поля нет, 0 — это «Низкий» (D-15).
@override final  IssueDtoPriority priority;
/// Сложность по шкале Фибоначчи. `null` — «не оценено» (D-16).
@override final  IssueDtoStoryPoints? storyPoints;
/// Автор задачи. Редактируется, пустым не бывает.
@override final  IssueUserDto author;
/// Исполнитель. `null` — «Не назначен».
@override final  IssueUserDto? assignee;
@override final  IssueQueueRefDto queue;
@override final  IssueProjectRefDto project;
/// Внешние ссылки задачи (US-47)
 final  List<IssueLinkDto> _links;
/// Внешние ссылки задачи (US-47)
@override List<IssueLinkDto> get links {
  if (_links is EqualUnmodifiableListView) return _links;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_links);
}

/// Роль запросившего в проекте задачи
@override final  IssueDtoRole role;
@override final  IssuePermissionsDto permissions;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of IssueDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueDtoCopyWith<_IssueDto> get copyWith => __$IssueDtoCopyWithImpl<_IssueDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssueDto&&(identical(other.key, key) || other.key == key)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.storyPoints, storyPoints) || other.storyPoints == storyPoints)&&(identical(other.author, author) || other.author == author)&&(identical(other.assignee, assignee) || other.assignee == assignee)&&(identical(other.queue, queue) || other.queue == queue)&&(identical(other.project, project) || other.project == project)&&const DeepCollectionEquality().equals(other.links, _links)&&(identical(other.role, role) || other.role == role)&&(identical(other.permissions, permissions) || other.permissions == permissions)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,key,title,description,status,priority,storyPoints,author,assignee,queue,project,const DeepCollectionEquality().hash(_links),role,permissions,createdAt,updatedAt);
}

@override
String toString() {
    return 'IssueDto(key: $key, title: $title, description: $description, status: $status, priority: $priority, storyPoints: $storyPoints, author: $author, assignee: $assignee, queue: $queue, project: $project, links: $links, role: $role, permissions: $permissions, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$IssueDtoCopyWith<$Res> implements $IssueDtoCopyWith<$Res> {
  factory _$IssueDtoCopyWith(_IssueDto value, $Res Function(_IssueDto) _then) = __$IssueDtoCopyWithImpl;
@override @useResult
$Res call({
 String key, String title, String? description, IssueStatusFullDto status, IssueDtoPriority priority, IssueDtoStoryPoints? storyPoints, IssueUserDto author, IssueUserDto? assignee, IssueQueueRefDto queue, IssueProjectRefDto project, List<IssueLinkDto> links, IssueDtoRole role, IssuePermissionsDto permissions, DateTime createdAt, DateTime updatedAt
});


@override $IssueStatusFullDtoCopyWith<$Res> get status;@override $IssueUserDtoCopyWith<$Res> get author;@override $IssueUserDtoCopyWith<$Res>? get assignee;@override $IssueQueueRefDtoCopyWith<$Res> get queue;@override $IssueProjectRefDtoCopyWith<$Res> get project;@override $IssuePermissionsDtoCopyWith<$Res> get permissions;

}
/// @nodoc
class __$IssueDtoCopyWithImpl<$Res>
    implements _$IssueDtoCopyWith<$Res> {
  __$IssueDtoCopyWithImpl(this._self, this._then);

  final _IssueDto _self;
  final $Res Function(_IssueDto) _then;

/// Create a copy of IssueDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? title = null,Object? description = freezed,Object? status = null,Object? priority = null,Object? storyPoints = freezed,Object? author = null,Object? assignee = freezed,Object? queue = null,Object? project = null,Object? links = null,Object? role = null,Object? permissions = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_IssueDto(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IssueStatusFullDto,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as IssueDtoPriority,storyPoints: freezed == storyPoints ? _self.storyPoints : storyPoints // ignore: cast_nullable_to_non_nullable
as IssueDtoStoryPoints?,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as IssueUserDto,assignee: freezed == assignee ? _self.assignee : assignee // ignore: cast_nullable_to_non_nullable
as IssueUserDto?,queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as IssueQueueRefDto,project: null == project ? _self.project : project // ignore: cast_nullable_to_non_nullable
as IssueProjectRefDto,links: null == links ? _self._links : links // ignore: cast_nullable_to_non_nullable
as List<IssueLinkDto>,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as IssueDtoRole,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as IssuePermissionsDto,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of IssueDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueStatusFullDtoCopyWith<$Res> get status {
  
  return $IssueStatusFullDtoCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}/// Create a copy of IssueDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueUserDtoCopyWith<$Res> get author {
  
  return $IssueUserDtoCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of IssueDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueUserDtoCopyWith<$Res>? get assignee {
    if (_self.assignee == null) {
    return null;
  }

  return $IssueUserDtoCopyWith<$Res>(_self.assignee!, (value) {
    return _then(_self.copyWith(assignee: value));
  });
}/// Create a copy of IssueDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueQueueRefDtoCopyWith<$Res> get queue {
  
  return $IssueQueueRefDtoCopyWith<$Res>(_self.queue, (value) {
    return _then(_self.copyWith(queue: value));
  });
}/// Create a copy of IssueDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueProjectRefDtoCopyWith<$Res> get project {
  
  return $IssueProjectRefDtoCopyWith<$Res>(_self.project, (value) {
    return _then(_self.copyWith(project: value));
  });
}/// Create a copy of IssueDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssuePermissionsDtoCopyWith<$Res> get permissions {
  
  return $IssuePermissionsDtoCopyWith<$Res>(_self.permissions, (value) {
    return _then(_self.copyWith(permissions: value));
  });
}
}

// dart format on
