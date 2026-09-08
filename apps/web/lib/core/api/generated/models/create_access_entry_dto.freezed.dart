// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_access_entry_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreateAccessEntryDto {

/// Адрес аккаунта Яндекса. Регистр не важен: адрес приводится к нижнему регистру. Формат проверяется сервером, некорректный — 400 с кодом `invalid_email`.
 String get email;
/// Create a copy of CreateAccessEntryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateAccessEntryDtoCopyWith<CreateAccessEntryDto> get copyWith => _$CreateAccessEntryDtoCopyWithImpl<CreateAccessEntryDto>(this as CreateAccessEntryDto, _$identity);

  /// Serializes this CreateAccessEntryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CreateAccessEntryDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateAccessEntryDto&&(identical(other.email, _this.email) || other.email == _this.email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CreateAccessEntryDto;
  return Object.hash(runtimeType,_this.email);
}

@override
String toString() {
  final _this = this as CreateAccessEntryDto;
  return 'CreateAccessEntryDto(email: ${_this.email})';
}


}

/// @nodoc
abstract mixin class $CreateAccessEntryDtoCopyWith<$Res>  {
  factory $CreateAccessEntryDtoCopyWith(CreateAccessEntryDto value, $Res Function(CreateAccessEntryDto) _then) = _$CreateAccessEntryDtoCopyWithImpl;
@useResult
$Res call({
 String email
});




}
/// @nodoc
class _$CreateAccessEntryDtoCopyWithImpl<$Res>
    implements $CreateAccessEntryDtoCopyWith<$Res> {
  _$CreateAccessEntryDtoCopyWithImpl(this._self, this._then);

  final CreateAccessEntryDto _self;
  final $Res Function(CreateAccessEntryDto) _then;

/// Create a copy of CreateAccessEntryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,}) {
  return _then(CreateAccessEntryDto(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateAccessEntryDto].
extension CreateAccessEntryDtoPatterns on CreateAccessEntryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateAccessEntryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateAccessEntryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateAccessEntryDto value)  $default,){
final _that = this;
switch (_that) {
case _CreateAccessEntryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateAccessEntryDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreateAccessEntryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateAccessEntryDto() when $default != null:
return $default(_that.email);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email)  $default,) {final _that = this;
switch (_that) {
case _CreateAccessEntryDto():
return $default(_that.email);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email)?  $default,) {final _that = this;
switch (_that) {
case _CreateAccessEntryDto() when $default != null:
return $default(_that.email);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateAccessEntryDto implements CreateAccessEntryDto {
  const _CreateAccessEntryDto({required this.email});
  factory _CreateAccessEntryDto.fromJson(Map<String, dynamic> json) => _$CreateAccessEntryDtoFromJson(json);

/// Адрес аккаунта Яндекса. Регистр не важен: адрес приводится к нижнему регистру. Формат проверяется сервером, некорректный — 400 с кодом `invalid_email`.
@override final  String email;

/// Create a copy of CreateAccessEntryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateAccessEntryDtoCopyWith<_CreateAccessEntryDto> get copyWith => __$CreateAccessEntryDtoCopyWithImpl<_CreateAccessEntryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateAccessEntryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateAccessEntryDto&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,email);
}

@override
String toString() {
    return 'CreateAccessEntryDto(email: $email)';
}


}

/// @nodoc
abstract mixin class _$CreateAccessEntryDtoCopyWith<$Res> implements $CreateAccessEntryDtoCopyWith<$Res> {
  factory _$CreateAccessEntryDtoCopyWith(_CreateAccessEntryDto value, $Res Function(_CreateAccessEntryDto) _then) = __$CreateAccessEntryDtoCopyWithImpl;
@override @useResult
$Res call({
 String email
});




}
/// @nodoc
class __$CreateAccessEntryDtoCopyWithImpl<$Res>
    implements _$CreateAccessEntryDtoCopyWith<$Res> {
  __$CreateAccessEntryDtoCopyWithImpl(this._self, this._then);

  final _CreateAccessEntryDto _self;
  final $Res Function(_CreateAccessEntryDto) _then;

/// Create a copy of CreateAccessEntryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,}) {
  return _then(_CreateAccessEntryDto(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
