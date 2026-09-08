// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_list_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AttachmentListDto _$AttachmentListDtoFromJson(Map<String, dynamic> json) =>
    _AttachmentListDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => AttachmentDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      total: json['total'] as num,
      canUpload: json['canUpload'] as bool,
    );

Map<String, dynamic> _$AttachmentListDtoToJson(_AttachmentListDto instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
      'total': instance.total,
      'canUpload': instance.canUpload,
    };
