// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_list_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectListDto {

/// Проекты пользователя, по названию
 List<ProjectDto> get items;/// Курсор следующей страницы. `null` — проектов больше нет.
 String? get nextCursor;/// Всего проектов у пользователя
 num get total;
/// Create a copy of ProjectListDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectListDtoCopyWith<ProjectListDto> get copyWith => _$ProjectListDtoCopyWithImpl<ProjectListDto>(this as ProjectListDto, _$identity);

  /// Serializes this ProjectListDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProjectListDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectListDto&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor)&&(identical(other.total, _this.total) || other.total == _this.total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProjectListDto;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.nextCursor,_this.total);
}

@override
String toString() {
  final _this = this as ProjectListDto;
  return 'ProjectListDto(items: ${_this.items}, nextCursor: ${_this.nextCursor}, total: ${_this.total})';
}


}

/// @nodoc
abstract mixin class $ProjectListDtoCopyWith<$Res>  {
  factory $ProjectListDtoCopyWith(ProjectListDto value, $Res Function(ProjectListDto) _then) = _$ProjectListDtoCopyWithImpl;
@useResult
$Res call({
 List<ProjectDto> items, String? nextCursor, num total
});




}
/// @nodoc
class _$ProjectListDtoCopyWithImpl<$Res>
    implements $ProjectListDtoCopyWith<$Res> {
  _$ProjectListDtoCopyWithImpl(this._self, this._then);

  final ProjectListDto _self;
  final $Res Function(ProjectListDto) _then;

/// Create a copy of ProjectListDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,Object? total = null,}) {
  return _then(ProjectListDto(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ProjectDto>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectListDto].
extension ProjectListDtoPatterns on ProjectListDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectListDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectListDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectListDto value)  $default,){
final _that = this;
switch (_that) {
case _ProjectListDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectListDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectListDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ProjectDto> items,  String? nextCursor,  num total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectListDto() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ProjectDto> items,  String? nextCursor,  num total)  $default,) {final _that = this;
switch (_that) {
case _ProjectListDto():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ProjectDto> items,  String? nextCursor,  num total)?  $default,) {final _that = this;
switch (_that) {
case _ProjectListDto() when $default != null:
return $default(_that.items,_that.nextCursor,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectListDto implements ProjectListDto {
  const _ProjectListDto({required  List<ProjectDto> items, required this.nextCursor, required this.total}): _items = items;
  factory _ProjectListDto.fromJson(Map<String, dynamic> json) => _$ProjectListDtoFromJson(json);

/// Проекты пользователя, по названию
 final  List<ProjectDto> _items;
/// Проекты пользователя, по названию
@override List<ProjectDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Курсор следующей страницы. `null` — проектов больше нет.
@override final  String? nextCursor;
/// Всего проектов у пользователя
@override final  num total;

/// Create a copy of ProjectListDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectListDtoCopyWith<_ProjectListDto> get copyWith => __$ProjectListDtoCopyWithImpl<_ProjectListDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectListDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectListDto&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor,total);
}

@override
String toString() {
    return 'ProjectListDto(items: $items, nextCursor: $nextCursor, total: $total)';
}


}

/// @nodoc
abstract mixin class _$ProjectListDtoCopyWith<$Res> implements $ProjectListDtoCopyWith<$Res> {
  factory _$ProjectListDtoCopyWith(_ProjectListDto value, $Res Function(_ProjectListDto) _then) = __$ProjectListDtoCopyWithImpl;
@override @useResult
$Res call({
 List<ProjectDto> items, String? nextCursor, num total
});




}
/// @nodoc
class __$ProjectListDtoCopyWithImpl<$Res>
    implements _$ProjectListDtoCopyWith<$Res> {
  __$ProjectListDtoCopyWithImpl(this._self, this._then);

  final _ProjectListDto _self;
  final $Res Function(_ProjectListDto) _then;

/// Create a copy of ProjectListDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,Object? total = null,}) {
  return _then(_ProjectListDto(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ProjectDto>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}

// dart format on
