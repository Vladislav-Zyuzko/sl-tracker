// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment_list_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CommentListDto {

/// В хронологическом порядке, **сначала старые** (US-70)
 List<CommentDto> get items;/// Курсор **более ранних** комментариев — тех, что выше по ленте («Показать более ранние»). Страница без курсора отдаёт последние комментарии задачи. `null` — более ранних нет.
 String? get nextCursor;/// Всего комментариев у задачи — счётчик на вкладке
 num get total;/// Может ли запросивший написать комментарий. `false` у читателя: поле ввода не показывается, а прямой вызов API вернёт 403 (US-71, D-29).
 bool get canComment;
/// Create a copy of CommentListDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentListDtoCopyWith<CommentListDto> get copyWith => _$CommentListDtoCopyWithImpl<CommentListDto>(this as CommentListDto, _$identity);

  /// Serializes this CommentListDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CommentListDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentListDto&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor)&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.canComment, _this.canComment) || other.canComment == _this.canComment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CommentListDto;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.nextCursor,_this.total,_this.canComment);
}

@override
String toString() {
  final _this = this as CommentListDto;
  return 'CommentListDto(items: ${_this.items}, nextCursor: ${_this.nextCursor}, total: ${_this.total}, canComment: ${_this.canComment})';
}


}

/// @nodoc
abstract mixin class $CommentListDtoCopyWith<$Res>  {
  factory $CommentListDtoCopyWith(CommentListDto value, $Res Function(CommentListDto) _then) = _$CommentListDtoCopyWithImpl;
@useResult
$Res call({
 List<CommentDto> items, String? nextCursor, num total, bool canComment
});




}
/// @nodoc
class _$CommentListDtoCopyWithImpl<$Res>
    implements $CommentListDtoCopyWith<$Res> {
  _$CommentListDtoCopyWithImpl(this._self, this._then);

  final CommentListDto _self;
  final $Res Function(CommentListDto) _then;

/// Create a copy of CommentListDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,Object? total = null,Object? canComment = null,}) {
  return _then(CommentListDto(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CommentDto>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,canComment: null == canComment ? _self.canComment : canComment // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentListDto].
extension CommentListDtoPatterns on CommentListDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentListDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentListDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentListDto value)  $default,){
final _that = this;
switch (_that) {
case _CommentListDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentListDto value)?  $default,){
final _that = this;
switch (_that) {
case _CommentListDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CommentDto> items,  String? nextCursor,  num total,  bool canComment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentListDto() when $default != null:
return $default(_that.items,_that.nextCursor,_that.total,_that.canComment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CommentDto> items,  String? nextCursor,  num total,  bool canComment)  $default,) {final _that = this;
switch (_that) {
case _CommentListDto():
return $default(_that.items,_that.nextCursor,_that.total,_that.canComment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CommentDto> items,  String? nextCursor,  num total,  bool canComment)?  $default,) {final _that = this;
switch (_that) {
case _CommentListDto() when $default != null:
return $default(_that.items,_that.nextCursor,_that.total,_that.canComment);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentListDto implements CommentListDto {
  const _CommentListDto({required  List<CommentDto> items, required this.nextCursor, required this.total, required this.canComment}): _items = items;
  factory _CommentListDto.fromJson(Map<String, dynamic> json) => _$CommentListDtoFromJson(json);

/// В хронологическом порядке, **сначала старые** (US-70)
 final  List<CommentDto> _items;
/// В хронологическом порядке, **сначала старые** (US-70)
@override List<CommentDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Курсор **более ранних** комментариев — тех, что выше по ленте («Показать более ранние»). Страница без курсора отдаёт последние комментарии задачи. `null` — более ранних нет.
@override final  String? nextCursor;
/// Всего комментариев у задачи — счётчик на вкладке
@override final  num total;
/// Может ли запросивший написать комментарий. `false` у читателя: поле ввода не показывается, а прямой вызов API вернёт 403 (US-71, D-29).
@override final  bool canComment;

/// Create a copy of CommentListDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentListDtoCopyWith<_CommentListDto> get copyWith => __$CommentListDtoCopyWithImpl<_CommentListDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentListDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentListDto&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.total, total) || other.total == total)&&(identical(other.canComment, canComment) || other.canComment == canComment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor,total,canComment);
}

@override
String toString() {
    return 'CommentListDto(items: $items, nextCursor: $nextCursor, total: $total, canComment: $canComment)';
}


}

/// @nodoc
abstract mixin class _$CommentListDtoCopyWith<$Res> implements $CommentListDtoCopyWith<$Res> {
  factory _$CommentListDtoCopyWith(_CommentListDto value, $Res Function(_CommentListDto) _then) = __$CommentListDtoCopyWithImpl;
@override @useResult
$Res call({
 List<CommentDto> items, String? nextCursor, num total, bool canComment
});




}
/// @nodoc
class __$CommentListDtoCopyWithImpl<$Res>
    implements _$CommentListDtoCopyWith<$Res> {
  __$CommentListDtoCopyWithImpl(this._self, this._then);

  final _CommentListDto _self;
  final $Res Function(_CommentListDto) _then;

/// Create a copy of CommentListDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,Object? total = null,Object? canComment = null,}) {
  return _then(_CommentListDto(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CommentDto>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,canComment: null == canComment ? _self.canComment : canComment // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
