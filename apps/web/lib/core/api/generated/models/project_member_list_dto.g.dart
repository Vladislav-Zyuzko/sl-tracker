// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_member_list_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectMemberListDto _$ProjectMemberListDtoFromJson(
  Map<String, dynamic> json,
) => _ProjectMemberListDto(
  items: (json['items'] as List<dynamic>)
      .map((e) => ProjectMemberDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['nextCursor'] as String?,
  total: json['total'] as num,
);

Map<String, dynamic> _$ProjectMemberListDtoToJson(
  _ProjectMemberListDto instance,
) => <String, dynamic>{
  'items': instance.items,
  'nextCursor': instance.nextCursor,
  'total': instance.total,
};
