// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectDto {

 String get id;/// Действующее короткое имя в адресе. Если проект запрошен по прежнему короткому имени, здесь всё равно действующее — клиенту следует заменить адрес в строке браузера на него (US-18).
 String get slug; String get name;/// Markdown, до 5000 символов
 String? get description;/// Подписанная ссылка на обложку со сроком жизни 10 минут. Бакет не публичный: ссылка без подписи содержимое не отдаёт. `null` — обложки нет, клиент рисует заглушку.
 String? get coverUrl;/// Роль текущего пользователя в этом проекте (permissions.md, 2.1).
 ProjectDtoRole get role;/// Сколько всего участников в проекте
 num get memberCount;/// Первые участники для группы аватаров: администраторы, затем по имени.
 List<ProjectMemberPreviewDto> get members; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of ProjectDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectDtoCopyWith<ProjectDto> get copyWith => _$ProjectDtoCopyWithImpl<ProjectDto>(this as ProjectDto, _$identity);

  /// Serializes this ProjectDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProjectDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.slug, _this.slug) || other.slug == _this.slug)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.coverUrl, _this.coverUrl) || other.coverUrl == _this.coverUrl)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.memberCount, _this.memberCount) || other.memberCount == _this.memberCount)&&const DeepCollectionEquality().equals(other.members, _this.members)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProjectDto;
  return Object.hash(runtimeType,_this.id,_this.slug,_this.name,_this.description,_this.coverUrl,_this.role,_this.memberCount,const DeepCollectionEquality().hash(_this.members),_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as ProjectDto;
  return 'ProjectDto(id: ${_this.id}, slug: ${_this.slug}, name: ${_this.name}, description: ${_this.description}, coverUrl: ${_this.coverUrl}, role: ${_this.role}, memberCount: ${_this.memberCount}, members: ${_this.members}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $ProjectDtoCopyWith<$Res>  {
  factory $ProjectDtoCopyWith(ProjectDto value, $Res Function(ProjectDto) _then) = _$ProjectDtoCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String name, String? description, String? coverUrl, ProjectDtoRole role, num memberCount, List<ProjectMemberPreviewDto> members, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$ProjectDtoCopyWithImpl<$Res>
    implements $ProjectDtoCopyWith<$Res> {
  _$ProjectDtoCopyWithImpl(this._self, this._then);

  final ProjectDto _self;
  final $Res Function(ProjectDto) _then;

/// Create a copy of ProjectDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? description = freezed,Object? coverUrl = freezed,Object? role = null,Object? memberCount = null,Object? members = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(ProjectDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ProjectDtoRole,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as num,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<ProjectMemberPreviewDto>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectDto].
extension ProjectDtoPatterns on ProjectDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectDto value)  $default,){
final _that = this;
switch (_that) {
case _ProjectDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String name,  String? description,  String? coverUrl,  ProjectDtoRole role,  num memberCount,  List<ProjectMemberPreviewDto> members,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectDto() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.description,_that.coverUrl,_that.role,_that.memberCount,_that.members,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String name,  String? description,  String? coverUrl,  ProjectDtoRole role,  num memberCount,  List<ProjectMemberPreviewDto> members,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ProjectDto():
return $default(_that.id,_that.slug,_that.name,_that.description,_that.coverUrl,_that.role,_that.memberCount,_that.members,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String name,  String? description,  String? coverUrl,  ProjectDtoRole role,  num memberCount,  List<ProjectMemberPreviewDto> members,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ProjectDto() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.description,_that.coverUrl,_that.role,_that.memberCount,_that.members,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectDto implements ProjectDto {
  const _ProjectDto({required this.id, required this.slug, required this.name, required this.description, required this.coverUrl, required this.role, required this.memberCount, required  List<ProjectMemberPreviewDto> members, required this.createdAt, required this.updatedAt}): _members = members;
  factory _ProjectDto.fromJson(Map<String, dynamic> json) => _$ProjectDtoFromJson(json);

@override final  String id;
/// Действующее короткое имя в адресе. Если проект запрошен по прежнему короткому имени, здесь всё равно действующее — клиенту следует заменить адрес в строке браузера на него (US-18).
@override final  String slug;
@override final  String name;
/// Markdown, до 5000 символов
@override final  String? description;
/// Подписанная ссылка на обложку со сроком жизни 10 минут. Бакет не публичный: ссылка без подписи содержимое не отдаёт. `null` — обложки нет, клиент рисует заглушку.
@override final  String? coverUrl;
/// Роль текущего пользователя в этом проекте (permissions.md, 2.1).
@override final  ProjectDtoRole role;
/// Сколько всего участников в проекте
@override final  num memberCount;
/// Первые участники для группы аватаров: администраторы, затем по имени.
 final  List<ProjectMemberPreviewDto> _members;
/// Первые участники для группы аватаров: администраторы, затем по имени.
@override List<ProjectMemberPreviewDto> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of ProjectDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectDtoCopyWith<_ProjectDto> get copyWith => __$ProjectDtoCopyWithImpl<_ProjectDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDto&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.role, role) || other.role == role)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&const DeepCollectionEquality().equals(other.members, _members)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,slug,name,description,coverUrl,role,memberCount,const DeepCollectionEquality().hash(_members),createdAt,updatedAt);
}

@override
String toString() {
    return 'ProjectDto(id: $id, slug: $slug, name: $name, description: $description, coverUrl: $coverUrl, role: $role, memberCount: $memberCount, members: $members, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ProjectDtoCopyWith<$Res> implements $ProjectDtoCopyWith<$Res> {
  factory _$ProjectDtoCopyWith(_ProjectDto value, $Res Function(_ProjectDto) _then) = __$ProjectDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String name, String? description, String? coverUrl, ProjectDtoRole role, num memberCount, List<ProjectMemberPreviewDto> members, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$ProjectDtoCopyWithImpl<$Res>
    implements _$ProjectDtoCopyWith<$Res> {
  __$ProjectDtoCopyWithImpl(this._self, this._then);

  final _ProjectDto _self;
  final $Res Function(_ProjectDto) _then;

/// Create a copy of ProjectDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? description = freezed,Object? coverUrl = freezed,Object? role = null,Object? memberCount = null,Object? members = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_ProjectDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,coverUrl: freezed == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ProjectDtoRole,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as num,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<ProjectMemberPreviewDto>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
