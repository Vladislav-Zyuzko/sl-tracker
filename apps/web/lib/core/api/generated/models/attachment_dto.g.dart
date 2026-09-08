// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AttachmentDto _$AttachmentDtoFromJson(Map<String, dynamic> json) =>
    _AttachmentDto(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      contentType: json['contentType'] as String,
      sizeBytes: json['sizeBytes'] as num,
      isImage: json['isImage'] as bool,
      url: json['url'] as String,
      downloadUrl: json['downloadUrl'] as String,
      uploadedBy: IssueUserDto.fromJson(
        json['uploadedBy'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      canDelete: json['canDelete'] as bool,
    );

Map<String, dynamic> _$AttachmentDtoToJson(_AttachmentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'contentType': instance.contentType,
      'sizeBytes': instance.sizeBytes,
      'isImage': instance.isImage,
      'url': instance.url,
      'downloadUrl': instance.downloadUrl,
      'uploadedBy': instance.uploadedBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'canDelete': instance.canDelete,
    };
