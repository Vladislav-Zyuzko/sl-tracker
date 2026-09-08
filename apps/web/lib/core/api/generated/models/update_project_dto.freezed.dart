// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_project_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateProjectDto {

/// Новое название. Переименование **не меняет** короткое имя в адресе: ранее отправленные ссылки продолжают работать (US-18).
 String? get name;/// `null` или пустая строка убирают описание.
 String? get description;
/// Create a copy of UpdateProjectDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateProjectDtoCopyWith<UpdateProjectDto> get copyWith => _$UpdateProjectDtoCopyWithImpl<UpdateProjectDto>(this as UpdateProjectDto, _$identity);

  /// Serializes this UpdateProjectDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UpdateProjectDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateProjectDto&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.description, _this.description) || other.description == _this.description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UpdateProjectDto;
  return Object.hash(runtimeType,_this.name,_this.description);
}

@override
String toString() {
  final _this = this as UpdateProjectDto;
  return 'UpdateProjectDto(name: ${_this.name}, description: ${_this.description})';
}


}

/// @nodoc
abstract mixin class $UpdateProjectDtoCopyWith<$Res>  {
  factory $UpdateProjectDtoCopyWith(UpdateProjectDto value, $Res Function(UpdateProjectDto) _then) = _$UpdateProjectDtoCopyWithImpl;
@useResult
$Res call({
 String? name, String? description
});




}
/// @nodoc
class _$UpdateProjectDtoCopyWithImpl<$Res>
    implements $UpdateProjectDtoCopyWith<$Res> {
  _$UpdateProjectDtoCopyWithImpl(this._self, this._then);

  final UpdateProjectDto _self;
  final $Res Function(UpdateProjectDto) _then;

/// Create a copy of UpdateProjectDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? description = freezed,}) {
  return _then(UpdateProjectDto(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateProjectDto].
extension UpdateProjectDtoPatterns on UpdateProjectDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateProjectDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateProjectDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateProjectDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdateProjectDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateProjectDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateProjectDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateProjectDto() when $default != null:
return $default(_that.name,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  String? description)  $default,) {final _that = this;
switch (_that) {
case _UpdateProjectDto():
return $default(_that.name,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _UpdateProjectDto() when $default != null:
return $default(_that.name,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateProjectDto implements UpdateProjectDto {
  const _UpdateProjectDto({this.name, this.description});
  factory _UpdateProjectDto.fromJson(Map<String, dynamic> json) => _$UpdateProjectDtoFromJson(json);

/// Новое название. Переименование **не меняет** короткое имя в адресе: ранее отправленные ссылки продолжают работать (US-18).
@override final  String? name;
/// `null` или пустая строка убирают описание.
@override final  String? description;

/// Create a copy of UpdateProjectDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateProjectDtoCopyWith<_UpdateProjectDto> get copyWith => __$UpdateProjectDtoCopyWithImpl<_UpdateProjectDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateProjectDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateProjectDto&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,description);
}

@override
String toString() {
    return 'UpdateProjectDto(name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class _$UpdateProjectDtoCopyWith<$Res> implements $UpdateProjectDtoCopyWith<$Res> {
  factory _$UpdateProjectDtoCopyWith(_UpdateProjectDto value, $Res Function(_UpdateProjectDto) _then) = __$UpdateProjectDtoCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? description
});




}
/// @nodoc
class __$UpdateProjectDtoCopyWithImpl<$Res>
    implements _$UpdateProjectDtoCopyWith<$Res> {
  __$UpdateProjectDtoCopyWithImpl(this._self, this._then);

  final _UpdateProjectDto _self;
  final $Res Function(_UpdateProjectDto) _then;

/// Create a copy of UpdateProjectDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? description = freezed,}) {
  return _then(_UpdateProjectDto(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
