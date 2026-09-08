// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dependency_health_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DependencyHealthDto {

/// Доступна ли зависимость
 DependencyHealthDtoStatus get status;/// Время ответа зависимости, мс
 num get latencyMs;/// Причина недоступности в общих словах. Внутренние детали и стектрейсы наружу не выходят — они в логах сервера.
 String? get error;
/// Create a copy of DependencyHealthDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DependencyHealthDtoCopyWith<DependencyHealthDto> get copyWith => _$DependencyHealthDtoCopyWithImpl<DependencyHealthDto>(this as DependencyHealthDto, _$identity);

  /// Serializes this DependencyHealthDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DependencyHealthDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DependencyHealthDto&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.latencyMs, _this.latencyMs) || other.latencyMs == _this.latencyMs)&&(identical(other.error, _this.error) || other.error == _this.error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DependencyHealthDto;
  return Object.hash(runtimeType,_this.status,_this.latencyMs,_this.error);
}

@override
String toString() {
  final _this = this as DependencyHealthDto;
  return 'DependencyHealthDto(status: ${_this.status}, latencyMs: ${_this.latencyMs}, error: ${_this.error})';
}


}

/// @nodoc
abstract mixin class $DependencyHealthDtoCopyWith<$Res>  {
  factory $DependencyHealthDtoCopyWith(DependencyHealthDto value, $Res Function(DependencyHealthDto) _then) = _$DependencyHealthDtoCopyWithImpl;
@useResult
$Res call({
 DependencyHealthDtoStatus status, num latencyMs, String? error
});




}
/// @nodoc
class _$DependencyHealthDtoCopyWithImpl<$Res>
    implements $DependencyHealthDtoCopyWith<$Res> {
  _$DependencyHealthDtoCopyWithImpl(this._self, this._then);

  final DependencyHealthDto _self;
  final $Res Function(DependencyHealthDto) _then;

/// Create a copy of DependencyHealthDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? latencyMs = null,Object? error = freezed,}) {
  return _then(DependencyHealthDto(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DependencyHealthDtoStatus,latencyMs: null == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as num,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DependencyHealthDto].
extension DependencyHealthDtoPatterns on DependencyHealthDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DependencyHealthDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DependencyHealthDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DependencyHealthDto value)  $default,){
final _that = this;
switch (_that) {
case _DependencyHealthDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DependencyHealthDto value)?  $default,){
final _that = this;
switch (_that) {
case _DependencyHealthDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DependencyHealthDtoStatus status,  num latencyMs,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DependencyHealthDto() when $default != null:
return $default(_that.status,_that.latencyMs,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DependencyHealthDtoStatus status,  num latencyMs,  String? error)  $default,) {final _that = this;
switch (_that) {
case _DependencyHealthDto():
return $default(_that.status,_that.latencyMs,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DependencyHealthDtoStatus status,  num latencyMs,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _DependencyHealthDto() when $default != null:
return $default(_that.status,_that.latencyMs,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DependencyHealthDto implements DependencyHealthDto {
  const _DependencyHealthDto({required this.status, required this.latencyMs, this.error});
  factory _DependencyHealthDto.fromJson(Map<String, dynamic> json) => _$DependencyHealthDtoFromJson(json);

/// Доступна ли зависимость
@override final  DependencyHealthDtoStatus status;
/// Время ответа зависимости, мс
@override final  num latencyMs;
/// Причина недоступности в общих словах. Внутренние детали и стектрейсы наружу не выходят — они в логах сервера.
@override final  String? error;

/// Create a copy of DependencyHealthDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DependencyHealthDtoCopyWith<_DependencyHealthDto> get copyWith => __$DependencyHealthDtoCopyWithImpl<_DependencyHealthDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DependencyHealthDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DependencyHealthDto&&(identical(other.status, status) || other.status == status)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,status,latencyMs,error);
}

@override
String toString() {
    return 'DependencyHealthDto(status: $status, latencyMs: $latencyMs, error: $error)';
}


}

/// @nodoc
abstract mixin class _$DependencyHealthDtoCopyWith<$Res> implements $DependencyHealthDtoCopyWith<$Res> {
  factory _$DependencyHealthDtoCopyWith(_DependencyHealthDto value, $Res Function(_DependencyHealthDto) _then) = __$DependencyHealthDtoCopyWithImpl;
@override @useResult
$Res call({
 DependencyHealthDtoStatus status, num latencyMs, String? error
});




}
/// @nodoc
class __$DependencyHealthDtoCopyWithImpl<$Res>
    implements _$DependencyHealthDtoCopyWith<$Res> {
  __$DependencyHealthDtoCopyWithImpl(this._self, this._then);

  final _DependencyHealthDto _self;
  final $Res Function(_DependencyHealthDto) _then;

/// Create a copy of DependencyHealthDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? latencyMs = null,Object? error = freezed,}) {
  return _then(_DependencyHealthDto(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DependencyHealthDtoStatus,latencyMs: null == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as num,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
