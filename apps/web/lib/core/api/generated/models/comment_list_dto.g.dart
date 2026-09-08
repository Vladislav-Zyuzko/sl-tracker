// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_list_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CommentListDto _$CommentListDtoFromJson(Map<String, dynamic> json) =>
    _CommentListDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => CommentDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      total: json['total'] as num,
      canComment: json['canComment'] as bool,
    );

Map<String, dynamic> _$CommentListDtoToJson(_CommentListDto instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
      'total': instance.total,
      'canComment': instance.canComment,
    };
