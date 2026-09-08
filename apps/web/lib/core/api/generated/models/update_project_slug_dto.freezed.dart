// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_project_slug_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateProjectSlugDto {

/// Новое короткое имя: строчные латинские буквы, цифры и одиночные дефисы внутри. Прежнее имя остаётся занятым навсегда и продолжает открывать этот проект (US-18).
 String get slug;
/// Create a copy of UpdateProjectSlugDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateProjectSlugDtoCopyWith<UpdateProjectSlugDto> get copyWith => _$UpdateProjectSlugDtoCopyWithImpl<UpdateProjectSlugDto>(this as UpdateProjectSlugDto, _$identity);

  /// Serializes this UpdateProjectSlugDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UpdateProjectSlugDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateProjectSlugDto&&(identical(other.slug, _this.slug) || other.slug == _this.slug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UpdateProjectSlugDto;
  return Object.hash(runtimeType,_this.slug);
}

@override
String toString() {
  final _this = this as UpdateProjectSlugDto;
  return 'UpdateProjectSlugDto(slug: ${_this.slug})';
}


}

/// @nodoc
abstract mixin class $UpdateProjectSlugDtoCopyWith<$Res>  {
  factory $UpdateProjectSlugDtoCopyWith(UpdateProjectSlugDto value, $Res Function(UpdateProjectSlugDto) _then) = _$UpdateProjectSlugDtoCopyWithImpl;
@useResult
$Res call({
 String slug
});




}
/// @nodoc
class _$UpdateProjectSlugDtoCopyWithImpl<$Res>
    implements $UpdateProjectSlugDtoCopyWith<$Res> {
  _$UpdateProjectSlugDtoCopyWithImpl(this._self, this._then);

  final UpdateProjectSlugDto _self;
  final $Res Function(UpdateProjectSlugDto) _then;

/// Create a copy of UpdateProjectSlugDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,}) {
  return _then(UpdateProjectSlugDto(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateProjectSlugDto].
extension UpdateProjectSlugDtoPatterns on UpdateProjectSlugDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateProjectSlugDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateProjectSlugDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateProjectSlugDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdateProjectSlugDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateProjectSlugDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateProjectSlugDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateProjectSlugDto() when $default != null:
return $default(_that.slug);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug)  $default,) {final _that = this;
switch (_that) {
case _UpdateProjectSlugDto():
return $default(_that.slug);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug)?  $default,) {final _that = this;
switch (_that) {
case _UpdateProjectSlugDto() when $default != null:
return $default(_that.slug);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateProjectSlugDto implements UpdateProjectSlugDto {
  const _UpdateProjectSlugDto({required this.slug});
  factory _UpdateProjectSlugDto.fromJson(Map<String, dynamic> json) => _$UpdateProjectSlugDtoFromJson(json);

/// Новое короткое имя: строчные латинские буквы, цифры и одиночные дефисы внутри. Прежнее имя остаётся занятым навсегда и продолжает открывать этот проект (US-18).
@override final  String slug;

/// Create a copy of UpdateProjectSlugDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateProjectSlugDtoCopyWith<_UpdateProjectSlugDto> get copyWith => __$UpdateProjectSlugDtoCopyWithImpl<_UpdateProjectSlugDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateProjectSlugDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateProjectSlugDto&&(identical(other.slug, slug) || other.slug == slug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,slug);
}

@override
String toString() {
    return 'UpdateProjectSlugDto(slug: $slug)';
}


}

/// @nodoc
abstract mixin class _$UpdateProjectSlugDtoCopyWith<$Res> implements $UpdateProjectSlugDtoCopyWith<$Res> {
  factory _$UpdateProjectSlugDtoCopyWith(_UpdateProjectSlugDto value, $Res Function(_UpdateProjectSlugDto) _then) = __$UpdateProjectSlugDtoCopyWithImpl;
@override @useResult
$Res call({
 String slug
});




}
/// @nodoc
class __$UpdateProjectSlugDtoCopyWithImpl<$Res>
    implements _$UpdateProjectSlugDtoCopyWith<$Res> {
  __$UpdateProjectSlugDtoCopyWithImpl(this._self, this._then);

  final _UpdateProjectSlugDto _self;
  final $Res Function(_UpdateProjectSlugDto) _then;

/// Create a copy of UpdateProjectSlugDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,}) {
  return _then(_UpdateProjectSlugDto(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
