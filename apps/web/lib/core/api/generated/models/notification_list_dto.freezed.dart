// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_list_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationListDto {

/// Сначала новые (US-103)
 List<NotificationDto> get items;/// Курсор следующей порции
 String? get nextCursor;/// Всего уведомлений у пользователя
 num get total;/// Непрочитанных: то же число, что и в счётчике шапки
 num get unreadCount;
/// Create a copy of NotificationListDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationListDtoCopyWith<NotificationListDto> get copyWith => _$NotificationListDtoCopyWithImpl<NotificationListDto>(this as NotificationListDto, _$identity);

  /// Serializes this NotificationListDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationListDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationListDto&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor)&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.unreadCount, _this.unreadCount) || other.unreadCount == _this.unreadCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationListDto;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.nextCursor,_this.total,_this.unreadCount);
}

@override
String toString() {
  final _this = this as NotificationListDto;
  return 'NotificationListDto(items: ${_this.items}, nextCursor: ${_this.nextCursor}, total: ${_this.total}, unreadCount: ${_this.unreadCount})';
}


}

/// @nodoc
abstract mixin class $NotificationListDtoCopyWith<$Res>  {
  factory $NotificationListDtoCopyWith(NotificationListDto value, $Res Function(NotificationListDto) _then) = _$NotificationListDtoCopyWithImpl;
@useResult
$Res call({
 List<NotificationDto> items, String? nextCursor, num total, num unreadCount
});




}
/// @nodoc
class _$NotificationListDtoCopyWithImpl<$Res>
    implements $NotificationListDtoCopyWith<$Res> {
  _$NotificationListDtoCopyWithImpl(this._self, this._then);

  final NotificationListDto _self;
  final $Res Function(NotificationListDto) _then;

/// Create a copy of NotificationListDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,Object? total = null,Object? unreadCount = null,}) {
  return _then(NotificationListDto(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<NotificationDto>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationListDto].
extension NotificationListDtoPatterns on NotificationListDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationListDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationListDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationListDto value)  $default,){
final _that = this;
switch (_that) {
case _NotificationListDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationListDto value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationListDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<NotificationDto> items,  String? nextCursor,  num total,  num unreadCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationListDto() when $default != null:
return $default(_that.items,_that.nextCursor,_that.total,_that.unreadCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<NotificationDto> items,  String? nextCursor,  num total,  num unreadCount)  $default,) {final _that = this;
switch (_that) {
case _NotificationListDto():
return $default(_that.items,_that.nextCursor,_that.total,_that.unreadCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<NotificationDto> items,  String? nextCursor,  num total,  num unreadCount)?  $default,) {final _that = this;
switch (_that) {
case _NotificationListDto() when $default != null:
return $default(_that.items,_that.nextCursor,_that.total,_that.unreadCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationListDto implements NotificationListDto {
  const _NotificationListDto({required  List<NotificationDto> items, required this.nextCursor, required this.total, required this.unreadCount}): _items = items;
  factory _NotificationListDto.fromJson(Map<String, dynamic> json) => _$NotificationListDtoFromJson(json);

/// Сначала новые (US-103)
 final  List<NotificationDto> _items;
/// Сначала новые (US-103)
@override List<NotificationDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Курсор следующей порции
@override final  String? nextCursor;
/// Всего уведомлений у пользователя
@override final  num total;
/// Непрочитанных: то же число, что и в счётчике шапки
@override final  num unreadCount;

/// Create a copy of NotificationListDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationListDtoCopyWith<_NotificationListDto> get copyWith => __$NotificationListDtoCopyWithImpl<_NotificationListDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationListDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationListDto&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.total, total) || other.total == total)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor,total,unreadCount);
}

@override
String toString() {
    return 'NotificationListDto(items: $items, nextCursor: $nextCursor, total: $total, unreadCount: $unreadCount)';
}


}

/// @nodoc
abstract mixin class _$NotificationListDtoCopyWith<$Res> implements $NotificationListDtoCopyWith<$Res> {
  factory _$NotificationListDtoCopyWith(_NotificationListDto value, $Res Function(_NotificationListDto) _then) = __$NotificationListDtoCopyWithImpl;
@override @useResult
$Res call({
 List<NotificationDto> items, String? nextCursor, num total, num unreadCount
});




}
/// @nodoc
class __$NotificationListDtoCopyWithImpl<$Res>
    implements _$NotificationListDtoCopyWith<$Res> {
  __$NotificationListDtoCopyWithImpl(this._self, this._then);

  final _NotificationListDto _self;
  final $Res Function(_NotificationListDto) _then;

/// Create a copy of NotificationListDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,Object? total = null,Object? unreadCount = null,}) {
  return _then(_NotificationListDto(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<NotificationDto>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}

// dart format on
