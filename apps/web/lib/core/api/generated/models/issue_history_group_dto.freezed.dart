// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issue_history_group_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IssueHistoryGroupDto {

/// Идентификатор группы изменений
 String get id; DateTime get createdAt;/// `null` — изменение системное, а не человеческое (например, очистка исполнителя при исключении участника из проекта). Интерфейс показывает его как «Система», а не приписывает случайному пользователю (US-91).
 IssueUserDto? get actor; List<IssueHistoryChangeDto> get changes;
/// Create a copy of IssueHistoryGroupDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueHistoryGroupDtoCopyWith<IssueHistoryGroupDto> get copyWith => _$IssueHistoryGroupDtoCopyWithImpl<IssueHistoryGroupDto>(this as IssueHistoryGroupDto, _$identity);

  /// Serializes this IssueHistoryGroupDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IssueHistoryGroupDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssueHistoryGroupDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.actor, _this.actor) || other.actor == _this.actor)&&const DeepCollectionEquality().equals(other.changes, _this.changes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IssueHistoryGroupDto;
  return Object.hash(runtimeType,_this.id,_this.createdAt,_this.actor,const DeepCollectionEquality().hash(_this.changes));
}

@override
String toString() {
  final _this = this as IssueHistoryGroupDto;
  return 'IssueHistoryGroupDto(id: ${_this.id}, createdAt: ${_this.createdAt}, actor: ${_this.actor}, changes: ${_this.changes})';
}


}

/// @nodoc
abstract mixin class $IssueHistoryGroupDtoCopyWith<$Res>  {
  factory $IssueHistoryGroupDtoCopyWith(IssueHistoryGroupDto value, $Res Function(IssueHistoryGroupDto) _then) = _$IssueHistoryGroupDtoCopyWithImpl;
@useResult
$Res call({
 String id, DateTime createdAt, IssueUserDto? actor, List<IssueHistoryChangeDto> changes
});


$IssueUserDtoCopyWith<$Res>? get actor;

}
/// @nodoc
class _$IssueHistoryGroupDtoCopyWithImpl<$Res>
    implements $IssueHistoryGroupDtoCopyWith<$Res> {
  _$IssueHistoryGroupDtoCopyWithImpl(this._self, this._then);

  final IssueHistoryGroupDto _self;
  final $Res Function(IssueHistoryGroupDto) _then;

/// Create a copy of IssueHistoryGroupDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? createdAt = null,Object? actor = freezed,Object? changes = null,}) {
  return _then(IssueHistoryGroupDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,actor: freezed == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as IssueUserDto?,changes: null == changes ? _self.changes : changes // ignore: cast_nullable_to_non_nullable
as List<IssueHistoryChangeDto>,
  ));
}
/// Create a copy of IssueHistoryGroupDto
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
}
}


/// Adds pattern-matching-related methods to [IssueHistoryGroupDto].
extension IssueHistoryGroupDtoPatterns on IssueHistoryGroupDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssueHistoryGroupDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssueHistoryGroupDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssueHistoryGroupDto value)  $default,){
final _that = this;
switch (_that) {
case _IssueHistoryGroupDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssueHistoryGroupDto value)?  $default,){
final _that = this;
switch (_that) {
case _IssueHistoryGroupDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime createdAt,  IssueUserDto? actor,  List<IssueHistoryChangeDto> changes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssueHistoryGroupDto() when $default != null:
return $default(_that.id,_that.createdAt,_that.actor,_that.changes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime createdAt,  IssueUserDto? actor,  List<IssueHistoryChangeDto> changes)  $default,) {final _that = this;
switch (_that) {
case _IssueHistoryGroupDto():
return $default(_that.id,_that.createdAt,_that.actor,_that.changes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime createdAt,  IssueUserDto? actor,  List<IssueHistoryChangeDto> changes)?  $default,) {final _that = this;
switch (_that) {
case _IssueHistoryGroupDto() when $default != null:
return $default(_that.id,_that.createdAt,_that.actor,_that.changes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssueHistoryGroupDto implements IssueHistoryGroupDto {
  const _IssueHistoryGroupDto({required this.id, required this.createdAt, required this.actor, required  List<IssueHistoryChangeDto> changes}): _changes = changes;
  factory _IssueHistoryGroupDto.fromJson(Map<String, dynamic> json) => _$IssueHistoryGroupDtoFromJson(json);

/// Идентификатор группы изменений
@override final  String id;
@override final  DateTime createdAt;
/// `null` — изменение системное, а не человеческое (например, очистка исполнителя при исключении участника из проекта). Интерфейс показывает его как «Система», а не приписывает случайному пользователю (US-91).
@override final  IssueUserDto? actor;
 final  List<IssueHistoryChangeDto> _changes;
@override List<IssueHistoryChangeDto> get changes {
  if (_changes is EqualUnmodifiableListView) return _changes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_changes);
}


/// Create a copy of IssueHistoryGroupDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueHistoryGroupDtoCopyWith<_IssueHistoryGroupDto> get copyWith => __$IssueHistoryGroupDtoCopyWithImpl<_IssueHistoryGroupDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueHistoryGroupDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssueHistoryGroupDto&&(identical(other.id, id) || other.id == id)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.actor, actor) || other.actor == actor)&&const DeepCollectionEquality().equals(other.changes, _changes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,createdAt,actor,const DeepCollectionEquality().hash(_changes));
}

@override
String toString() {
    return 'IssueHistoryGroupDto(id: $id, createdAt: $createdAt, actor: $actor, changes: $changes)';
}


}

/// @nodoc
abstract mixin class _$IssueHistoryGroupDtoCopyWith<$Res> implements $IssueHistoryGroupDtoCopyWith<$Res> {
  factory _$IssueHistoryGroupDtoCopyWith(_IssueHistoryGroupDto value, $Res Function(_IssueHistoryGroupDto) _then) = __$IssueHistoryGroupDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime createdAt, IssueUserDto? actor, List<IssueHistoryChangeDto> changes
});


@override $IssueUserDtoCopyWith<$Res>? get actor;

}
/// @nodoc
class __$IssueHistoryGroupDtoCopyWithImpl<$Res>
    implements _$IssueHistoryGroupDtoCopyWith<$Res> {
  __$IssueHistoryGroupDtoCopyWithImpl(this._self, this._then);

  final _IssueHistoryGroupDto _self;
  final $Res Function(_IssueHistoryGroupDto) _then;

/// Create a copy of IssueHistoryGroupDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? createdAt = null,Object? actor = freezed,Object? changes = null,}) {
  return _then(_IssueHistoryGroupDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,actor: freezed == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as IssueUserDto?,changes: null == changes ? _self._changes : changes // ignore: cast_nullable_to_non_nullable
as List<IssueHistoryChangeDto>,
  ));
}

/// Create a copy of IssueHistoryGroupDto
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
}
}

// dart format on
