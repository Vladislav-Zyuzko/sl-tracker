// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mention_suggestion_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MentionSuggestionDto {

/// Подставляется в токен `@[Имя](user:<uuid>)`
 String get id; String get displayName;/// Показывается второй строкой **только при совпадении имён** (US-74). Адрес виден лишь по участникам того же проекта — там он и так есть на вкладке «Участники».
 String get email; String? get avatarUrl;
/// Create a copy of MentionSuggestionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MentionSuggestionDtoCopyWith<MentionSuggestionDto> get copyWith => _$MentionSuggestionDtoCopyWithImpl<MentionSuggestionDto>(this as MentionSuggestionDto, _$identity);

  /// Serializes this MentionSuggestionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MentionSuggestionDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MentionSuggestionDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MentionSuggestionDto;
  return Object.hash(runtimeType,_this.id,_this.displayName,_this.email,_this.avatarUrl);
}

@override
String toString() {
  final _this = this as MentionSuggestionDto;
  return 'MentionSuggestionDto(id: ${_this.id}, displayName: ${_this.displayName}, email: ${_this.email}, avatarUrl: ${_this.avatarUrl})';
}


}

/// @nodoc
abstract mixin class $MentionSuggestionDtoCopyWith<$Res>  {
  factory $MentionSuggestionDtoCopyWith(MentionSuggestionDto value, $Res Function(MentionSuggestionDto) _then) = _$MentionSuggestionDtoCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String email, String? avatarUrl
});




}
/// @nodoc
class _$MentionSuggestionDtoCopyWithImpl<$Res>
    implements $MentionSuggestionDtoCopyWith<$Res> {
  _$MentionSuggestionDtoCopyWithImpl(this._self, this._then);

  final MentionSuggestionDto _self;
  final $Res Function(MentionSuggestionDto) _then;

/// Create a copy of MentionSuggestionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? email = null,Object? avatarUrl = freezed,}) {
  return _then(MentionSuggestionDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MentionSuggestionDto].
extension MentionSuggestionDtoPatterns on MentionSuggestionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MentionSuggestionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MentionSuggestionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MentionSuggestionDto value)  $default,){
final _that = this;
switch (_that) {
case _MentionSuggestionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MentionSuggestionDto value)?  $default,){
final _that = this;
switch (_that) {
case _MentionSuggestionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  String email,  String? avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MentionSuggestionDto() when $default != null:
return $default(_that.id,_that.displayName,_that.email,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  String email,  String? avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _MentionSuggestionDto():
return $default(_that.id,_that.displayName,_that.email,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  String email,  String? avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _MentionSuggestionDto() when $default != null:
return $default(_that.id,_that.displayName,_that.email,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MentionSuggestionDto implements MentionSuggestionDto {
  const _MentionSuggestionDto({required this.id, required this.displayName, required this.email, required this.avatarUrl});
  factory _MentionSuggestionDto.fromJson(Map<String, dynamic> json) => _$MentionSuggestionDtoFromJson(json);

/// Подставляется в токен `@[Имя](user:<uuid>)`
@override final  String id;
@override final  String displayName;
/// Показывается второй строкой **только при совпадении имён** (US-74). Адрес виден лишь по участникам того же проекта — там он и так есть на вкладке «Участники».
@override final  String email;
@override final  String? avatarUrl;

/// Create a copy of MentionSuggestionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MentionSuggestionDtoCopyWith<_MentionSuggestionDto> get copyWith => __$MentionSuggestionDtoCopyWithImpl<_MentionSuggestionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MentionSuggestionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MentionSuggestionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,displayName,email,avatarUrl);
}

@override
String toString() {
    return 'MentionSuggestionDto(id: $id, displayName: $displayName, email: $email, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$MentionSuggestionDtoCopyWith<$Res> implements $MentionSuggestionDtoCopyWith<$Res> {
  factory _$MentionSuggestionDtoCopyWith(_MentionSuggestionDto value, $Res Function(_MentionSuggestionDto) _then) = __$MentionSuggestionDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String email, String? avatarUrl
});




}
/// @nodoc
class __$MentionSuggestionDtoCopyWithImpl<$Res>
    implements _$MentionSuggestionDtoCopyWith<$Res> {
  __$MentionSuggestionDtoCopyWithImpl(this._self, this._then);

  final _MentionSuggestionDto _self;
  final $Res Function(_MentionSuggestionDto) _then;

/// Create a copy of MentionSuggestionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? email = null,Object? avatarUrl = freezed,}) {
  return _then(_MentionSuggestionDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
