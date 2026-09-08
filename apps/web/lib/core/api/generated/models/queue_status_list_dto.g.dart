// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_status_list_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QueueStatusListDto _$QueueStatusListDtoFromJson(Map<String, dynamic> json) =>
    _QueueStatusListDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => QueueStatusDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$QueueStatusListDtoToJson(_QueueStatusListDto instance) =>
    <String, dynamic>{'items': instance.items};
