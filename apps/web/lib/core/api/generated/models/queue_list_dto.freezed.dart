// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'queue_list_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QueueListDto {

/// По названию по возрастанию (US-31)
 List<QueueDto> get items;/// Очередей у проекта единицы, поэтому список отдаётся целиком, без курсора
 num? get total;
/// Create a copy of QueueListDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QueueListDtoCopyWith<QueueListDto> get copyWith => _$QueueListDtoCopyWithImpl<QueueListDto>(this as QueueListDto, _$identity);

  /// Serializes this QueueListDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as QueueListDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QueueListDto&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.total, _this.total) || other.total == _this.total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as QueueListDto;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.total);
}

@override
String toString() {
  final _this = this as QueueListDto;
  return 'QueueListDto(items: ${_this.items}, total: ${_this.total})';
}


}

/// @nodoc
abstract mixin class $QueueListDtoCopyWith<$Res>  {
  factory $QueueListDtoCopyWith(QueueListDto value, $Res Function(QueueListDto) _then) = _$QueueListDtoCopyWithImpl;
@useResult
$Res call({
 List<QueueDto> items, num? total
});




}
/// @nodoc
class _$QueueListDtoCopyWithImpl<$Res>
    implements $QueueListDtoCopyWith<$Res> {
  _$QueueListDtoCopyWithImpl(this._self, this._then);

  final QueueListDto _self;
  final $Res Function(QueueListDto) _then;

/// Create a copy of QueueListDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? total = freezed,}) {
  return _then(QueueListDto(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<QueueDto>,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}

}


/// Adds pattern-matching-related methods to [QueueListDto].
extension QueueListDtoPatterns on QueueListDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QueueListDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QueueListDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QueueListDto value)  $default,){
final _that = this;
switch (_that) {
case _QueueListDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QueueListDto value)?  $default,){
final _that = this;
switch (_that) {
case _QueueListDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<QueueDto> items,  num? total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QueueListDto() when $default != null:
return $default(_that.items,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<QueueDto> items,  num? total)  $default,) {final _that = this;
switch (_that) {
case _QueueListDto():
return $default(_that.items,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<QueueDto> items,  num? total)?  $default,) {final _that = this;
switch (_that) {
case _QueueListDto() when $default != null:
return $default(_that.items,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QueueListDto implements QueueListDto {
  const _QueueListDto({required  List<QueueDto> items, this.total}): _items = items;
  factory _QueueListDto.fromJson(Map<String, dynamic> json) => _$QueueListDtoFromJson(json);

/// По названию по возрастанию (US-31)
 final  List<QueueDto> _items;
/// По названию по возрастанию (US-31)
@override List<QueueDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Очередей у проекта единицы, поэтому список отдаётся целиком, без курсора
@override final  num? total;

/// Create a copy of QueueListDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QueueListDtoCopyWith<_QueueListDto> get copyWith => __$QueueListDtoCopyWithImpl<_QueueListDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QueueListDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _QueueListDto&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),total);
}

@override
String toString() {
    return 'QueueListDto(items: $items, total: $total)';
}


}

/// @nodoc
abstract mixin class _$QueueListDtoCopyWith<$Res> implements $QueueListDtoCopyWith<$Res> {
  factory _$QueueListDtoCopyWith(_QueueListDto value, $Res Function(_QueueListDto) _then) = __$QueueListDtoCopyWithImpl;
@override @useResult
$Res call({
 List<QueueDto> items, num? total
});




}
/// @nodoc
class __$QueueListDtoCopyWithImpl<$Res>
    implements _$QueueListDtoCopyWith<$Res> {
  __$QueueListDtoCopyWithImpl(this._self, this._then);

  final _QueueListDto _self;
  final $Res Function(_QueueListDto) _then;

/// Create a copy of QueueListDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? total = freezed,}) {
  return _then(_QueueListDto(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<QueueDto>,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}


}

// dart format on
