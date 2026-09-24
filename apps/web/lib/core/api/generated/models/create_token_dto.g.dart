// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_token_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreateTokenDto _$CreateTokenDtoFromJson(Map<String, dynamic> json) =>
    _CreateTokenDto(
      name: json['name'] as String,
      expiresInDays: json['expiresInDays'] as num? ?? 365,
    );

Map<String, dynamic> _$CreateTokenDtoToJson(_CreateTokenDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'expiresInDays': instance.expiresInDays,
    };
