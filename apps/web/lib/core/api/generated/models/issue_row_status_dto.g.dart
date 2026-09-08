// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_row_status_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IssueRowStatusDto _$IssueRowStatusDtoFromJson(Map<String, dynamic> json) =>
    _IssueRowStatusDto(
      id: json['id'] as String,
      key: json['key'] as String,
      name: json['name'] as String,
      category: IssueRowStatusDtoCategory.fromJson(json['category'] as String),
    );

Map<String, dynamic> _$IssueRowStatusDtoToJson(_IssueRowStatusDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'name': instance.name,
      'category': _$IssueRowStatusDtoCategoryEnumMap[instance.category]!,
    };

const _$IssueRowStatusDtoCategoryEnumMap = {
  IssueRowStatusDtoCategory.open: 'open',
  IssueRowStatusDtoCategory.inProgress: 'in_progress',
  IssueRowStatusDtoCategory.done: 'done',
  IssueRowStatusDtoCategory.$unknown: r'$unknown',
};
