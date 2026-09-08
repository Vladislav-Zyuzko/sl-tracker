// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'queue_status_list_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QueueStatusListDto {

/// В фиксированном порядке отображения
 List<QueueStatusDto> get items;
/// Create a copy of QueueStatusListDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueStatusListDtoCopyWith<QueueStatusListDto> get copyWith => _$QueueStatusListDtoCopyWithImpl<QueueStatusListDto>(this as QueueStatusListDto, _$identity);

  /// Serializes this QueueStatusListDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as QueueStatusListDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueStatusListDto&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as QueueStatusListDto;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as QueueStatusListDto;
  return 'QueueStatusListDto(items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $QueueStatusListDtoCopyWith<$Res>  {
  factory $QueueStatusListDtoCopyWith(QueueStatusListDto value, $Res Function(QueueStatusListDto) _then) = _$QueueStatusListDtoCopyWithImpl;
@useResult
$Res call({
 List<QueueStatusDto> items
});




}
/// @nodoc
class _$QueueStatusListDtoCopyWithImpl<$Res>
    implements $QueueStatusListDtoCopyWith<$Res> {
  _$QueueStatusListDtoCopyWithImpl(this._self, this._then);

  final QueueStatusListDto _self;
  final $Res Function(QueueStatusListDto) _then;

/// Create a copy of QueueStatusListDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,}) {
  return _then(QueueStatusListDto(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<QueueStatusDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [QueueStatusListDto].
extension QueueStatusListDtoPatterns on QueueStatusListDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueueStatusListDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueueStatusListDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueueStatusListDto value)  $default,){
final _that = this;
switch (_that) {
case _QueueStatusListDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueueStatusListDto value)?  $default,){
final _that = this;
switch (_that) {
case _QueueStatusListDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<QueueStatusDto> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueueStatusListDto() when $default != null:
return $default(_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<QueueStatusDto> items)  $default,) {final _that = this;
switch (_that) {
case _QueueStatusListDto():
return $default(_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<QueueStatusDto> items)?  $default,) {final _that = this;
switch (_that) {
case _QueueStatusListDto() when $default != null:
return $default(_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QueueStatusListDto implements QueueStatusListDto {
  const _QueueStatusListDto({required  List<QueueStatusDto> items}): _items = items;
  factory _QueueStatusListDto.fromJson(Map<String, dynamic> json) => _$QueueStatusListDtoFromJson(json);

/// В фиксированном порядке отображения
 final  List<QueueStatusDto> _items;
/// В фиксированном порядке отображения
@override List<QueueStatusDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of QueueStatusListDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueStatusListDtoCopyWith<_QueueStatusListDto> get copyWith => __$QueueStatusListDtoCopyWithImpl<_QueueStatusListDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QueueStatusListDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueueStatusListDto&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'QueueStatusListDto(items: $items)';
}


}

/// @nodoc
abstract mixin class _$QueueStatusListDtoCopyWith<$Res> implements $QueueStatusListDtoCopyWith<$Res> {
  factory _$QueueStatusListDtoCopyWith(_QueueStatusListDto value, $Res Function(_QueueStatusListDto) _then) = __$QueueStatusListDtoCopyWithImpl;
@override @useResult
$Res call({
 List<QueueStatusDto> items
});




}
/// @nodoc
class __$QueueStatusListDtoCopyWithImpl<$Res>
    implements _$QueueStatusListDtoCopyWith<$Res> {
  __$QueueStatusListDtoCopyWithImpl(this._self, this._then);

  final _QueueStatusListDto _self;
  final $Res Function(_QueueStatusListDto) _then;

/// Create a copy of QueueStatusListDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(_QueueStatusListDto(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<QueueStatusDto>,
  ));
}


}

// dart format on
