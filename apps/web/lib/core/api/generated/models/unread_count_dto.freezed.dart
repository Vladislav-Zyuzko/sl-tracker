// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unread_count_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UnreadCountDto {

/// Точное число непрочитанных. Обрезку до «99+» делает интерфейс, а не сервер: иначе он не сможет показать точное значение до 99 (US-103).
 num get unreadCount;
/// Create a copy of UnreadCountDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnreadCountDtoCopyWith<UnreadCountDto> get copyWith => _$UnreadCountDtoCopyWithImpl<UnreadCountDto>(this as UnreadCountDto, _$identity);

  /// Serializes this UnreadCountDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UnreadCountDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnreadCountDto&&(identical(other.unreadCount, _this.unreadCount) || other.unreadCount == _this.unreadCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UnreadCountDto;
  return Object.hash(runtimeType,_this.unreadCount);
}

@override
String toString() {
  final _this = this as UnreadCountDto;
  return 'UnreadCountDto(unreadCount: ${_this.unreadCount})';
}


}

/// @nodoc
abstract mixin class $UnreadCountDtoCopyWith<$Res>  {
  factory $UnreadCountDtoCopyWith(UnreadCountDto value, $Res Function(UnreadCountDto) _then) = _$UnreadCountDtoCopyWithImpl;
@useResult
$Res call({
 num unreadCount
});




}
/// @nodoc
class _$UnreadCountDtoCopyWithImpl<$Res>
    implements $UnreadCountDtoCopyWith<$Res> {
  _$UnreadCountDtoCopyWithImpl(this._self, this._then);

  final UnreadCountDto _self;
  final $Res Function(UnreadCountDto) _then;

/// Create a copy of UnreadCountDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? unreadCount = null,}) {
  return _then(UnreadCountDto(
unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [UnreadCountDto].
extension UnreadCountDtoPatterns on UnreadCountDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnreadCountDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnreadCountDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnreadCountDto value)  $default,){
final _that = this;
switch (_that) {
case _UnreadCountDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnreadCountDto value)?  $default,){
final _that = this;
switch (_that) {
case _UnreadCountDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( num unreadCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnreadCountDto() when $default != null:
return $default(_that.unreadCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( num unreadCount)  $default,) {final _that = this;
switch (_that) {
case _UnreadCountDto():
return $default(_that.unreadCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( num unreadCount)?  $default,) {final _that = this;
switch (_that) {
case _UnreadCountDto() when $default != null:
return $default(_that.unreadCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UnreadCountDto implements UnreadCountDto {
  const _UnreadCountDto({required this.unreadCount});
  factory _UnreadCountDto.fromJson(Map<String, dynamic> json) => _$UnreadCountDtoFromJson(json);

/// Точное число непрочитанных. Обрезку до «99+» делает интерфейс, а не сервер: иначе он не сможет показать точное значение до 99 (US-103).
@override final  num unreadCount;

/// Create a copy of UnreadCountDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnreadCountDtoCopyWith<_UnreadCountDto> get copyWith => __$UnreadCountDtoCopyWithImpl<_UnreadCountDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnreadCountDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnreadCountDto&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,unreadCount);
}

@override
String toString() {
    return 'UnreadCountDto(unreadCount: $unreadCount)';
}


}

/// @nodoc
abstract mixin class _$UnreadCountDtoCopyWith<$Res> implements $UnreadCountDtoCopyWith<$Res> {
  factory _$UnreadCountDtoCopyWith(_UnreadCountDto value, $Res Function(_UnreadCountDto) _then) = __$UnreadCountDtoCopyWithImpl;
@override @useResult
$Res call({
 num unreadCount
});




}
/// @nodoc
class __$UnreadCountDtoCopyWithImpl<$Res>
    implements _$UnreadCountDtoCopyWith<$Res> {
  __$UnreadCountDtoCopyWithImpl(this._self, this._then);

  final _UnreadCountDto _self;
  final $Res Function(_UnreadCountDto) _then;

/// Create a copy of UnreadCountDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? unreadCount = null,}) {
  return _then(_UnreadCountDto(
unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}

// dart format on
