// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attachment_list_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AttachmentListDto {

/// Сначала старые, в порядке добавления
 List<AttachmentDto> get items; String? get nextCursor;/// Всего вложений у задачи
 num get total;/// Может ли запросивший приложить файл. `false` у читателя (US-46, D-29).
 bool get canUpload;
/// Create a copy of AttachmentListDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttachmentListDtoCopyWith<AttachmentListDto> get copyWith => _$AttachmentListDtoCopyWithImpl<AttachmentListDto>(this as AttachmentListDto, _$identity);

  /// Serializes this AttachmentListDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AttachmentListDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttachmentListDto&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor)&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.canUpload, _this.canUpload) || other.canUpload == _this.canUpload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AttachmentListDto;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.nextCursor,_this.total,_this.canUpload);
}

@override
String toString() {
  final _this = this as AttachmentListDto;
  return 'AttachmentListDto(items: ${_this.items}, nextCursor: ${_this.nextCursor}, total: ${_this.total}, canUpload: ${_this.canUpload})';
}


}

/// @nodoc
abstract mixin class $AttachmentListDtoCopyWith<$Res>  {
  factory $AttachmentListDtoCopyWith(AttachmentListDto value, $Res Function(AttachmentListDto) _then) = _$AttachmentListDtoCopyWithImpl;
@useResult
$Res call({
 List<AttachmentDto> items, String? nextCursor, num total, bool canUpload
});




}
/// @nodoc
class _$AttachmentListDtoCopyWithImpl<$Res>
    implements $AttachmentListDtoCopyWith<$Res> {
  _$AttachmentListDtoCopyWithImpl(this._self, this._then);

  final AttachmentListDto _self;
  final $Res Function(AttachmentListDto) _then;

/// Create a copy of AttachmentListDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,Object? total = null,Object? canUpload = null,}) {
  return _then(AttachmentListDto(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<AttachmentDto>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,canUpload: null == canUpload ? _self.canUpload : canUpload // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AttachmentListDto].
extension AttachmentListDtoPatterns on AttachmentListDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttachmentListDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttachmentListDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttachmentListDto value)  $default,){
final _that = this;
switch (_that) {
case _AttachmentListDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttachmentListDto value)?  $default,){
final _that = this;
switch (_that) {
case _AttachmentListDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AttachmentDto> items,  String? nextCursor,  num total,  bool canUpload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttachmentListDto() when $default != null:
return $default(_that.items,_that.nextCursor,_that.total,_that.canUpload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AttachmentDto> items,  String? nextCursor,  num total,  bool canUpload)  $default,) {final _that = this;
switch (_that) {
case _AttachmentListDto():
return $default(_that.items,_that.nextCursor,_that.total,_that.canUpload);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AttachmentDto> items,  String? nextCursor,  num total,  bool canUpload)?  $default,) {final _that = this;
switch (_that) {
case _AttachmentListDto() when $default != null:
return $default(_that.items,_that.nextCursor,_that.total,_that.canUpload);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttachmentListDto implements AttachmentListDto {
  const _AttachmentListDto({required  List<AttachmentDto> items, required this.nextCursor, required this.total, required this.canUpload}): _items = items;
  factory _AttachmentListDto.fromJson(Map<String, dynamic> json) => _$AttachmentListDtoFromJson(json);

/// Сначала старые, в порядке добавления
 final  List<AttachmentDto> _items;
/// Сначала старые, в порядке добавления
@override List<AttachmentDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;
/// Всего вложений у задачи
@override final  num total;
/// Может ли запросивший приложить файл. `false` у читателя (US-46, D-29).
@override final  bool canUpload;

/// Create a copy of AttachmentListDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttachmentListDtoCopyWith<_AttachmentListDto> get copyWith => __$AttachmentListDtoCopyWithImpl<_AttachmentListDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttachmentListDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttachmentListDto&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.total, total) || other.total == total)&&(identical(other.canUpload, canUpload) || other.canUpload == canUpload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor,total,canUpload);
}

@override
String toString() {
    return 'AttachmentListDto(items: $items, nextCursor: $nextCursor, total: $total, canUpload: $canUpload)';
}


}

/// @nodoc
abstract mixin class _$AttachmentListDtoCopyWith<$Res> implements $AttachmentListDtoCopyWith<$Res> {
  factory _$AttachmentListDtoCopyWith(_AttachmentListDto value, $Res Function(_AttachmentListDto) _then) = __$AttachmentListDtoCopyWithImpl;
@override @useResult
$Res call({
 List<AttachmentDto> items, String? nextCursor, num total, bool canUpload
});




}
/// @nodoc
class __$AttachmentListDtoCopyWithImpl<$Res>
    implements _$AttachmentListDtoCopyWith<$Res> {
  __$AttachmentListDtoCopyWithImpl(this._self, this._then);

  final _AttachmentListDto _self;
  final $Res Function(_AttachmentListDto) _then;

/// Create a copy of AttachmentListDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,Object? total = null,Object? canUpload = null,}) {
  return _then(_AttachmentListDto(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<AttachmentDto>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,canUpload: null == canUpload ? _self.canUpload : canUpload // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
