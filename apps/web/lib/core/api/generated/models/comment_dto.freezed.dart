// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CommentDto {

 String get id;/// Текст в Markdown, как есть. Упоминания записаны токеном `@[Имя](user:<uuid>)`; актуальные имена и аватары упомянутых — в поле `mentions`, а токен, которому там ничего не соответствует, показывается **обычным текстом** (US-74).
///
/// **Сервер разметку не санитизирует**: клиент обязан рендерить её без исполнения содержимого (D-22).
 String get body;/// Автор: имя и аватар приезжают сразу
 IssueUserDto get author;/// Упомянутые в тексте участники проекта — **актуальные** имена и аватары: человек сменил имя в Яндекс ID, и оно поменялось во всех старых комментариях (US-74). Упоминание того, кто не состоит в проекте, сюда не попадает никогда (D-41).
 List<IssueUserDto> get mentions;/// Когда комментарий правили. Не `null` — в ленте помечается «изменён» (US-72).
 DateTime? get editedAt; DateTime get createdAt; CommentPermissionsDto get permissions;
/// Create a copy of CommentDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentDtoCopyWith<CommentDto> get copyWith => _$CommentDtoCopyWithImpl<CommentDto>(this as CommentDto, _$identity);

  /// Serializes this CommentDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CommentDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.author, _this.author) || other.author == _this.author)&&const DeepCollectionEquality().equals(other.mentions, _this.mentions)&&(identical(other.editedAt, _this.editedAt) || other.editedAt == _this.editedAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.permissions, _this.permissions) || other.permissions == _this.permissions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CommentDto;
  return Object.hash(runtimeType,_this.id,_this.body,_this.author,const DeepCollectionEquality().hash(_this.mentions),_this.editedAt,_this.createdAt,_this.permissions);
}

@override
String toString() {
  final _this = this as CommentDto;
  return 'CommentDto(id: ${_this.id}, body: ${_this.body}, author: ${_this.author}, mentions: ${_this.mentions}, editedAt: ${_this.editedAt}, createdAt: ${_this.createdAt}, permissions: ${_this.permissions})';
}


}

/// @nodoc
abstract mixin class $CommentDtoCopyWith<$Res>  {
  factory $CommentDtoCopyWith(CommentDto value, $Res Function(CommentDto) _then) = _$CommentDtoCopyWithImpl;
@useResult
$Res call({
 String id, String body, IssueUserDto author, List<IssueUserDto> mentions, DateTime? editedAt, DateTime createdAt, CommentPermissionsDto permissions
});


$IssueUserDtoCopyWith<$Res> get author;$CommentPermissionsDtoCopyWith<$Res> get permissions;

}
/// @nodoc
class _$CommentDtoCopyWithImpl<$Res>
    implements $CommentDtoCopyWith<$Res> {
  _$CommentDtoCopyWithImpl(this._self, this._then);

  final CommentDto _self;
  final $Res Function(CommentDto) _then;

/// Create a copy of CommentDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? body = null,Object? author = null,Object? mentions = null,Object? editedAt = freezed,Object? createdAt = null,Object? permissions = null,}) {
  return _then(CommentDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as IssueUserDto,mentions: null == mentions ? _self.mentions : mentions // ignore: cast_nullable_to_non_nullable
as List<IssueUserDto>,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as CommentPermissionsDto,
  ));
}
/// Create a copy of CommentDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueUserDtoCopyWith<$Res> get author {
  
  return $IssueUserDtoCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of CommentDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommentPermissionsDtoCopyWith<$Res> get permissions {
  
  return $CommentPermissionsDtoCopyWith<$Res>(_self.permissions, (value) {
    return _then(_self.copyWith(permissions: value));
  });
}
}


/// Adds pattern-matching-related methods to [CommentDto].
extension CommentDtoPatterns on CommentDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentDto value)  $default,){
final _that = this;
switch (_that) {
case _CommentDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentDto value)?  $default,){
final _that = this;
switch (_that) {
case _CommentDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String body,  IssueUserDto author,  List<IssueUserDto> mentions,  DateTime? editedAt,  DateTime createdAt,  CommentPermissionsDto permissions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentDto() when $default != null:
return $default(_that.id,_that.body,_that.author,_that.mentions,_that.editedAt,_that.createdAt,_that.permissions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String body,  IssueUserDto author,  List<IssueUserDto> mentions,  DateTime? editedAt,  DateTime createdAt,  CommentPermissionsDto permissions)  $default,) {final _that = this;
switch (_that) {
case _CommentDto():
return $default(_that.id,_that.body,_that.author,_that.mentions,_that.editedAt,_that.createdAt,_that.permissions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String body,  IssueUserDto author,  List<IssueUserDto> mentions,  DateTime? editedAt,  DateTime createdAt,  CommentPermissionsDto permissions)?  $default,) {final _that = this;
switch (_that) {
case _CommentDto() when $default != null:
return $default(_that.id,_that.body,_that.author,_that.mentions,_that.editedAt,_that.createdAt,_that.permissions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentDto implements CommentDto {
  const _CommentDto({required this.id, required this.body, required this.author, required  List<IssueUserDto> mentions, required this.editedAt, required this.createdAt, required this.permissions}): _mentions = mentions;
  factory _CommentDto.fromJson(Map<String, dynamic> json) => _$CommentDtoFromJson(json);

@override final  String id;
/// Текст в Markdown, как есть. Упоминания записаны токеном `@[Имя](user:<uuid>)`; актуальные имена и аватары упомянутых — в поле `mentions`, а токен, которому там ничего не соответствует, показывается **обычным текстом** (US-74).
///
/// **Сервер разметку не санитизирует**: клиент обязан рендерить её без исполнения содержимого (D-22).
@override final  String body;
/// Автор: имя и аватар приезжают сразу
@override final  IssueUserDto author;
/// Упомянутые в тексте участники проекта — **актуальные** имена и аватары: человек сменил имя в Яндекс ID, и оно поменялось во всех старых комментариях (US-74). Упоминание того, кто не состоит в проекте, сюда не попадает никогда (D-41).
 final  List<IssueUserDto> _mentions;
/// Упомянутые в тексте участники проекта — **актуальные** имена и аватары: человек сменил имя в Яндекс ID, и оно поменялось во всех старых комментариях (US-74). Упоминание того, кто не состоит в проекте, сюда не попадает никогда (D-41).
@override List<IssueUserDto> get mentions {
  if (_mentions is EqualUnmodifiableListView) return _mentions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mentions);
}

/// Когда комментарий правили. Не `null` — в ленте помечается «изменён» (US-72).
@override final  DateTime? editedAt;
@override final  DateTime createdAt;
@override final  CommentPermissionsDto permissions;

/// Create a copy of CommentDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentDtoCopyWith<_CommentDto> get copyWith => __$CommentDtoCopyWithImpl<_CommentDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentDto&&(identical(other.id, id) || other.id == id)&&(identical(other.body, body) || other.body == body)&&(identical(other.author, author) || other.author == author)&&const DeepCollectionEquality().equals(other.mentions, _mentions)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.permissions, permissions) || other.permissions == permissions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,body,author,const DeepCollectionEquality().hash(_mentions),editedAt,createdAt,permissions);
}

@override
String toString() {
    return 'CommentDto(id: $id, body: $body, author: $author, mentions: $mentions, editedAt: $editedAt, createdAt: $createdAt, permissions: $permissions)';
}


}

/// @nodoc
abstract mixin class _$CommentDtoCopyWith<$Res> implements $CommentDtoCopyWith<$Res> {
  factory _$CommentDtoCopyWith(_CommentDto value, $Res Function(_CommentDto) _then) = __$CommentDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String body, IssueUserDto author, List<IssueUserDto> mentions, DateTime? editedAt, DateTime createdAt, CommentPermissionsDto permissions
});


@override $IssueUserDtoCopyWith<$Res> get author;@override $CommentPermissionsDtoCopyWith<$Res> get permissions;

}
/// @nodoc
class __$CommentDtoCopyWithImpl<$Res>
    implements _$CommentDtoCopyWith<$Res> {
  __$CommentDtoCopyWithImpl(this._self, this._then);

  final _CommentDto _self;
  final $Res Function(_CommentDto) _then;

/// Create a copy of CommentDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? body = null,Object? author = null,Object? mentions = null,Object? editedAt = freezed,Object? createdAt = null,Object? permissions = null,}) {
  return _then(_CommentDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as IssueUserDto,mentions: null == mentions ? _self._mentions : mentions // ignore: cast_nullable_to_non_nullable
as List<IssueUserDto>,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as CommentPermissionsDto,
  ));
}

/// Create a copy of CommentDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueUserDtoCopyWith<$Res> get author {
  
  return $IssueUserDtoCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of CommentDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommentPermissionsDtoCopyWith<$Res> get permissions {
  
  return $CommentPermissionsDtoCopyWith<$Res>(_self.permissions, (value) {
    return _then(_self.copyWith(permissions: value));
  });
}
}

// dart format on
