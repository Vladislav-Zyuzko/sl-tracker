// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_notification_setting_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateNotificationSettingDto {

 UpdateNotificationSettingDtoType get type;/// Выключенный тип не создаёт ни записи, ни счётчика (US-103)
 bool get enabled;/// Канал. В MVP единственный, но передавать его можно уже сейчас (D-18).
 UpdateNotificationSettingDtoChannel get channel;
/// Create a copy of UpdateNotificationSettingDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateNotificationSettingDtoCopyWith<UpdateNotificationSettingDto> get copyWith => _$UpdateNotificationSettingDtoCopyWithImpl<UpdateNotificationSettingDto>(this as UpdateNotificationSettingDto, _$identity);

  /// Serializes this UpdateNotificationSettingDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UpdateNotificationSettingDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateNotificationSettingDto&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.channel, _this.channel) || other.channel == _this.channel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UpdateNotificationSettingDto;
  return Object.hash(runtimeType,_this.type,_this.enabled,_this.channel);
}

@override
String toString() {
  final _this = this as UpdateNotificationSettingDto;
  return 'UpdateNotificationSettingDto(type: ${_this.type}, enabled: ${_this.enabled}, channel: ${_this.channel})';
}


}

/// @nodoc
abstract mixin class $UpdateNotificationSettingDtoCopyWith<$Res>  {
  factory $UpdateNotificationSettingDtoCopyWith(UpdateNotificationSettingDto value, $Res Function(UpdateNotificationSettingDto) _then) = _$UpdateNotificationSettingDtoCopyWithImpl;
@useResult
$Res call({
 UpdateNotificationSettingDtoType type, bool enabled, UpdateNotificationSettingDtoChannel channel
});




}
/// @nodoc
class _$UpdateNotificationSettingDtoCopyWithImpl<$Res>
    implements $UpdateNotificationSettingDtoCopyWith<$Res> {
  _$UpdateNotificationSettingDtoCopyWithImpl(this._self, this._then);

  final UpdateNotificationSettingDto _self;
  final $Res Function(UpdateNotificationSettingDto) _then;

/// Create a copy of UpdateNotificationSettingDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? enabled = null,Object? channel = null,}) {
  return _then(UpdateNotificationSettingDto(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as UpdateNotificationSettingDtoType,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as UpdateNotificationSettingDtoChannel,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateNotificationSettingDto].
extension UpdateNotificationSettingDtoPatterns on UpdateNotificationSettingDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateNotificationSettingDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateNotificationSettingDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateNotificationSettingDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdateNotificationSettingDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateNotificationSettingDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateNotificationSettingDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UpdateNotificationSettingDtoType type,  bool enabled,  UpdateNotificationSettingDtoChannel channel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateNotificationSettingDto() when $default != null:
return $default(_that.type,_that.enabled,_that.channel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UpdateNotificationSettingDtoType type,  bool enabled,  UpdateNotificationSettingDtoChannel channel)  $default,) {final _that = this;
switch (_that) {
case _UpdateNotificationSettingDto():
return $default(_that.type,_that.enabled,_that.channel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UpdateNotificationSettingDtoType type,  bool enabled,  UpdateNotificationSettingDtoChannel channel)?  $default,) {final _that = this;
switch (_that) {
case _UpdateNotificationSettingDto() when $default != null:
return $default(_that.type,_that.enabled,_that.channel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateNotificationSettingDto implements UpdateNotificationSettingDto {
  const _UpdateNotificationSettingDto({required this.type, required this.enabled, this.channel = UpdateNotificationSettingDtoChannel.inApp});
  factory _UpdateNotificationSettingDto.fromJson(Map<String, dynamic> json) => _$UpdateNotificationSettingDtoFromJson(json);

@override final  UpdateNotificationSettingDtoType type;
/// Выключенный тип не создаёт ни записи, ни счётчика (US-103)
@override final  bool enabled;
/// Канал. В MVP единственный, но передавать его можно уже сейчас (D-18).
@override@JsonKey() final  UpdateNotificationSettingDtoChannel channel;

/// Create a copy of UpdateNotificationSettingDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateNotificationSettingDtoCopyWith<_UpdateNotificationSettingDto> get copyWith => __$UpdateNotificationSettingDtoCopyWithImpl<_UpdateNotificationSettingDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateNotificationSettingDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateNotificationSettingDto&&(identical(other.type, type) || other.type == type)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.channel, channel) || other.channel == channel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,enabled,channel);
}

@override
String toString() {
    return 'UpdateNotificationSettingDto(type: $type, enabled: $enabled, channel: $channel)';
}


}

/// @nodoc
abstract mixin class _$UpdateNotificationSettingDtoCopyWith<$Res> implements $UpdateNotificationSettingDtoCopyWith<$Res> {
  factory _$UpdateNotificationSettingDtoCopyWith(_UpdateNotificationSettingDto value, $Res Function(_UpdateNotificationSettingDto) _then) = __$UpdateNotificationSettingDtoCopyWithImpl;
@override @useResult
$Res call({
 UpdateNotificationSettingDtoType type, bool enabled, UpdateNotificationSettingDtoChannel channel
});




}
/// @nodoc
class __$UpdateNotificationSettingDtoCopyWithImpl<$Res>
    implements _$UpdateNotificationSettingDtoCopyWith<$Res> {
  __$UpdateNotificationSettingDtoCopyWithImpl(this._self, this._then);

  final _UpdateNotificationSettingDto _self;
  final $Res Function(_UpdateNotificationSettingDto) _then;

/// Create a copy of UpdateNotificationSettingDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? enabled = null,Object? channel = null,}) {
  return _then(_UpdateNotificationSettingDto(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as UpdateNotificationSettingDtoType,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as UpdateNotificationSettingDtoChannel,
  ));
}


}

// dart format on
