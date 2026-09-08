// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issue_row_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IssueRowDto {

 String get key; String get title; IssueRowStatusDto get status; num get priority;/// `null` — «не оценено»
 num? get storyPoints;/// `null` — «Не назначен»
 IssueUserDto? get assignee;
/// Create a copy of IssueRowDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssueRowDtoCopyWith<IssueRowDto> get copyWith => _$IssueRowDtoCopyWithImpl<IssueRowDto>(this as IssueRowDto, _$identity);

  /// Serializes this IssueRowDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IssueRowDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssueRowDto&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.priority, _this.priority) || other.priority == _this.priority)&&(identical(other.storyPoints, _this.storyPoints) || other.storyPoints == _this.storyPoints)&&(identical(other.assignee, _this.assignee) || other.assignee == _this.assignee));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IssueRowDto;
  return Object.hash(runtimeType,_this.key,_this.title,_this.status,_this.priority,_this.storyPoints,_this.assignee);
}

@override
String toString() {
  final _this = this as IssueRowDto;
  return 'IssueRowDto(key: ${_this.key}, title: ${_this.title}, status: ${_this.status}, priority: ${_this.priority}, storyPoints: ${_this.storyPoints}, assignee: ${_this.assignee})';
}


}

/// @nodoc
abstract mixin class $IssueRowDtoCopyWith<$Res>  {
  factory $IssueRowDtoCopyWith(IssueRowDto value, $Res Function(IssueRowDto) _then) = _$IssueRowDtoCopyWithImpl;
@useResult
$Res call({
 String key, String title, IssueRowStatusDto status, num priority, num? storyPoints, IssueUserDto? assignee
});


$IssueRowStatusDtoCopyWith<$Res> get status;$IssueUserDtoCopyWith<$Res>? get assignee;

}
/// @nodoc
class _$IssueRowDtoCopyWithImpl<$Res>
    implements $IssueRowDtoCopyWith<$Res> {
  _$IssueRowDtoCopyWithImpl(this._self, this._then);

  final IssueRowDto _self;
  final $Res Function(IssueRowDto) _then;

/// Create a copy of IssueRowDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? title = null,Object? status = null,Object? priority = null,Object? storyPoints = freezed,Object? assignee = freezed,}) {
  return _then(IssueRowDto(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IssueRowStatusDto,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as num,storyPoints: freezed == storyPoints ? _self.storyPoints : storyPoints // ignore: cast_nullable_to_non_nullable
as num?,assignee: freezed == assignee ? _self.assignee : assignee // ignore: cast_nullable_to_non_nullable
as IssueUserDto?,
  ));
}
/// Create a copy of IssueRowDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueRowStatusDtoCopyWith<$Res> get status {
  
  return $IssueRowStatusDtoCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}/// Create a copy of IssueRowDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueUserDtoCopyWith<$Res>? get assignee {
    if (_self.assignee == null) {
    return null;
  }

  return $IssueUserDtoCopyWith<$Res>(_self.assignee!, (value) {
    return _then(_self.copyWith(assignee: value));
  });
}
}


/// Adds pattern-matching-related methods to [IssueRowDto].
extension IssueRowDtoPatterns on IssueRowDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssueRowDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssueRowDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssueRowDto value)  $default,){
final _that = this;
switch (_that) {
case _IssueRowDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssueRowDto value)?  $default,){
final _that = this;
switch (_that) {
case _IssueRowDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String title,  IssueRowStatusDto status,  num priority,  num? storyPoints,  IssueUserDto? assignee)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssueRowDto() when $default != null:
return $default(_that.key,_that.title,_that.status,_that.priority,_that.storyPoints,_that.assignee);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String title,  IssueRowStatusDto status,  num priority,  num? storyPoints,  IssueUserDto? assignee)  $default,) {final _that = this;
switch (_that) {
case _IssueRowDto():
return $default(_that.key,_that.title,_that.status,_that.priority,_that.storyPoints,_that.assignee);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String title,  IssueRowStatusDto status,  num priority,  num? storyPoints,  IssueUserDto? assignee)?  $default,) {final _that = this;
switch (_that) {
case _IssueRowDto() when $default != null:
return $default(_that.key,_that.title,_that.status,_that.priority,_that.storyPoints,_that.assignee);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IssueRowDto implements IssueRowDto {
  const _IssueRowDto({required this.key, required this.title, required this.status, required this.priority, required this.storyPoints, required this.assignee});
  factory _IssueRowDto.fromJson(Map<String, dynamic> json) => _$IssueRowDtoFromJson(json);

@override final  String key;
@override final  String title;
@override final  IssueRowStatusDto status;
@override final  num priority;
/// `null` — «не оценено»
@override final  num? storyPoints;
/// `null` — «Не назначен»
@override final  IssueUserDto? assignee;

/// Create a copy of IssueRowDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssueRowDtoCopyWith<_IssueRowDto> get copyWith => __$IssueRowDtoCopyWithImpl<_IssueRowDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IssueRowDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssueRowDto&&(identical(other.key, key) || other.key == key)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.storyPoints, storyPoints) || other.storyPoints == storyPoints)&&(identical(other.assignee, assignee) || other.assignee == assignee));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,key,title,status,priority,storyPoints,assignee);
}

@override
String toString() {
    return 'IssueRowDto(key: $key, title: $title, status: $status, priority: $priority, storyPoints: $storyPoints, assignee: $assignee)';
}


}

/// @nodoc
abstract mixin class _$IssueRowDtoCopyWith<$Res> implements $IssueRowDtoCopyWith<$Res> {
  factory _$IssueRowDtoCopyWith(_IssueRowDto value, $Res Function(_IssueRowDto) _then) = __$IssueRowDtoCopyWithImpl;
@override @useResult
$Res call({
 String key, String title, IssueRowStatusDto status, num priority, num? storyPoints, IssueUserDto? assignee
});


@override $IssueRowStatusDtoCopyWith<$Res> get status;@override $IssueUserDtoCopyWith<$Res>? get assignee;

}
/// @nodoc
class __$IssueRowDtoCopyWithImpl<$Res>
    implements _$IssueRowDtoCopyWith<$Res> {
  __$IssueRowDtoCopyWithImpl(this._self, this._then);

  final _IssueRowDto _self;
  final $Res Function(_IssueRowDto) _then;

/// Create a copy of IssueRowDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? title = null,Object? status = null,Object? priority = null,Object? storyPoints = freezed,Object? assignee = freezed,}) {
  return _then(_IssueRowDto(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IssueRowStatusDto,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as num,storyPoints: freezed == storyPoints ? _self.storyPoints : storyPoints // ignore: cast_nullable_to_non_nullable
as num?,assignee: freezed == assignee ? _self.assignee : assignee // ignore: cast_nullable_to_non_nullable
as IssueUserDto?,
  ));
}

/// Create a copy of IssueRowDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueRowStatusDtoCopyWith<$Res> get status {
  
  return $IssueRowStatusDtoCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}/// Create a copy of IssueRowDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueUserDtoCopyWith<$Res>? get assignee {
    if (_self.assignee == null) {
    return null;
  }

  return $IssueUserDtoCopyWith<$Res>(_self.assignee!, (value) {
    return _then(_self.copyWith(assignee: value));
  });
}
}

// dart format on
