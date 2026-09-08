// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invitation_list_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvitationListDto {

/// Сначала новые
 List<InvitationDto> get items; String? get nextCursor;/// Всего приглашений у проекта, включая истёкшие и отозванные
 num get total;
/// Create a copy of InvitationListDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvitationListDtoCopyWith<InvitationListDto> get copyWith => _$InvitationListDtoCopyWithImpl<InvitationListDto>(this as InvitationListDto, _$identity);

  /// Serializes this InvitationListDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InvitationListDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvitationListDto&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor)&&(identical(other.total, _this.total) || other.total == _this.total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InvitationListDto;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.nextCursor,_this.total);
}

@override
String toString() {
  final _this = this as InvitationListDto;
  return 'InvitationListDto(items: ${_this.items}, nextCursor: ${_this.nextCursor}, total: ${_this.total})';
}


}

/// @nodoc
abstract mixin class $InvitationListDtoCopyWith<$Res>  {
  factory $InvitationListDtoCopyWith(InvitationListDto value, $Res Function(InvitationListDto) _then) = _$InvitationListDtoCopyWithImpl;
@useResult
$Res call({
 List<InvitationDto> items, String? nextCursor, num total
});




}
/// @nodoc
class _$InvitationListDtoCopyWithImpl<$Res>
    implements $InvitationListDtoCopyWith<$Res> {
  _$InvitationListDtoCopyWithImpl(this._self, this._then);

  final InvitationListDto _self;
  final $Res Function(InvitationListDto) _then;

/// Create a copy of InvitationListDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,Object? total = null,}) {
  return _then(InvitationListDto(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<InvitationDto>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [InvitationListDto].
extension InvitationListDtoPatterns on InvitationListDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvitationListDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvitationListDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvitationListDto value)  $default,){
final _that = this;
switch (_that) {
case _InvitationListDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvitationListDto value)?  $default,){
final _that = this;
switch (_that) {
case _InvitationListDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<InvitationDto> items,  String? nextCursor,  num total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvitationListDto() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<InvitationDto> items,  String? nextCursor,  num total)  $default,) {final _that = this;
switch (_that) {
case _InvitationListDto():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<InvitationDto> items,  String? nextCursor,  num total)?  $default,) {final _that = this;
switch (_that) {
case _InvitationListDto() when $default != null:
return $default(_that.items,_that.nextCursor,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvitationListDto implements InvitationListDto {
  const _InvitationListDto({required  List<InvitationDto> items, required this.nextCursor, required this.total}): _items = items;
  factory _InvitationListDto.fromJson(Map<String, dynamic> json) => _$InvitationListDtoFromJson(json);

/// Сначала новые
 final  List<InvitationDto> _items;
/// Сначала новые
@override List<InvitationDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;
/// Всего приглашений у проекта, включая истёкшие и отозванные
@override final  num total;

/// Create a copy of InvitationListDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvitationListDtoCopyWith<_InvitationListDto> get copyWith => __$InvitationListDtoCopyWithImpl<_InvitationListDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvitationListDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvitationListDto&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor,total);
}

@override
String toString() {
    return 'InvitationListDto(items: $items, nextCursor: $nextCursor, total: $total)';
}


}

/// @nodoc
abstract mixin class _$InvitationListDtoCopyWith<$Res> implements $InvitationListDtoCopyWith<$Res> {
  factory _$InvitationListDtoCopyWith(_InvitationListDto value, $Res Function(_InvitationListDto) _then) = __$InvitationListDtoCopyWithImpl;
@override @useResult
$Res call({
 List<InvitationDto> items, String? nextCursor, num total
});




}
/// @nodoc
class __$InvitationListDtoCopyWithImpl<$Res>
    implements _$InvitationListDtoCopyWith<$Res> {
  __$InvitationListDtoCopyWithImpl(this._self, this._then);

  final _InvitationListDto _self;
  final $Res Function(_InvitationListDto) _then;

/// Create a copy of InvitationListDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,Object? total = null,}) {
  return _then(_InvitationListDto(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<InvitationDto>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}

// dart format on
