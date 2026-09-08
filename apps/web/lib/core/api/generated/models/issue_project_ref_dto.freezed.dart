// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issue_project_ref_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IssueProjectRefDto {

 String get slug; String get name;
/// Create a copy of IssueProjectRefDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueProjectRefDtoCopyWith<IssueProjectRefDto> get copyWith => _$IssueProjectRefDtoCopyWithImpl<IssueProjectRefDto>(this as IssueProjectRefDto, _$identity);

  /// Serializes this IssueProjectRefDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IssueProjectRefDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssueProjectRefDto&&(identical(other.slug, _this.slug) || other.slug == _this.slug)&&(identical(other.name, _this.name) || other.name == _this.name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IssueProjectRefDto;
  return Object.hash(runtimeType,_this.slug,_this.name);
}

@override
String toString() {
  final _this = this as IssueProjectRefDto;
  return 'IssueProjectRefDto(slug: ${_this.slug}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $IssueProjectRefDtoCopyWith<$Res>  {
  factory $IssueProjectRefDtoCopyWith(IssueProjectRefDto value, $Res Function(IssueProjectRefDto) _then) = _$IssueProjectRefDtoCopyWithImpl;
@useResult
$Res call({
 String slug, String name
});




}
/// @nodoc
class _$IssueProjectRefDtoCopyWithImpl<$Res>
    implements $IssueProjectRefDtoCopyWith<$Res> {
  _$IssueProjectRefDtoCopyWithImpl(this._self, this._then);

  final IssueProjectRefDto _self;
  final $Res Function(IssueProjectRefDto) _then;

/// Create a copy of IssueProjectRefDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? name = null,}) {
  return _then(IssueProjectRefDto(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [IssueProjectRefDto].
extension IssueProjectRefDtoPatterns on IssueProjectRefDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssueProjectRefDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssueProjectRefDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssueProjectRefDto value)  $default,){
final _that = this;
switch (_that) {
case _IssueProjectRefDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssueProjectRefDto value)?  $default,){
final _that = this;
switch (_that) {
case _IssueProjectRefDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssueProjectRefDto() when $default != null:
return $default(_that.slug,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  String name)  $default,) {final _that = this;
switch (_that) {
case _IssueProjectRefDto():
return $default(_that.slug,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  String name)?  $default,) {final _that = this;
switch (_that) {
case _IssueProjectRefDto() when $default != null:
return $default(_that.slug,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssueProjectRefDto implements IssueProjectRefDto {
  const _IssueProjectRefDto({required this.slug, required this.name});
  factory _IssueProjectRefDto.fromJson(Map<String, dynamic> json) => _$IssueProjectRefDtoFromJson(json);

@override final  String slug;
@override final  String name;

/// Create a copy of IssueProjectRefDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueProjectRefDtoCopyWith<_IssueProjectRefDto> get copyWith => __$IssueProjectRefDtoCopyWithImpl<_IssueProjectRefDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueProjectRefDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssueProjectRefDto&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,slug,name);
}

@override
String toString() {
    return 'IssueProjectRefDto(slug: $slug, name: $name)';
}


}

/// @nodoc
abstract mixin class _$IssueProjectRefDtoCopyWith<$Res> implements $IssueProjectRefDtoCopyWith<$Res> {
  factory _$IssueProjectRefDtoCopyWith(_IssueProjectRefDto value, $Res Function(_IssueProjectRefDto) _then) = __$IssueProjectRefDtoCopyWithImpl;
@override @useResult
$Res call({
 String slug, String name
});




}
/// @nodoc
class __$IssueProjectRefDtoCopyWithImpl<$Res>
    implements _$IssueProjectRefDtoCopyWith<$Res> {
  __$IssueProjectRefDtoCopyWithImpl(this._self, this._then);

  final _IssueProjectRefDto _self;
  final $Res Function(_IssueProjectRefDto) _then;

/// Create a copy of IssueProjectRefDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? name = null,}) {
  return _then(_IssueProjectRefDto(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
