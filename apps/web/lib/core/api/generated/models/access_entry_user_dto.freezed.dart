// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'access_entry_user_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AccessEntryUserDto {

 String get id; String get displayName;/// Аватар из Яндекс ID
 String? get avatarUrl;
/// Create a copy of AccessEntryUserDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccessEntryUserDtoCopyWith<AccessEntryUserDto> get copyWith => _$AccessEntryUserDtoCopyWithImpl<AccessEntryUserDto>(this as AccessEntryUserDto, _$identity);

  /// Serializes this AccessEntryUserDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AccessEntryUserDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccessEntryUserDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AccessEntryUserDto;
  return Object.hash(runtimeType,_this.id,_this.displayName,_this.avatarUrl);
}

@override
String toString() {
  final _this = this as AccessEntryUserDto;
  return 'AccessEntryUserDto(id: ${_this.id}, displayName: ${_this.displayName}, avatarUrl: ${_this.avatarUrl})';
}


}

/// @nodoc
abstract mixin class $AccessEntryUserDtoCopyWith<$Res>  {
  factory $AccessEntryUserDtoCopyWith(AccessEntryUserDto value, $Res Function(AccessEntryUserDto) _then) = _$AccessEntryUserDtoCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String? avatarUrl
});




}
/// @nodoc
class _$AccessEntryUserDtoCopyWithImpl<$Res>
    implements $AccessEntryUserDtoCopyWith<$Res> {
  _$AccessEntryUserDtoCopyWithImpl(this._self, this._then);

  final AccessEntryUserDto _self;
  final $Res Function(AccessEntryUserDto) _then;

/// Create a copy of AccessEntryUserDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? avatarUrl = freezed,}) {
  return _then(AccessEntryUserDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AccessEntryUserDto].
extension AccessEntryUserDtoPatterns on AccessEntryUserDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccessEntryUserDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccessEntryUserDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccessEntryUserDto value)  $default,){
final _that = this;
switch (_that) {
case _AccessEntryUserDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccessEntryUserDto value)?  $default,){
final _that = this;
switch (_that) {
case _AccessEntryUserDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String? avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccessEntryUserDto() when $default != null:
return $default(_that.id,_that.displayName,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String? avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _AccessEntryUserDto():
return $default(_that.id,_that.displayName,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String? avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _AccessEntryUserDto() when $default != null:
return $default(_that.id,_that.displayName,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AccessEntryUserDto implements AccessEntryUserDto {
  const _AccessEntryUserDto({required this.id, required this.displayName, required this.avatarUrl});
  factory _AccessEntryUserDto.fromJson(Map<String, dynamic> json) => _$AccessEntryUserDtoFromJson(json);

@override final  String id;
@override final  String displayName;
/// Аватар из Яндекс ID
@override final  String? avatarUrl;

/// Create a copy of AccessEntryUserDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccessEntryUserDtoCopyWith<_AccessEntryUserDto> get copyWith => __$AccessEntryUserDtoCopyWithImpl<_AccessEntryUserDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccessEntryUserDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccessEntryUserDto&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,displayName,avatarUrl);
}

@override
String toString() {
    return 'AccessEntryUserDto(id: $id, displayName: $displayName, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$AccessEntryUserDtoCopyWith<$Res> implements $AccessEntryUserDtoCopyWith<$Res> {
  factory _$AccessEntryUserDtoCopyWith(_AccessEntryUserDto value, $Res Function(_AccessEntryUserDto) _then) = __$AccessEntryUserDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String? avatarUrl
});




}
/// @nodoc
class __$AccessEntryUserDtoCopyWithImpl<$Res>
    implements _$AccessEntryUserDtoCopyWith<$Res> {
  __$AccessEntryUserDtoCopyWithImpl(this._self, this._then);

  final _AccessEntryUserDto _self;
  final $Res Function(_AccessEntryUserDto) _then;

/// Create a copy of AccessEntryUserDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? avatarUrl = freezed,}) {
  return _then(_AccessEntryUserDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
