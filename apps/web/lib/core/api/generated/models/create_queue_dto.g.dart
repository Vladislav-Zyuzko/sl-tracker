// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_queue_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreateQueueDto _$CreateQueueDtoFromJson(Map<String, dynamic> json) =>
    _CreateQueueDto(
      key: json['key'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$CreateQueueDtoToJson(_CreateQueueDto instance) =>
    <String, dynamic>{
      'key': instance.key,
      'name': instance.name,
      'description': instance.description,
    };
