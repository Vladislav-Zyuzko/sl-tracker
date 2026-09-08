// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issue_list_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IssueListDto {

 List<IssueRowDto> get items;/// Курсор следующей порции. `null` — задачи кончились.
 String? get nextCursor;/// Сколько задач подходит под текущие фильтры — счётчик «Показано N».
 num get total;/// Роль запросившего в проекте очереди: по ней прячется кнопка «Создать задачу».
 IssueListDtoRole? get role;
/// Create a copy of IssueListDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueListDtoCopyWith<IssueListDto> get copyWith => _$IssueListDtoCopyWithImpl<IssueListDto>(this as IssueListDto, _$identity);

  /// Serializes this IssueListDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IssueListDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssueListDto&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor)&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.role, _this.role) || other.role == _this.role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IssueListDto;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.nextCursor,_this.total,_this.role);
}

@override
String toString() {
  final _this = this as IssueListDto;
  return 'IssueListDto(items: ${_this.items}, nextCursor: ${_this.nextCursor}, total: ${_this.total}, role: ${_this.role})';
}


}

/// @nodoc
abstract mixin class $IssueListDtoCopyWith<$Res>  {
  factory $IssueListDtoCopyWith(IssueListDto value, $Res Function(IssueListDto) _then) = _$IssueListDtoCopyWithImpl;
@useResult
$Res call({
 List<IssueRowDto> items, String? nextCursor, num total, IssueListDtoRole? role
});




}
/// @nodoc
class _$IssueListDtoCopyWithImpl<$Res>
    implements $IssueListDtoCopyWith<$Res> {
  _$IssueListDtoCopyWithImpl(this._self, this._then);

  final IssueListDto _self;
  final $Res Function(IssueListDto) _then;

/// Create a copy of IssueListDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,Object? total = null,Object? role = freezed,}) {
  return _then(IssueListDto(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<IssueRowDto>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as IssueListDtoRole?,
  ));
}

}


/// Adds pattern-matching-related methods to [IssueListDto].
extension IssueListDtoPatterns on IssueListDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssueListDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssueListDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssueListDto value)  $default,){
final _that = this;
switch (_that) {
case _IssueListDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssueListDto value)?  $default,){
final _that = this;
switch (_that) {
case _IssueListDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<IssueRowDto> items,  String? nextCursor,  num total,  IssueListDtoRole? role)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssueListDto() when $default != null:
return $default(_that.items,_that.nextCursor,_that.total,_that.role);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<IssueRowDto> items,  String? nextCursor,  num total,  IssueListDtoRole? role)  $default,) {final _that = this;
switch (_that) {
case _IssueListDto():
return $default(_that.items,_that.nextCursor,_that.total,_that.role);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<IssueRowDto> items,  String? nextCursor,  num total,  IssueListDtoRole? role)?  $default,) {final _that = this;
switch (_that) {
case _IssueListDto() when $default != null:
return $default(_that.items,_that.nextCursor,_that.total,_that.role);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssueListDto implements IssueListDto {
  const _IssueListDto({required  List<IssueRowDto> items, required this.nextCursor, required this.total, this.role}): _items = items;
  factory _IssueListDto.fromJson(Map<String, dynamic> json) => _$IssueListDtoFromJson(json);

 final  List<IssueRowDto> _items;
@override List<IssueRowDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Курсор следующей порции. `null` — задачи кончились.
@override final  String? nextCursor;
/// Сколько задач подходит под текущие фильтры — счётчик «Показано N».
@override final  num total;
/// Роль запросившего в проекте очереди: по ней прячется кнопка «Создать задачу».
@override final  IssueListDtoRole? role;

/// Create a copy of IssueListDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueListDtoCopyWith<_IssueListDto> get copyWith => __$IssueListDtoCopyWithImpl<_IssueListDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueListDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssueListDto&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.total, total) || other.total == total)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor,total,role);
}

@override
String toString() {
    return 'IssueListDto(items: $items, nextCursor: $nextCursor, total: $total, role: $role)';
}


}

/// @nodoc
abstract mixin class _$IssueListDtoCopyWith<$Res> implements $IssueListDtoCopyWith<$Res> {
  factory _$IssueListDtoCopyWith(_IssueListDto value, $Res Function(_IssueListDto) _then) = __$IssueListDtoCopyWithImpl;
@override @useResult
$Res call({
 List<IssueRowDto> items, String? nextCursor, num total, IssueListDtoRole? role
});




}
/// @nodoc
class __$IssueListDtoCopyWithImpl<$Res>
    implements _$IssueListDtoCopyWith<$Res> {
  __$IssueListDtoCopyWithImpl(this._self, this._then);

  final _IssueListDto _self;
  final $Res Function(_IssueListDto) _then;

/// Create a copy of IssueListDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,Object? total = null,Object? role = freezed,}) {
  return _then(_IssueListDto(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<IssueRowDto>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as IssueListDtoRole?,
  ));
}


}

// dart format on
