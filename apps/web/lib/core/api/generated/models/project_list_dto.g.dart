// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_list_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectListDto _$ProjectListDtoFromJson(Map<String, dynamic> json) =>
    _ProjectListDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => ProjectDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      total: json['total'] as num,
    );

Map<String, dynamic> _$ProjectListDtoToJson(_ProjectListDto instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
      'total': instance.total,
    };
