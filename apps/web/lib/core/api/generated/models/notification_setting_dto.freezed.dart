// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_setting_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationSettingDto {

 NotificationSettingDtoType get type; NotificationSettingDtoChannel get channel;/// По умолчанию включены все типы (US-103)
 bool get enabled;
/// Create a copy of NotificationSettingDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationSettingDtoCopyWith<NotificationSettingDto> get copyWith => _$NotificationSettingDtoCopyWithImpl<NotificationSettingDto>(this as NotificationSettingDto, _$identity);

  /// Serializes this NotificationSettingDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationSettingDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationSettingDto&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.channel, _this.channel) || other.channel == _this.channel)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationSettingDto;
  return Object.hash(runtimeType,_this.type,_this.channel,_this.enabled);
}

@override
String toString() {
  final _this = this as NotificationSettingDto;
  return 'NotificationSettingDto(type: ${_this.type}, channel: ${_this.channel}, enabled: ${_this.enabled})';
}


}

/// @nodoc
abstract mixin class $NotificationSettingDtoCopyWith<$Res>  {
  factory $NotificationSettingDtoCopyWith(NotificationSettingDto value, $Res Function(NotificationSettingDto) _then) = _$NotificationSettingDtoCopyWithImpl;
@useResult
$Res call({
 NotificationSettingDtoType type, NotificationSettingDtoChannel channel, bool enabled
});




}
/// @nodoc
class _$NotificationSettingDtoCopyWithImpl<$Res>
    implements $NotificationSettingDtoCopyWith<$Res> {
  _$NotificationSettingDtoCopyWithImpl(this._self, this._then);

  final NotificationSettingDto _self;
  final $Res Function(NotificationSettingDto) _then;

/// Create a copy of NotificationSettingDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? channel = null,Object? enabled = null,}) {
  return _then(NotificationSettingDto(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NotificationSettingDtoType,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as NotificationSettingDtoChannel,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationSettingDto].
extension NotificationSettingDtoPatterns on NotificationSettingDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationSettingDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationSettingDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationSettingDto value)  $default,){
final _that = this;
switch (_that) {
case _NotificationSettingDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationSettingDto value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationSettingDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( NotificationSettingDtoType type,  NotificationSettingDtoChannel channel,  bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationSettingDto() when $default != null:
return $default(_that.type,_that.channel,_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( NotificationSettingDtoType type,  NotificationSettingDtoChannel channel,  bool enabled)  $default,) {final _that = this;
switch (_that) {
case _NotificationSettingDto():
return $default(_that.type,_that.channel,_that.enabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( NotificationSettingDtoType type,  NotificationSettingDtoChannel channel,  bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _NotificationSettingDto() when $default != null:
return $default(_that.type,_that.channel,_that.enabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationSettingDto implements NotificationSettingDto {
  const _NotificationSettingDto({required this.type, required this.channel, required this.enabled});
  factory _NotificationSettingDto.fromJson(Map<String, dynamic> json) => _$NotificationSettingDtoFromJson(json);

@override final  NotificationSettingDtoType type;
@override final  NotificationSettingDtoChannel channel;
/// По умолчанию включены все типы (US-103)
@override final  bool enabled;

/// Create a copy of NotificationSettingDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationSettingDtoCopyWith<_NotificationSettingDto> get copyWith => __$NotificationSettingDtoCopyWithImpl<_NotificationSettingDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationSettingDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationSettingDto&&(identical(other.type, type) || other.type == type)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,channel,enabled);
}

@override
String toString() {
    return 'NotificationSettingDto(type: $type, channel: $channel, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$NotificationSettingDtoCopyWith<$Res> implements $NotificationSettingDtoCopyWith<$Res> {
  factory _$NotificationSettingDtoCopyWith(_NotificationSettingDto value, $Res Function(_NotificationSettingDto) _then) = __$NotificationSettingDtoCopyWithImpl;
@override @useResult
$Res call({
 NotificationSettingDtoType type, NotificationSettingDtoChannel channel, bool enabled
});




}
/// @nodoc
class __$NotificationSettingDtoCopyWithImpl<$Res>
    implements _$NotificationSettingDtoCopyWith<$Res> {
  __$NotificationSettingDtoCopyWithImpl(this._self, this._then);

  final _NotificationSettingDto _self;
  final $Res Function(_NotificationSettingDto) _then;

/// Create a copy of NotificationSettingDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? channel = null,Object? enabled = null,}) {
  return _then(_NotificationSettingDto(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NotificationSettingDtoType,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as NotificationSettingDtoChannel,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
