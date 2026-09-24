// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'token_list_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TokenListDto {

/// Сначала новые
 List<TokenDto> get items;/// Сколько токенов в ответе
 num get total;
/// Create a copy of TokenListDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokenListDtoCopyWith<TokenListDto> get copyWith => _$TokenListDtoCopyWithImpl<TokenListDto>(this as TokenListDto, _$identity);

  /// Serializes this TokenListDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TokenListDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TokenListDto&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.total, _this.total) || other.total == _this.total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TokenListDto;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.total);
}

@override
String toString() {
  final _this = this as TokenListDto;
  return 'TokenListDto(items: ${_this.items}, total: ${_this.total})';
}


}

/// @nodoc
abstract mixin class $TokenListDtoCopyWith<$Res>  {
  factory $TokenListDtoCopyWith(TokenListDto value, $Res Function(TokenListDto) _then) = _$TokenListDtoCopyWithImpl;
@useResult
$Res call({
 List<TokenDto> items, num total
});




}
/// @nodoc
class _$TokenListDtoCopyWithImpl<$Res>
    implements $TokenListDtoCopyWith<$Res> {
  _$TokenListDtoCopyWithImpl(this._self, this._then);

  final TokenListDto _self;
  final $Res Function(TokenListDto) _then;

/// Create a copy of TokenListDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? total = null,}) {
  return _then(TokenListDto(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<TokenDto>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [TokenListDto].
extension TokenListDtoPatterns on TokenListDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TokenListDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TokenListDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TokenListDto value)  $default,){
final _that = this;
switch (_that) {
case _TokenListDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TokenListDto value)?  $default,){
final _that = this;
switch (_that) {
case _TokenListDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TokenDto> items,  num total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TokenListDto() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TokenDto> items,  num total)  $default,) {final _that = this;
switch (_that) {
case _TokenListDto():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TokenDto> items,  num total)?  $default,) {final _that = this;
switch (_that) {
case _TokenListDto() when $default != null:
return $default(_that.items,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TokenListDto implements TokenListDto {
  const _TokenListDto({required  List<TokenDto> items, required this.total}): _items = items;
  factory _TokenListDto.fromJson(Map<String, dynamic> json) => _$TokenListDtoFromJson(json);

/// Сначала новые
 final  List<TokenDto> _items;
/// Сначала новые
@override List<TokenDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Сколько токенов в ответе
@override final  num total;

/// Create a copy of TokenListDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TokenListDtoCopyWith<_TokenListDto> get copyWith => __$TokenListDtoCopyWithImpl<_TokenListDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TokenListDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TokenListDto&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),total);
}

@override
String toString() {
    return 'TokenListDto(items: $items, total: $total)';
}


}

/// @nodoc
abstract mixin class _$TokenListDtoCopyWith<$Res> implements $TokenListDtoCopyWith<$Res> {
  factory _$TokenListDtoCopyWith(_TokenListDto value, $Res Function(_TokenListDto) _then) = __$TokenListDtoCopyWithImpl;
@override @useResult
$Res call({
 List<TokenDto> items, num total
});




}
/// @nodoc
class __$TokenListDtoCopyWithImpl<$Res>
    implements _$TokenListDtoCopyWith<$Res> {
  __$TokenListDtoCopyWithImpl(this._self, this._then);

  final _TokenListDto _self;
  final $Res Function(_TokenListDto) _then;

/// Create a copy of TokenListDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? total = null,}) {
  return _then(_TokenListDto(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<TokenDto>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}

// dart format on
