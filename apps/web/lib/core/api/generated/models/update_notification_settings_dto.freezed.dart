// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_notification_settings_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateNotificationSettingsDto {

/// Меняются только перечисленные типы; остальные остаются как были.
 List<UpdateNotificationSettingDto> get items;
/// Create a copy of UpdateNotificationSettingsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateNotificationSettingsDtoCopyWith<UpdateNotificationSettingsDto> get copyWith => _$UpdateNotificationSettingsDtoCopyWithImpl<UpdateNotificationSettingsDto>(this as UpdateNotificationSettingsDto, _$identity);

  /// Serializes this UpdateNotificationSettingsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UpdateNotificationSettingsDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateNotificationSettingsDto&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UpdateNotificationSettingsDto;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as UpdateNotificationSettingsDto;
  return 'UpdateNotificationSettingsDto(items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $UpdateNotificationSettingsDtoCopyWith<$Res>  {
  factory $UpdateNotificationSettingsDtoCopyWith(UpdateNotificationSettingsDto value, $Res Function(UpdateNotificationSettingsDto) _then) = _$UpdateNotificationSettingsDtoCopyWithImpl;
@useResult
$Res call({
 List<UpdateNotificationSettingDto> items
});




}
/// @nodoc
class _$UpdateNotificationSettingsDtoCopyWithImpl<$Res>
    implements $UpdateNotificationSettingsDtoCopyWith<$Res> {
  _$UpdateNotificationSettingsDtoCopyWithImpl(this._self, this._then);

  final UpdateNotificationSettingsDto _self;
  final $Res Function(UpdateNotificationSettingsDto) _then;

/// Create a copy of UpdateNotificationSettingsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,}) {
  return _then(UpdateNotificationSettingsDto(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<UpdateNotificationSettingDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateNotificationSettingsDto].
extension UpdateNotificationSettingsDtoPatterns on UpdateNotificationSettingsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateNotificationSettingsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateNotificationSettingsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateNotificationSettingsDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdateNotificationSettingsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateNotificationSettingsDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateNotificationSettingsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<UpdateNotificationSettingDto> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateNotificationSettingsDto() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<UpdateNotificationSettingDto> items)  $default,) {final _that = this;
switch (_that) {
case _UpdateNotificationSettingsDto():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<UpdateNotificationSettingDto> items)?  $default,) {final _that = this;
switch (_that) {
case _UpdateNotificationSettingsDto() when $default != null:
return $default(_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateNotificationSettingsDto implements UpdateNotificationSettingsDto {
  const _UpdateNotificationSettingsDto({required  List<UpdateNotificationSettingDto> items}): _items = items;
  factory _UpdateNotificationSettingsDto.fromJson(Map<String, dynamic> json) => _$UpdateNotificationSettingsDtoFromJson(json);

/// Меняются только перечисленные типы; остальные остаются как были.
 final  List<UpdateNotificationSettingDto> _items;
/// Меняются только перечисленные типы; остальные остаются как были.
@override List<UpdateNotificationSettingDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of UpdateNotificationSettingsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateNotificationSettingsDtoCopyWith<_UpdateNotificationSettingsDto> get copyWith => __$UpdateNotificationSettingsDtoCopyWithImpl<_UpdateNotificationSettingsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateNotificationSettingsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateNotificationSettingsDto&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'UpdateNotificationSettingsDto(items: $items)';
}


}

/// @nodoc
abstract mixin class _$UpdateNotificationSettingsDtoCopyWith<$Res> implements $UpdateNotificationSettingsDtoCopyWith<$Res> {
  factory _$UpdateNotificationSettingsDtoCopyWith(_UpdateNotificationSettingsDto value, $Res Function(_UpdateNotificationSettingsDto) _then) = __$UpdateNotificationSettingsDtoCopyWithImpl;
@override @useResult
$Res call({
 List<UpdateNotificationSettingDto> items
});




}
/// @nodoc
class __$UpdateNotificationSettingsDtoCopyWithImpl<$Res>
    implements _$UpdateNotificationSettingsDtoCopyWith<$Res> {
  __$UpdateNotificationSettingsDtoCopyWithImpl(this._self, this._then);

  final _UpdateNotificationSettingsDto _self;
  final $Res Function(_UpdateNotificationSettingsDto) _then;

/// Create a copy of UpdateNotificationSettingsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(_UpdateNotificationSettingsDto(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<UpdateNotificationSettingDto>,
  ));
}


}

// dart format on
