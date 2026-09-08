// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_link_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IssueLinkDto _$IssueLinkDtoFromJson(Map<String, dynamic> json) =>
    _IssueLinkDto(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String?,
      createdBy: IssueUserDto.fromJson(
        json['createdBy'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$IssueLinkDtoToJson(_IssueLinkDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'title': instance.title,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt.toIso8601String(),
    };
