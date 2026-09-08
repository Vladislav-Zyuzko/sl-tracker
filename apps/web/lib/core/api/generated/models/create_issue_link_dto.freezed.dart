// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_issue_link_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreateIssueLinkDto {

/// Только схемы `http` и `https` (US-47)
 String get url;/// Подпись. Пусто — интерфейс показывает сам адрес.
 String? get title;
/// Create a copy of CreateIssueLinkDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateIssueLinkDtoCopyWith<CreateIssueLinkDto> get copyWith => _$CreateIssueLinkDtoCopyWithImpl<CreateIssueLinkDto>(this as CreateIssueLinkDto, _$identity);

  /// Serializes this CreateIssueLinkDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CreateIssueLinkDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateIssueLinkDto&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.title, _this.title) || other.title == _this.title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CreateIssueLinkDto;
  return Object.hash(runtimeType,_this.url,_this.title);
}

@override
String toString() {
  final _this = this as CreateIssueLinkDto;
  return 'CreateIssueLinkDto(url: ${_this.url}, title: ${_this.title})';
}


}

/// @nodoc
abstract mixin class $CreateIssueLinkDtoCopyWith<$Res>  {
  factory $CreateIssueLinkDtoCopyWith(CreateIssueLinkDto value, $Res Function(CreateIssueLinkDto) _then) = _$CreateIssueLinkDtoCopyWithImpl;
@useResult
$Res call({
 String url, String? title
});




}
/// @nodoc
class _$CreateIssueLinkDtoCopyWithImpl<$Res>
    implements $CreateIssueLinkDtoCopyWith<$Res> {
  _$CreateIssueLinkDtoCopyWithImpl(this._self, this._then);

  final CreateIssueLinkDto _self;
  final $Res Function(CreateIssueLinkDto) _then;

/// Create a copy of CreateIssueLinkDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? title = freezed,}) {
  return _then(CreateIssueLinkDto(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateIssueLinkDto].
extension CreateIssueLinkDtoPatterns on CreateIssueLinkDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateIssueLinkDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateIssueLinkDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateIssueLinkDto value)  $default,){
final _that = this;
switch (_that) {
case _CreateIssueLinkDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateIssueLinkDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreateIssueLinkDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String? title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateIssueLinkDto() when $default != null:
return $default(_that.url,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String? title)  $default,) {final _that = this;
switch (_that) {
case _CreateIssueLinkDto():
return $default(_that.url,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String? title)?  $default,) {final _that = this;
switch (_that) {
case _CreateIssueLinkDto() when $default != null:
return $default(_that.url,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateIssueLinkDto implements CreateIssueLinkDto {
  const _CreateIssueLinkDto({required this.url, this.title});
  factory _CreateIssueLinkDto.fromJson(Map<String, dynamic> json) => _$CreateIssueLinkDtoFromJson(json);

/// Только схемы `http` и `https` (US-47)
@override final  String url;
/// Подпись. Пусто — интерфейс показывает сам адрес.
@override final  String? title;

/// Create a copy of CreateIssueLinkDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateIssueLinkDtoCopyWith<_CreateIssueLinkDto> get copyWith => __$CreateIssueLinkDtoCopyWithImpl<_CreateIssueLinkDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateIssueLinkDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateIssueLinkDto&&(identical(other.url, url) || other.url == url)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,url,title);
}

@override
String toString() {
    return 'CreateIssueLinkDto(url: $url, title: $title)';
}


}

/// @nodoc
abstract mixin class _$CreateIssueLinkDtoCopyWith<$Res> implements $CreateIssueLinkDtoCopyWith<$Res> {
  factory _$CreateIssueLinkDtoCopyWith(_CreateIssueLinkDto value, $Res Function(_CreateIssueLinkDto) _then) = __$CreateIssueLinkDtoCopyWithImpl;
@override @useResult
$Res call({
 String url, String? title
});




}
/// @nodoc
class __$CreateIssueLinkDtoCopyWithImpl<$Res>
    implements _$CreateIssueLinkDtoCopyWith<$Res> {
  __$CreateIssueLinkDtoCopyWithImpl(this._self, this._then);

  final _CreateIssueLinkDto _self;
  final $Res Function(_CreateIssueLinkDto) _then;

/// Create a copy of CreateIssueLinkDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? title = freezed,}) {
  return _then(_CreateIssueLinkDto(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
