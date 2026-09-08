// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_issue_list_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MyIssueListDto _$MyIssueListDtoFromJson(Map<String, dynamic> json) =>
    _MyIssueListDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => MyIssueDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      total: json['total'] as num,
    );

Map<String, dynamic> _$MyIssueListDtoToJson(_MyIssueListDto instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
      'total': instance.total,
    };
