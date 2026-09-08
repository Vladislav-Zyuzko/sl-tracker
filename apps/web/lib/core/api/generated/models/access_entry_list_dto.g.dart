// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'access_entry_list_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AccessEntryListDto _$AccessEntryListDtoFromJson(Map<String, dynamic> json) =>
    _AccessEntryListDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => AccessEntryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      total: json['total'] as num,
    );

Map<String, dynamic> _$AccessEntryListDtoToJson(_AccessEntryListDto instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
      'total': instance.total,
    };
