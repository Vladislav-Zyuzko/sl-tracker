// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TokenDto _$TokenDtoFromJson(Map<String, dynamic> json) => _TokenDto(
  id: json['id'] as String,
  name: json['name'] as String,
  prefix: json['prefix'] as String,
  purpose: TokenDtoPurpose.fromJson(json['purpose'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  lastSeenAt: DateTime.parse(json['lastSeenAt'] as String),
  expiresAt: DateTime.parse(json['expiresAt'] as String),
  revokedAt: json['revokedAt'] == null
      ? null
      : DateTime.parse(json['revokedAt'] as String),
);

Map<String, dynamic> _$TokenDtoToJson(_TokenDto instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'prefix': instance.prefix,
  'purpose': _$TokenDtoPurposeEnumMap[instance.purpose]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'lastSeenAt': instance.lastSeenAt.toIso8601String(),
  'expiresAt': instance.expiresAt.toIso8601String(),
  'revokedAt': instance.revokedAt?.toIso8601String(),
};

const _$TokenDtoPurposeEnumMap = {
  TokenDtoPurpose.pat: 'pat',
  TokenDtoPurpose.$unknown: r'$unknown',
};
