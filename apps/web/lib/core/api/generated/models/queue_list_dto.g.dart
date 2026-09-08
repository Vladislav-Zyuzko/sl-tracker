// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_list_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QueueListDto _$QueueListDtoFromJson(Map<String, dynamic> json) =>
    _QueueListDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => QueueDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as num?,
    );

Map<String, dynamic> _$QueueListDtoToJson(_QueueListDto instance) =>
    <String, dynamic>{'items': instance.items, 'total': instance.total};
