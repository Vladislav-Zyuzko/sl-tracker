// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attachment_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AttachmentDto {

 String get id;/// Имя файла как его назвал загрузивший
 String get fileName;/// Тип, определённый **по содержимому файла**, а не по заголовку запроса и не по расширению. Неопознанное содержимое — `application/octet-stream`.
 String get contentType;/// Размер в байтах, максимум 26 214 400 (25 МБ)
 num get sizeBytes;/// Показывать превью в задаче. Верно для image/png, image/jpeg, image/webp, image/gif (US-46).
 bool get isImage;/// Подписанная ссылка на содержимое, живёт 10 минут. Бакет не публичный: та же ссылка без подписи ничего не отдаёт, и посторонний файл не получит (US-46, D-21). Ссылка выдаётся заново при каждом запросе списка — сохранять её надолго нельзя.
 String get url;/// Та же подписанная ссылка, но с `Content-Disposition: attachment`: браузер скачивает файл под исходным именем, хотя в хранилище он лежит под именем, сгенерированным сервером.
 String get downloadUrl;/// Кто приложил
 IssueUserDto get uploadedBy; DateTime get createdAt;/// Может ли запросивший удалить это вложение: администратор проекта — любое, участник — только своё, читатель — никакое (US-46).
 bool get canDelete;
/// Create a copy of AttachmentDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttachmentDtoCopyWith<AttachmentDto> get copyWith => _$AttachmentDtoCopyWithImpl<AttachmentDto>(this as AttachmentDto, _$identity);

  /// Serializes this AttachmentDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AttachmentDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttachmentDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.fileName, _this.fileName) || other.fileName == _this.fileName)&&(identical(other.contentType, _this.contentType) || other.contentType == _this.contentType)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes)&&(identical(other.isImage, _this.isImage) || other.isImage == _this.isImage)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.downloadUrl, _this.downloadUrl) || other.downloadUrl == _this.downloadUrl)&&(identical(other.uploadedBy, _this.uploadedBy) || other.uploadedBy == _this.uploadedBy)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.canDelete, _this.canDelete) || other.canDelete == _this.canDelete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AttachmentDto;
  return Object.hash(runtimeType,_this.id,_this.fileName,_this.contentType,_this.sizeBytes,_this.isImage,_this.url,_this.downloadUrl,_this.uploadedBy,_this.createdAt,_this.canDelete);
}

@override
String toString() {
  final _this = this as AttachmentDto;
  return 'AttachmentDto(id: ${_this.id}, fileName: ${_this.fileName}, contentType: ${_this.contentType}, sizeBytes: ${_this.sizeBytes}, isImage: ${_this.isImage}, url: ${_this.url}, downloadUrl: ${_this.downloadUrl}, uploadedBy: ${_this.uploadedBy}, createdAt: ${_this.createdAt}, canDelete: ${_this.canDelete})';
}


}

/// @nodoc
abstract mixin class $AttachmentDtoCopyWith<$Res>  {
  factory $AttachmentDtoCopyWith(AttachmentDto value, $Res Function(AttachmentDto) _then) = _$AttachmentDtoCopyWithImpl;
@useResult
$Res call({
 String id, String fileName, String contentType, num sizeBytes, bool isImage, String url, String downloadUrl, IssueUserDto uploadedBy, DateTime createdAt, bool canDelete
});


$IssueUserDtoCopyWith<$Res> get uploadedBy;

}
/// @nodoc
class _$AttachmentDtoCopyWithImpl<$Res>
    implements $AttachmentDtoCopyWith<$Res> {
  _$AttachmentDtoCopyWithImpl(this._self, this._then);

  final AttachmentDto _self;
  final $Res Function(AttachmentDto) _then;

/// Create a copy of AttachmentDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fileName = null,Object? contentType = null,Object? sizeBytes = null,Object? isImage = null,Object? url = null,Object? downloadUrl = null,Object? uploadedBy = null,Object? createdAt = null,Object? canDelete = null,}) {
  return _then(AttachmentDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as num,isImage: null == isImage ? _self.isImage : isImage // ignore: cast_nullable_to_non_nullable
as bool,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,downloadUrl: null == downloadUrl ? _self.downloadUrl : downloadUrl // ignore: cast_nullable_to_non_nullable
as String,uploadedBy: null == uploadedBy ? _self.uploadedBy : uploadedBy // ignore: cast_nullable_to_non_nullable
as IssueUserDto,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,canDelete: null == canDelete ? _self.canDelete : canDelete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of AttachmentDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueUserDtoCopyWith<$Res> get uploadedBy {
  
  return $IssueUserDtoCopyWith<$Res>(_self.uploadedBy, (value) {
    return _then(_self.copyWith(uploadedBy: value));
  });
}
}


/// Adds pattern-matching-related methods to [AttachmentDto].
extension AttachmentDtoPatterns on AttachmentDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttachmentDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttachmentDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttachmentDto value)  $default,){
final _that = this;
switch (_that) {
case _AttachmentDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttachmentDto value)?  $default,){
final _that = this;
switch (_that) {
case _AttachmentDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fileName,  String contentType,  num sizeBytes,  bool isImage,  String url,  String downloadUrl,  IssueUserDto uploadedBy,  DateTime createdAt,  bool canDelete)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttachmentDto() when $default != null:
return $default(_that.id,_that.fileName,_that.contentType,_that.sizeBytes,_that.isImage,_that.url,_that.downloadUrl,_that.uploadedBy,_that.createdAt,_that.canDelete);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fileName,  String contentType,  num sizeBytes,  bool isImage,  String url,  String downloadUrl,  IssueUserDto uploadedBy,  DateTime createdAt,  bool canDelete)  $default,) {final _that = this;
switch (_that) {
case _AttachmentDto():
return $default(_that.id,_that.fileName,_that.contentType,_that.sizeBytes,_that.isImage,_that.url,_that.downloadUrl,_that.uploadedBy,_that.createdAt,_that.canDelete);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fileName,  String contentType,  num sizeBytes,  bool isImage,  String url,  String downloadUrl,  IssueUserDto uploadedBy,  DateTime createdAt,  bool canDelete)?  $default,) {final _that = this;
switch (_that) {
case _AttachmentDto() when $default != null:
return $default(_that.id,_that.fileName,_that.contentType,_that.sizeBytes,_that.isImage,_that.url,_that.downloadUrl,_that.uploadedBy,_that.createdAt,_that.canDelete);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttachmentDto implements AttachmentDto {
  const _AttachmentDto({required this.id, required this.fileName, required this.contentType, required this.sizeBytes, required this.isImage, required this.url, required this.downloadUrl, required this.uploadedBy, required this.createdAt, required this.canDelete});
  factory _AttachmentDto.fromJson(Map<String, dynamic> json) => _$AttachmentDtoFromJson(json);

@override final  String id;
/// Имя файла как его назвал загрузивший
@override final  String fileName;
/// Тип, определённый **по содержимому файла**, а не по заголовку запроса и не по расширению. Неопознанное содержимое — `application/octet-stream`.
@override final  String contentType;
/// Размер в байтах, максимум 26 214 400 (25 МБ)
@override final  num sizeBytes;
/// Показывать превью в задаче. Верно для image/png, image/jpeg, image/webp, image/gif (US-46).
@override final  bool isImage;
/// Подписанная ссылка на содержимое, живёт 10 минут. Бакет не публичный: та же ссылка без подписи ничего не отдаёт, и посторонний файл не получит (US-46, D-21). Ссылка выдаётся заново при каждом запросе списка — сохранять её надолго нельзя.
@override final  String url;
/// Та же подписанная ссылка, но с `Content-Disposition: attachment`: браузер скачивает файл под исходным именем, хотя в хранилище он лежит под именем, сгенерированным сервером.
@override final  String downloadUrl;
/// Кто приложил
@override final  IssueUserDto uploadedBy;
@override final  DateTime createdAt;
/// Может ли запросивший удалить это вложение: администратор проекта — любое, участник — только своё, читатель — никакое (US-46).
@override final  bool canDelete;

/// Create a copy of AttachmentDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttachmentDtoCopyWith<_AttachmentDto> get copyWith => __$AttachmentDtoCopyWithImpl<_AttachmentDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttachmentDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttachmentDto&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.isImage, isImage) || other.isImage == isImage)&&(identical(other.url, url) || other.url == url)&&(identical(other.downloadUrl, downloadUrl) || other.downloadUrl == downloadUrl)&&(identical(other.uploadedBy, uploadedBy) || other.uploadedBy == uploadedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.canDelete, canDelete) || other.canDelete == canDelete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,fileName,contentType,sizeBytes,isImage,url,downloadUrl,uploadedBy,createdAt,canDelete);
}

@override
String toString() {
    return 'AttachmentDto(id: $id, fileName: $fileName, contentType: $contentType, sizeBytes: $sizeBytes, isImage: $isImage, url: $url, downloadUrl: $downloadUrl, uploadedBy: $uploadedBy, createdAt: $createdAt, canDelete: $canDelete)';
}


}

/// @nodoc
abstract mixin class _$AttachmentDtoCopyWith<$Res> implements $AttachmentDtoCopyWith<$Res> {
  factory _$AttachmentDtoCopyWith(_AttachmentDto value, $Res Function(_AttachmentDto) _then) = __$AttachmentDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String fileName, String contentType, num sizeBytes, bool isImage, String url, String downloadUrl, IssueUserDto uploadedBy, DateTime createdAt, bool canDelete
});


@override $IssueUserDtoCopyWith<$Res> get uploadedBy;

}
/// @nodoc
class __$AttachmentDtoCopyWithImpl<$Res>
    implements _$AttachmentDtoCopyWith<$Res> {
  __$AttachmentDtoCopyWithImpl(this._self, this._then);

  final _AttachmentDto _self;
  final $Res Function(_AttachmentDto) _then;

/// Create a copy of AttachmentDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fileName = null,Object? contentType = null,Object? sizeBytes = null,Object? isImage = null,Object? url = null,Object? downloadUrl = null,Object? uploadedBy = null,Object? createdAt = null,Object? canDelete = null,}) {
  return _then(_AttachmentDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as num,isImage: null == isImage ? _self.isImage : isImage // ignore: cast_nullable_to_non_nullable
as bool,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,downloadUrl: null == downloadUrl ? _self.downloadUrl : downloadUrl // ignore: cast_nullable_to_non_nullable
as String,uploadedBy: null == uploadedBy ? _self.uploadedBy : uploadedBy // ignore: cast_nullable_to_non_nullable
as IssueUserDto,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,canDelete: null == canDelete ? _self.canDelete : canDelete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of AttachmentDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssueUserDtoCopyWith<$Res> get uploadedBy {
  
  return $IssueUserDtoCopyWith<$Res>(_self.uploadedBy, (value) {
    return _then(_self.copyWith(uploadedBy: value));
  });
}
}

// dart format on
