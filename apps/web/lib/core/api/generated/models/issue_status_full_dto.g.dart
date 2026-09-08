// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_status_full_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IssueStatusFullDto _$IssueStatusFullDtoFromJson(Map<String, dynamic> json) =>
    _IssueStatusFullDto(
      id: json['id'] as String,
      key: json['key'] as String,
      name: json['name'] as String,
      category: IssueStatusFullDtoCategory.fromJson(json['category'] as String),
      position: json['position'] as num,
    );

Map<String, dynamic> _$IssueStatusFullDtoToJson(_IssueStatusFullDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'name': instance.name,
      'category': _$IssueStatusFullDtoCategoryEnumMap[instance.category]!,
      'position': instance.position,
    };

const _$IssueStatusFullDtoCategoryEnumMap = {
  IssueStatusFullDtoCategory.open: 'open',
  IssueStatusFullDtoCategory.inProgress: 'in_progress',
  IssueStatusFullDtoCategory.done: 'done',
  IssueStatusFullDtoCategory.$unknown: r'$unknown',
};
