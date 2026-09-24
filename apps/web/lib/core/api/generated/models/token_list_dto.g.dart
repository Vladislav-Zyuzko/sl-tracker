// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_list_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TokenListDto _$TokenListDtoFromJson(Map<String, dynamic> json) =>
    _TokenListDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => TokenDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as num,
    );

Map<String, dynamic> _$TokenListDtoToJson(_TokenListDto instance) =>
    <String, dynamic>{'items': instance.items, 'total': instance.total};
