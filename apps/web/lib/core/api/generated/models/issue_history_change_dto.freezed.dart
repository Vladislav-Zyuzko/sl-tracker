// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issue_history_change_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IssueHistoryChangeDto {

 String get id;/// Что изменилось. `issue_created` — создание задачи; эта запись всегда самая ранняя и показывает **реального создателя**, даже если поле «Автор» потом меняли (D-13). У `description_changed` значений нет: фиксируется только факт изменения, старый текст не хранится (US-91).
 IssueHistoryChangeDtoKind get kind;/// Читаемое старое значение на момент изменения — имя человека, название статуса, число. `null` означает «пусто»: «не назначен» у исполнителя, «не оценено» у сложности (US-91).
 String? get oldValue;/// Читаемое новое значение
 String? get newValue;/// Идентификатор прежнего объекта (пользователя или статуса) — для аватара и ссылки
 String? get oldRefId; String? get newRefId;
/// Create a copy of IssueHistoryChangeDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueHistoryChangeDtoCopyWith<IssueHistoryChangeDto> get copyWith => _$IssueHistoryChangeDtoCopyWithImpl<IssueHistoryChangeDto>(this as IssueHistoryChangeDto, _$identity);

  /// Serializes this IssueHistoryChangeDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IssueHistoryChangeDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssueHistoryChangeDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.oldValue, _this.oldValue) || other.oldValue == _this.oldValue)&&(identical(other.newValue, _this.newValue) || other.newValue == _this.newValue)&&(identical(other.oldRefId, _this.oldRefId) || other.oldRefId == _this.oldRefId)&&(identical(other.newRefId, _this.newRefId) || other.newRefId == _this.newRefId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IssueHistoryChangeDto;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.oldValue,_this.newValue,_this.oldRefId,_this.newRefId);
}

@override
String toString() {
  final _this = this as IssueHistoryChangeDto;
  return 'IssueHistoryChangeDto(id: ${_this.id}, kind: ${_this.kind}, oldValue: ${_this.oldValue}, newValue: ${_this.newValue}, oldRefId: ${_this.oldRefId}, newRefId: ${_this.newRefId})';
}


}

/// @nodoc
abstract mixin class $IssueHistoryChangeDtoCopyWith<$Res>  {
  factory $IssueHistoryChangeDtoCopyWith(IssueHistoryChangeDto value, $Res Function(IssueHistoryChangeDto) _then) = _$IssueHistoryChangeDtoCopyWithImpl;
@useResult
$Res call({
 String id, IssueHistoryChangeDtoKind kind, String? oldValue, String? newValue, String? oldRefId, String? newRefId
});




}
/// @nodoc
class _$IssueHistoryChangeDtoCopyWithImpl<$Res>
    implements $IssueHistoryChangeDtoCopyWith<$Res> {
  _$IssueHistoryChangeDtoCopyWithImpl(this._self, this._then);

  final IssueHistoryChangeDto _self;
  final $Res Function(IssueHistoryChangeDto) _then;

/// Create a copy of IssueHistoryChangeDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? oldValue = freezed,Object? newValue = freezed,Object? oldRefId = freezed,Object? newRefId = freezed,}) {
  return _then(IssueHistoryChangeDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as IssueHistoryChangeDtoKind,oldValue: freezed == oldValue ? _self.oldValue : oldValue // ignore: cast_nullable_to_non_nullable
as String?,newValue: freezed == newValue ? _self.newValue : newValue // ignore: cast_nullable_to_non_nullable
as String?,oldRefId: freezed == oldRefId ? _self.oldRefId : oldRefId // ignore: cast_nullable_to_non_nullable
as String?,newRefId: freezed == newRefId ? _self.newRefId : newRefId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [IssueHistoryChangeDto].
extension IssueHistoryChangeDtoPatterns on IssueHistoryChangeDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssueHistoryChangeDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssueHistoryChangeDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssueHistoryChangeDto value)  $default,){
final _that = this;
switch (_that) {
case _IssueHistoryChangeDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssueHistoryChangeDto value)?  $default,){
final _that = this;
switch (_that) {
case _IssueHistoryChangeDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  IssueHistoryChangeDtoKind kind,  String? oldValue,  String? newValue,  String? oldRefId,  String? newRefId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssueHistoryChangeDto() when $default != null:
return $default(_that.id,_that.kind,_that.oldValue,_that.newValue,_that.oldRefId,_that.newRefId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  IssueHistoryChangeDtoKind kind,  String? oldValue,  String? newValue,  String? oldRefId,  String? newRefId)  $default,) {final _that = this;
switch (_that) {
case _IssueHistoryChangeDto():
return $default(_that.id,_that.kind,_that.oldValue,_that.newValue,_that.oldRefId,_that.newRefId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  IssueHistoryChangeDtoKind kind,  String? oldValue,  String? newValue,  String? oldRefId,  String? newRefId)?  $default,) {final _that = this;
switch (_that) {
case _IssueHistoryChangeDto() when $default != null:
return $default(_that.id,_that.kind,_that.oldValue,_that.newValue,_that.oldRefId,_that.newRefId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssueHistoryChangeDto implements IssueHistoryChangeDto {
  const _IssueHistoryChangeDto({required this.id, required this.kind, required this.oldValue, required this.newValue, required this.oldRefId, required this.newRefId});
  factory _IssueHistoryChangeDto.fromJson(Map<String, dynamic> json) => _$IssueHistoryChangeDtoFromJson(json);

@override final  String id;
/// Что изменилось. `issue_created` — создание задачи; эта запись всегда самая ранняя и показывает **реального создателя**, даже если поле «Автор» потом меняли (D-13). У `description_changed` значений нет: фиксируется только факт изменения, старый текст не хранится (US-91).
@override final  IssueHistoryChangeDtoKind kind;
/// Читаемое старое значение на момент изменения — имя человека, название статуса, число. `null` означает «пусто»: «не назначен» у исполнителя, «не оценено» у сложности (US-91).
@override final  String? oldValue;
/// Читаемое новое значение
@override final  String? newValue;
/// Идентификатор прежнего объекта (пользователя или статуса) — для аватара и ссылки
@override final  String? oldRefId;
@override final  String? newRefId;

/// Create a copy of IssueHistoryChangeDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueHistoryChangeDtoCopyWith<_IssueHistoryChangeDto> get copyWith => __$IssueHistoryChangeDtoCopyWithImpl<_IssueHistoryChangeDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueHistoryChangeDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssueHistoryChangeDto&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.oldValue, oldValue) || other.oldValue == oldValue)&&(identical(other.newValue, newValue) || other.newValue == newValue)&&(identical(other.oldRefId, oldRefId) || other.oldRefId == oldRefId)&&(identical(other.newRefId, newRefId) || other.newRefId == newRefId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,oldValue,newValue,oldRefId,newRefId);
}

@override
String toString() {
    return 'IssueHistoryChangeDto(id: $id, kind: $kind, oldValue: $oldValue, newValue: $newValue, oldRefId: $oldRefId, newRefId: $newRefId)';
}


}

/// @nodoc
abstract mixin class _$IssueHistoryChangeDtoCopyWith<$Res> implements $IssueHistoryChangeDtoCopyWith<$Res> {
  factory _$IssueHistoryChangeDtoCopyWith(_IssueHistoryChangeDto value, $Res Function(_IssueHistoryChangeDto) _then) = __$IssueHistoryChangeDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, IssueHistoryChangeDtoKind kind, String? oldValue, String? newValue, String? oldRefId, String? newRefId
});




}
/// @nodoc
class __$IssueHistoryChangeDtoCopyWithImpl<$Res>
    implements _$IssueHistoryChangeDtoCopyWith<$Res> {
  __$IssueHistoryChangeDtoCopyWithImpl(this._self, this._then);

  final _IssueHistoryChangeDto _self;
  final $Res Function(_IssueHistoryChangeDto) _then;

/// Create a copy of IssueHistoryChangeDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? oldValue = freezed,Object? newValue = freezed,Object? oldRefId = freezed,Object? newRefId = freezed,}) {
  return _then(_IssueHistoryChangeDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as IssueHistoryChangeDtoKind,oldValue: freezed == oldValue ? _self.oldValue : oldValue // ignore: cast_nullable_to_non_nullable
as String?,newValue: freezed == newValue ? _self.newValue : newValue // ignore: cast_nullable_to_non_nullable
as String?,oldRefId: freezed == oldRefId ? _self.oldRefId : oldRefId // ignore: cast_nullable_to_non_nullable
as String?,newRefId: freezed == newRefId ? _self.newRefId : newRefId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
