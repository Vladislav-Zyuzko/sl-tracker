// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mention_suggestion_list_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MentionSuggestionListDto {

/// По имени по возрастанию; не более 10 совпадений
 List<MentionSuggestionDto> get items;
/// Create a copy of MentionSuggestionListDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MentionSuggestionListDtoCopyWith<MentionSuggestionListDto> get copyWith => _$MentionSuggestionListDtoCopyWithImpl<MentionSuggestionListDto>(this as MentionSuggestionListDto, _$identity);

  /// Serializes this MentionSuggestionListDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MentionSuggestionListDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MentionSuggestionListDto&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MentionSuggestionListDto;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as MentionSuggestionListDto;
  return 'MentionSuggestionListDto(items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $MentionSuggestionListDtoCopyWith<$Res>  {
  factory $MentionSuggestionListDtoCopyWith(MentionSuggestionListDto value, $Res Function(MentionSuggestionListDto) _then) = _$MentionSuggestionListDtoCopyWithImpl;
@useResult
$Res call({
 List<MentionSuggestionDto> items
});




}
/// @nodoc
class _$MentionSuggestionListDtoCopyWithImpl<$Res>
    implements $MentionSuggestionListDtoCopyWith<$Res> {
  _$MentionSuggestionListDtoCopyWithImpl(this._self, this._then);

  final MentionSuggestionListDto _self;
  final $Res Function(MentionSuggestionListDto) _then;

/// Create a copy of MentionSuggestionListDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,}) {
  return _then(MentionSuggestionListDto(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<MentionSuggestionDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [MentionSuggestionListDto].
extension MentionSuggestionListDtoPatterns on MentionSuggestionListDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MentionSuggestionListDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MentionSuggestionListDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MentionSuggestionListDto value)  $default,){
final _that = this;
switch (_that) {
case _MentionSuggestionListDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MentionSuggestionListDto value)?  $default,){
final _that = this;
switch (_that) {
case _MentionSuggestionListDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MentionSuggestionDto> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MentionSuggestionListDto() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MentionSuggestionDto> items)  $default,) {final _that = this;
switch (_that) {
case _MentionSuggestionListDto():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MentionSuggestionDto> items)?  $default,) {final _that = this;
switch (_that) {
case _MentionSuggestionListDto() when $default != null:
return $default(_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MentionSuggestionListDto implements MentionSuggestionListDto {
  const _MentionSuggestionListDto({required  List<MentionSuggestionDto> items}): _items = items;
  factory _MentionSuggestionListDto.fromJson(Map<String, dynamic> json) => _$MentionSuggestionListDtoFromJson(json);

/// По имени по возрастанию; не более 10 совпадений
 final  List<MentionSuggestionDto> _items;
/// По имени по возрастанию; не более 10 совпадений
@override List<MentionSuggestionDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of MentionSuggestionListDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MentionSuggestionListDtoCopyWith<_MentionSuggestionListDto> get copyWith => __$MentionSuggestionListDtoCopyWithImpl<_MentionSuggestionListDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MentionSuggestionListDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MentionSuggestionListDto&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'MentionSuggestionListDto(items: $items)';
}


}

/// @nodoc
abstract mixin class _$MentionSuggestionListDtoCopyWith<$Res> implements $MentionSuggestionListDtoCopyWith<$Res> {
  factory _$MentionSuggestionListDtoCopyWith(_MentionSuggestionListDto value, $Res Function(_MentionSuggestionListDto) _then) = __$MentionSuggestionListDtoCopyWithImpl;
@override @useResult
$Res call({
 List<MentionSuggestionDto> items
});




}
/// @nodoc
class __$MentionSuggestionListDtoCopyWithImpl<$Res>
    implements _$MentionSuggestionListDtoCopyWith<$Res> {
  __$MentionSuggestionListDtoCopyWithImpl(this._self, this._then);

  final _MentionSuggestionListDto _self;
  final $Res Function(_MentionSuggestionListDto) _then;

/// Create a copy of MentionSuggestionListDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(_MentionSuggestionListDto(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MentionSuggestionDto>,
  ));
}


}

// dart format on
