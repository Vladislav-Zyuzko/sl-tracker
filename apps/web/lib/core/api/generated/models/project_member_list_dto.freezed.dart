// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_member_list_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectMemberListDto {

/// Сначала администраторы, дальше по имени (design/screens/project.md)
 List<ProjectMemberDto> get items; String? get nextCursor;/// Всего участников в проекте, а при поиске (`q`) — сколько участников ему соответствует, то есть длина всего отфильтрованного списка, а не страницы.
 num get total;
/// Create a copy of ProjectMemberListDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectMemberListDtoCopyWith<ProjectMemberListDto> get copyWith => _$ProjectMemberListDtoCopyWithImpl<ProjectMemberListDto>(this as ProjectMemberListDto, _$identity);

  /// Serializes this ProjectMemberListDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProjectMemberListDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectMemberListDto&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor)&&(identical(other.total, _this.total) || other.total == _this.total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProjectMemberListDto;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.nextCursor,_this.total);
}

@override
String toString() {
  final _this = this as ProjectMemberListDto;
  return 'ProjectMemberListDto(items: ${_this.items}, nextCursor: ${_this.nextCursor}, total: ${_this.total})';
}


}

/// @nodoc
abstract mixin class $ProjectMemberListDtoCopyWith<$Res>  {
  factory $ProjectMemberListDtoCopyWith(ProjectMemberListDto value, $Res Function(ProjectMemberListDto) _then) = _$ProjectMemberListDtoCopyWithImpl;
@useResult
$Res call({
 List<ProjectMemberDto> items, String? nextCursor, num total
});




}
/// @nodoc
class _$ProjectMemberListDtoCopyWithImpl<$Res>
    implements $ProjectMemberListDtoCopyWith<$Res> {
  _$ProjectMemberListDtoCopyWithImpl(this._self, this._then);

  final ProjectMemberListDto _self;
  final $Res Function(ProjectMemberListDto) _then;

/// Create a copy of ProjectMemberListDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,Object? total = null,}) {
  return _then(ProjectMemberListDto(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ProjectMemberDto>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectMemberListDto].
extension ProjectMemberListDtoPatterns on ProjectMemberListDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectMemberListDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectMemberListDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectMemberListDto value)  $default,){
final _that = this;
switch (_that) {
case _ProjectMemberListDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectMemberListDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectMemberListDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ProjectMemberDto> items,  String? nextCursor,  num total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectMemberListDto() when $default != null:
return $default(_that.items,_that.nextCursor,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ProjectMemberDto> items,  String? nextCursor,  num total)  $default,) {final _that = this;
switch (_that) {
case _ProjectMemberListDto():
return $default(_that.items,_that.nextCursor,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ProjectMemberDto> items,  String? nextCursor,  num total)?  $default,) {final _that = this;
switch (_that) {
case _ProjectMemberListDto() when $default != null:
return $default(_that.items,_that.nextCursor,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectMemberListDto implements ProjectMemberListDto {
  const _ProjectMemberListDto({required  List<ProjectMemberDto> items, required this.nextCursor, required this.total}): _items = items;
  factory _ProjectMemberListDto.fromJson(Map<String, dynamic> json) => _$ProjectMemberListDtoFromJson(json);

/// Сначала администраторы, дальше по имени (design/screens/project.md)
 final  List<ProjectMemberDto> _items;
/// Сначала администраторы, дальше по имени (design/screens/project.md)
@override List<ProjectMemberDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;
/// Всего участников в проекте, а при поиске (`q`) — сколько участников ему соответствует, то есть длина всего отфильтрованного списка, а не страницы.
@override final  num total;

/// Create a copy of ProjectMemberListDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectMemberListDtoCopyWith<_ProjectMemberListDto> get copyWith => __$ProjectMemberListDtoCopyWithImpl<_ProjectMemberListDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectMemberListDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectMemberListDto&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor,total);
}

@override
String toString() {
    return 'ProjectMemberListDto(items: $items, nextCursor: $nextCursor, total: $total)';
}


}

/// @nodoc
abstract mixin class _$ProjectMemberListDtoCopyWith<$Res> implements $ProjectMemberListDtoCopyWith<$Res> {
  factory _$ProjectMemberListDtoCopyWith(_ProjectMemberListDto value, $Res Function(_ProjectMemberListDto) _then) = __$ProjectMemberListDtoCopyWithImpl;
@override @useResult
$Res call({
 List<ProjectMemberDto> items, String? nextCursor, num total
});




}
/// @nodoc
class __$ProjectMemberListDtoCopyWithImpl<$Res>
    implements _$ProjectMemberListDtoCopyWith<$Res> {
  __$ProjectMemberListDtoCopyWithImpl(this._self, this._then);

  final _ProjectMemberListDto _self;
  final $Res Function(_ProjectMemberListDto) _then;

/// Create a copy of ProjectMemberListDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,Object? total = null,}) {
  return _then(_ProjectMemberListDto(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ProjectMemberDto>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}

// dart format on
