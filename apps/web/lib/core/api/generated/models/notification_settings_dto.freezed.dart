// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_settings_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationSettingsDto {

/// Все типы уведомлений, включая те, которые пользователь не трогал: отсутствие записи в базе означает «включено», и клиенту не нужно об этом знать.
 List<NotificationSettingDto> get items;
/// Create a copy of NotificationSettingsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationSettingsDtoCopyWith<NotificationSettingsDto> get copyWith => _$NotificationSettingsDtoCopyWithImpl<NotificationSettingsDto>(this as NotificationSettingsDto, _$identity);

  /// Serializes this NotificationSettingsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationSettingsDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationSettingsDto&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationSettingsDto;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as NotificationSettingsDto;
  return 'NotificationSettingsDto(items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $NotificationSettingsDtoCopyWith<$Res>  {
  factory $NotificationSettingsDtoCopyWith(NotificationSettingsDto value, $Res Function(NotificationSettingsDto) _then) = _$NotificationSettingsDtoCopyWithImpl;
@useResult
$Res call({
 List<NotificationSettingDto> items
});




}
/// @nodoc
class _$NotificationSettingsDtoCopyWithImpl<$Res>
    implements $NotificationSettingsDtoCopyWith<$Res> {
  _$NotificationSettingsDtoCopyWithImpl(this._self, this._then);

  final NotificationSettingsDto _self;
  final $Res Function(NotificationSettingsDto) _then;

/// Create a copy of NotificationSettingsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,}) {
  return _then(NotificationSettingsDto(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<NotificationSettingDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationSettingsDto].
extension NotificationSettingsDtoPatterns on NotificationSettingsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationSettingsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationSettingsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationSettingsDto value)  $default,){
final _that = this;
switch (_that) {
case _NotificationSettingsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationSettingsDto value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationSettingsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<NotificationSettingDto> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationSettingsDto() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<NotificationSettingDto> items)  $default,) {final _that = this;
switch (_that) {
case _NotificationSettingsDto():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<NotificationSettingDto> items)?  $default,) {final _that = this;
switch (_that) {
case _NotificationSettingsDto() when $default != null:
return $default(_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationSettingsDto implements NotificationSettingsDto {
  const _NotificationSettingsDto({required  List<NotificationSettingDto> items}): _items = items;
  factory _NotificationSettingsDto.fromJson(Map<String, dynamic> json) => _$NotificationSettingsDtoFromJson(json);

/// Все типы уведомлений, включая те, которые пользователь не трогал: отсутствие записи в базе означает «включено», и клиенту не нужно об этом знать.
 final  List<NotificationSettingDto> _items;
/// Все типы уведомлений, включая те, которые пользователь не трогал: отсутствие записи в базе означает «включено», и клиенту не нужно об этом знать.
@override List<NotificationSettingDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of NotificationSettingsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationSettingsDtoCopyWith<_NotificationSettingsDto> get copyWith => __$NotificationSettingsDtoCopyWithImpl<_NotificationSettingsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationSettingsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationSettingsDto&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'NotificationSettingsDto(items: $items)';
}


}

/// @nodoc
abstract mixin class _$NotificationSettingsDtoCopyWith<$Res> implements $NotificationSettingsDtoCopyWith<$Res> {
  factory _$NotificationSettingsDtoCopyWith(_NotificationSettingsDto value, $Res Function(_NotificationSettingsDto) _then) = __$NotificationSettingsDtoCopyWithImpl;
@override @useResult
$Res call({
 List<NotificationSettingDto> items
});




}
/// @nodoc
class __$NotificationSettingsDtoCopyWithImpl<$Res>
    implements _$NotificationSettingsDtoCopyWith<$Res> {
  __$NotificationSettingsDtoCopyWithImpl(this._self, this._then);

  final _NotificationSettingsDto _self;
  final $Res Function(_NotificationSettingsDto) _then;

/// Create a copy of NotificationSettingsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(_NotificationSettingsDto(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<NotificationSettingDto>,
  ));
}


}

// dart format on
