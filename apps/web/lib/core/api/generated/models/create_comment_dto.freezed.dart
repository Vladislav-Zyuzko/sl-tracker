// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_comment_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreateCommentDto {

/// Markdown. Пустой текст и текст из одних пробелов отклоняются (US-71). Упоминание вставляется токеном `@[Имя](user:<uuid>)`, идентификатор берётся из подсказки `GET /api/issues/{key}/mention-suggestions`. Токен с посторонним пользователем **молча игнорируется**: связи и уведомления не будет, текст останется текстом (D-41).
 String get body;
/// Create a copy of CreateCommentDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateCommentDtoCopyWith<CreateCommentDto> get copyWith => _$CreateCommentDtoCopyWithImpl<CreateCommentDto>(this as CreateCommentDto, _$identity);

  /// Serializes this CreateCommentDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CreateCommentDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateCommentDto&&(identical(other.body, _this.body) || other.body == _this.body));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CreateCommentDto;
  return Object.hash(runtimeType,_this.body);
}

@override
String toString() {
  final _this = this as CreateCommentDto;
  return 'CreateCommentDto(body: ${_this.body})';
}


}

/// @nodoc
abstract mixin class $CreateCommentDtoCopyWith<$Res>  {
  factory $CreateCommentDtoCopyWith(CreateCommentDto value, $Res Function(CreateCommentDto) _then) = _$CreateCommentDtoCopyWithImpl;
@useResult
$Res call({
 String body
});




}
/// @nodoc
class _$CreateCommentDtoCopyWithImpl<$Res>
    implements $CreateCommentDtoCopyWith<$Res> {
  _$CreateCommentDtoCopyWithImpl(this._self, this._then);

  final CreateCommentDto _self;
  final $Res Function(CreateCommentDto) _then;

/// Create a copy of CreateCommentDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? body = null,}) {
  return _then(CreateCommentDto(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateCommentDto].
extension CreateCommentDtoPatterns on CreateCommentDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateCommentDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateCommentDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateCommentDto value)  $default,){
final _that = this;
switch (_that) {
case _CreateCommentDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateCommentDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreateCommentDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String body)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateCommentDto() when $default != null:
return $default(_that.body);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String body)  $default,) {final _that = this;
switch (_that) {
case _CreateCommentDto():
return $default(_that.body);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String body)?  $default,) {final _that = this;
switch (_that) {
case _CreateCommentDto() when $default != null:
return $default(_that.body);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateCommentDto implements CreateCommentDto {
  const _CreateCommentDto({required this.body});
  factory _CreateCommentDto.fromJson(Map<String, dynamic> json) => _$CreateCommentDtoFromJson(json);

/// Markdown. Пустой текст и текст из одних пробелов отклоняются (US-71). Упоминание вставляется токеном `@[Имя](user:<uuid>)`, идентификатор берётся из подсказки `GET /api/issues/{key}/mention-suggestions`. Токен с посторонним пользователем **молча игнорируется**: связи и уведомления не будет, текст останется текстом (D-41).
@override final  String body;

/// Create a copy of CreateCommentDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateCommentDtoCopyWith<_CreateCommentDto> get copyWith => __$CreateCommentDtoCopyWithImpl<_CreateCommentDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateCommentDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateCommentDto&&(identical(other.body, body) || other.body == body));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,body);
}

@override
String toString() {
    return 'CreateCommentDto(body: $body)';
}


}

/// @nodoc
abstract mixin class _$CreateCommentDtoCopyWith<$Res> implements $CreateCommentDtoCopyWith<$Res> {
  factory _$CreateCommentDtoCopyWith(_CreateCommentDto value, $Res Function(_CreateCommentDto) _then) = __$CreateCommentDtoCopyWithImpl;
@override @useResult
$Res call({
 String body
});




}
/// @nodoc
class __$CreateCommentDtoCopyWithImpl<$Res>
    implements _$CreateCommentDtoCopyWith<$Res> {
  __$CreateCommentDtoCopyWithImpl(this._self, this._then);

  final _CreateCommentDto _self;
  final $Res Function(_CreateCommentDto) _then;

/// Create a copy of CreateCommentDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? body = null,}) {
  return _then(_CreateCommentDto(
body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
