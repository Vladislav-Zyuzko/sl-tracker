// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_status_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QueueStatusDto _$QueueStatusDtoFromJson(Map<String, dynamic> json) =>
    _QueueStatusDto(
      id: json['id'] as String,
      key: json['key'] as String,
      name: json['name'] as String,
      category: QueueStatusDtoCategory.fromJson(json['category'] as String),
      position: json['position'] as num,
    );

Map<String, dynamic> _$QueueStatusDtoToJson(_QueueStatusDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'name': instance.name,
      'category': _$QueueStatusDtoCategoryEnumMap[instance.category]!,
      'position': instance.position,
    };

const _$QueueStatusDtoCategoryEnumMap = {
  QueueStatusDtoCategory.open: 'open',
  QueueStatusDtoCategory.inProgress: 'in_progress',
  QueueStatusDtoCategory.done: 'done',
  QueueStatusDtoCategory.$unknown: r'$unknown',
};
