// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'my_issue_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MyIssueDto {

/// Публичный ключ задачи, он же адрес
 String get key;/// Тема задачи
 String get title;/// Приоритет 0–100 с шагом 10. Список отсортирован по нему по убыванию.
 num get priority; IssueStatusDto get status;
/// Create a copy of MyIssueDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MyIssueDtoCopyWith<MyIssueDto> get copyWith => _$MyIssueDtoCopyWithImpl<MyIssueDto>(this as MyIssueDto, _$identity);

  /// Serializes this MyIssueDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MyIssueDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyIssueDto&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.priority, _this.priority) || other.priority == _this.priority)&&(identical(other.status, _this.status) || other.status == _this.status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MyIssueDto;
  return Object.hash(runtimeType,_this.key,_this.title,_this.priority,_this.status);
}

@override
String toString() {
  final _this = this as MyIssueDto;
  return 'MyIssueDto(key: ${_this.key}, title: ${_this.title}, priority: ${_this.priority}, status: ${_this.status})';
}


}

/// @nodoc
abstract mixin class $MyIssueDtoCopyWith<$Res>  {
  factory $MyIssueDtoCopyWith(MyIssueDto value, $Res Function(MyIssueDto) _then) = _$MyIssueDtoCopyWithImpl;
@useResult
$Res call({
 String key, String title, num priority, IssueStatusDto status
});


$IssueStatusDtoCopyWith<$Res> get status;

}
/// @nodoc
class _$MyIssueDtoCopyWithImpl<$Res>
    implements $MyIssueDtoCopyWith<$Res> {
  _$MyIssueDtoCopyWithImpl(this._self, this._then);

  final MyIssueDto _self;
  final $Res Function(MyIssueDto) _then;

/// Create a copy of MyIssueDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? title = null,Object? priority = null,Object? status = null,}) {
  return _then(MyIssueDto(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as num,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IssueStatusDto,
  ));
}
/// Create a copy of MyIssueDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueStatusDtoCopyWith<$Res> get status {
  
  return $IssueStatusDtoCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}
}


/// Adds pattern-matching-related methods to [MyIssueDto].
extension MyIssueDtoPatterns on MyIssueDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MyIssueDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MyIssueDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MyIssueDto value)  $default,){
final _that = this;
switch (_that) {
case _MyIssueDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MyIssueDto value)?  $default,){
final _that = this;
switch (_that) {
case _MyIssueDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String title,  num priority,  IssueStatusDto status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MyIssueDto() when $default != null:
return $default(_that.key,_that.title,_that.priority,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String title,  num priority,  IssueStatusDto status)  $default,) {final _that = this;
switch (_that) {
case _MyIssueDto():
return $default(_that.key,_that.title,_that.priority,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String title,  num priority,  IssueStatusDto status)?  $default,) {final _that = this;
switch (_that) {
case _MyIssueDto() when $default != null:
return $default(_that.key,_that.title,_that.priority,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MyIssueDto implements MyIssueDto {
  const _MyIssueDto({required this.key, required this.title, required this.priority, required this.status});
  factory _MyIssueDto.fromJson(Map<String, dynamic> json) => _$MyIssueDtoFromJson(json);

/// Публичный ключ задачи, он же адрес
@override final  String key;
/// Тема задачи
@override final  String title;
/// Приоритет 0–100 с шагом 10. Список отсортирован по нему по убыванию.
@override final  num priority;
@override final  IssueStatusDto status;

/// Create a copy of MyIssueDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MyIssueDtoCopyWith<_MyIssueDto> get copyWith => __$MyIssueDtoCopyWithImpl<_MyIssueDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MyIssueDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MyIssueDto&&(identical(other.key, key) || other.key == key)&&(identical(other.title, title) || other.title == title)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,key,title,priority,status);
}

@override
String toString() {
    return 'MyIssueDto(key: $key, title: $title, priority: $priority, status: $status)';
}


}

/// @nodoc
abstract mixin class _$MyIssueDtoCopyWith<$Res> implements $MyIssueDtoCopyWith<$Res> {
  factory _$MyIssueDtoCopyWith(_MyIssueDto value, $Res Function(_MyIssueDto) _then) = __$MyIssueDtoCopyWithImpl;
@override @useResult
$Res call({
 String key, String title, num priority, IssueStatusDto status
});


@override $IssueStatusDtoCopyWith<$Res> get status;

}
/// @nodoc
class __$MyIssueDtoCopyWithImpl<$Res>
    implements _$MyIssueDtoCopyWith<$Res> {
  __$MyIssueDtoCopyWithImpl(this._self, this._then);

  final _MyIssueDto _self;
  final $Res Function(_MyIssueDto) _then;

/// Create a copy of MyIssueDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? title = null,Object? priority = null,Object? status = null,}) {
  return _then(_MyIssueDto(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as num,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as IssueStatusDto,
  ));
}

/// Create a copy of MyIssueDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueStatusDtoCopyWith<$Res> get status {
  
  return $IssueStatusDtoCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}
}

// dart format on
