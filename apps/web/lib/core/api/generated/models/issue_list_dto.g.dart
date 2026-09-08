// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_list_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IssueListDto _$IssueListDtoFromJson(Map<String, dynamic> json) =>
    _IssueListDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => IssueRowDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      total: json['total'] as num,
      role: json['role'] == null
          ? null
          : IssueListDtoRole.fromJson(json['role'] as String),
    );

Map<String, dynamic> _$IssueListDtoToJson(_IssueListDto instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
      'total': instance.total,
      'role': _$IssueListDtoRoleEnumMap[instance.role],
    };

const _$IssueListDtoRoleEnumMap = {
  IssueListDtoRole.admin: 'admin',
  IssueListDtoRole.member: 'member',
  IssueListDtoRole.reader: 'reader',
  IssueListDtoRole.$unknown: r'$unknown',
};
