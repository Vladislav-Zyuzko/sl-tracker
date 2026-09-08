// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CommentDto _$CommentDtoFromJson(Map<String, dynamic> json) => _CommentDto(
  id: json['id'] as String,
  body: json['body'] as String,
  author: IssueUserDto.fromJson(json['author'] as Map<String, dynamic>),
  mentions: (json['mentions'] as List<dynamic>)
      .map((e) => IssueUserDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  editedAt: json['editedAt'] == null
      ? null
      : DateTime.parse(json['editedAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  permissions: CommentPermissionsDto.fromJson(
    json['permissions'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$CommentDtoToJson(_CommentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'body': instance.body,
      'author': instance.author,
      'mentions': instance.mentions,
      'editedAt': instance.editedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'permissions': instance.permissions,
    };
