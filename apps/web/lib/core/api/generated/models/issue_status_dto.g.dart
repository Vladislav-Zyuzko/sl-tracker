// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_status_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IssueStatusDto _$IssueStatusDtoFromJson(Map<String, dynamic> json) =>
    _IssueStatusDto(
      key: json['key'] as String,
      name: json['name'] as String,
      category: IssueStatusDtoCategory.fromJson(json['category'] as String),
    );

Map<String, dynamic> _$IssueStatusDtoToJson(_IssueStatusDto instance) =>
    <String, dynamic>{
      'key': instance.key,
      'name': instance.name,
      'category': _$IssueStatusDtoCategoryEnumMap[instance.category]!,
    };

const _$IssueStatusDtoCategoryEnumMap = {
  IssueStatusDtoCategory.open: 'open',
  IssueStatusDtoCategory.inProgress: 'in_progress',
  IssueStatusDtoCategory.done: 'done',
  IssueStatusDtoCategory.$unknown: r'$unknown',
};
