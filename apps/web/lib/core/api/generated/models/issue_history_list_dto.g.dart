// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_history_list_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IssueHistoryListDto _$IssueHistoryListDtoFromJson(Map<String, dynamic> json) =>
    _IssueHistoryListDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => IssueHistoryGroupDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      total: json['total'] as num,
    );

Map<String, dynamic> _$IssueHistoryListDtoToJson(
  _IssueHistoryListDto instance,
) => <String, dynamic>{
  'items': instance.items,
  'nextCursor': instance.nextCursor,
  'total': instance.total,
};
