// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issued_token_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IssuedTokenDto _$IssuedTokenDtoFromJson(Map<String, dynamic> json) =>
    _IssuedTokenDto(
      id: json['id'] as String,
      name: json['name'] as String,
      prefix: json['prefix'] as String,
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$IssuedTokenDtoToJson(_IssuedTokenDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'prefix': instance.prefix,
      'token': instance.token,
      'expiresAt': instance.expiresAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };
