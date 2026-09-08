// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issue_link_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IssueLinkDto {

 String get id; String get url;/// Подпись. Пусто — интерфейс показывает сам адрес (US-47).
 String? get title; IssueUserDto get createdBy; DateTime get createdAt;
/// Create a copy of IssueLinkDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueLinkDtoCopyWith<IssueLinkDto> get copyWith => _$IssueLinkDtoCopyWithImpl<IssueLinkDto>(this as IssueLinkDto, _$identity);

  /// Serializes this IssueLinkDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IssueLinkDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssueLinkDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IssueLinkDto;
  return Object.hash(runtimeType,_this.id,_this.url,_this.title,_this.createdBy,_this.createdAt);
}

@override
String toString() {
  final _this = this as IssueLinkDto;
  return 'IssueLinkDto(id: ${_this.id}, url: ${_this.url}, title: ${_this.title}, createdBy: ${_this.createdBy}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $IssueLinkDtoCopyWith<$Res>  {
  factory $IssueLinkDtoCopyWith(IssueLinkDto value, $Res Function(IssueLinkDto) _then) = _$IssueLinkDtoCopyWithImpl;
@useResult
$Res call({
 String id, String url, String? title, IssueUserDto createdBy, DateTime createdAt
});


$IssueUserDtoCopyWith<$Res> get createdBy;

}
/// @nodoc
class _$IssueLinkDtoCopyWithImpl<$Res>
    implements $IssueLinkDtoCopyWith<$Res> {
  _$IssueLinkDtoCopyWithImpl(this._self, this._then);

  final IssueLinkDto _self;
  final $Res Function(IssueLinkDto) _then;

/// Create a copy of IssueLinkDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? url = null,Object? title = freezed,Object? createdBy = null,Object? createdAt = null,}) {
  return _then(IssueLinkDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as IssueUserDto,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of IssueLinkDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueUserDtoCopyWith<$Res> get createdBy {
  
  return $IssueUserDtoCopyWith<$Res>(_self.createdBy, (value) {
    return _then(_self.copyWith(createdBy: value));
  });
}
}


/// Adds pattern-matching-related methods to [IssueLinkDto].
extension IssueLinkDtoPatterns on IssueLinkDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssueLinkDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssueLinkDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssueLinkDto value)  $default,){
final _that = this;
switch (_that) {
case _IssueLinkDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssueLinkDto value)?  $default,){
final _that = this;
switch (_that) {
case _IssueLinkDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String url,  String? title,  IssueUserDto createdBy,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssueLinkDto() when $default != null:
return $default(_that.id,_that.url,_that.title,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String url,  String? title,  IssueUserDto createdBy,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _IssueLinkDto():
return $default(_that.id,_that.url,_that.title,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String url,  String? title,  IssueUserDto createdBy,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _IssueLinkDto() when $default != null:
return $default(_that.id,_that.url,_that.title,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssueLinkDto implements IssueLinkDto {
  const _IssueLinkDto({required this.id, required this.url, required this.title, required this.createdBy, required this.createdAt});
  factory _IssueLinkDto.fromJson(Map<String, dynamic> json) => _$IssueLinkDtoFromJson(json);

@override final  String id;
@override final  String url;
/// Подпись. Пусто — интерфейс показывает сам адрес (US-47).
@override final  String? title;
@override final  IssueUserDto createdBy;
@override final  DateTime createdAt;

/// Create a copy of IssueLinkDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueLinkDtoCopyWith<_IssueLinkDto> get copyWith => __$IssueLinkDtoCopyWithImpl<_IssueLinkDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueLinkDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssueLinkDto&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,url,title,createdBy,createdAt);
}

@override
String toString() {
    return 'IssueLinkDto(id: $id, url: $url, title: $title, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$IssueLinkDtoCopyWith<$Res> implements $IssueLinkDtoCopyWith<$Res> {
  factory _$IssueLinkDtoCopyWith(_IssueLinkDto value, $Res Function(_IssueLinkDto) _then) = __$IssueLinkDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String url, String? title, IssueUserDto createdBy, DateTime createdAt
});


@override $IssueUserDtoCopyWith<$Res> get createdBy;

}
/// @nodoc
class __$IssueLinkDtoCopyWithImpl<$Res>
    implements _$IssueLinkDtoCopyWith<$Res> {
  __$IssueLinkDtoCopyWithImpl(this._self, this._then);

  final _IssueLinkDto _self;
  final $Res Function(_IssueLinkDto) _then;

/// Create a copy of IssueLinkDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? url = null,Object? title = freezed,Object? createdBy = null,Object? createdAt = null,}) {
  return _then(_IssueLinkDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as IssueUserDto,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of IssueLinkDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueUserDtoCopyWith<$Res> get createdBy {
  
  return $IssueUserDtoCopyWith<$Res>(_self.createdBy, (value) {
    return _then(_self.copyWith(createdBy: value));
  });
}
}

// dart format on
