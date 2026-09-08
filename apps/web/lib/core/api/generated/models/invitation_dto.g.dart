// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InvitationDto _$InvitationDtoFromJson(Map<String, dynamic> json) =>
    _InvitationDto(
      id: json['id'] as String,
      role: InvitationDtoRole.fromJson(json['role'] as String),
      state: InvitationDtoState.fromJson(json['state'] as String),
      url: json['url'] as String?,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      lifetimeDays: InvitationDtoLifetimeDays.fromJson(
        json['lifetimeDays'] as num,
      ),
      revokedAt: json['revokedAt'] == null
          ? null
          : DateTime.parse(json['revokedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: InvitationAuthorDto.fromJson(
        json['createdBy'] as Map<String, dynamic>,
      ),
      acceptedCount: json['acceptedCount'] as num,
    );

Map<String, dynamic> _$InvitationDtoToJson(
  _InvitationDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'role': _$InvitationDtoRoleEnumMap[instance.role]!,
  'state': _$InvitationDtoStateEnumMap[instance.state]!,
  'url': instance.url,
  'expiresAt': instance.expiresAt.toIso8601String(),
  'lifetimeDays': _$InvitationDtoLifetimeDaysEnumMap[instance.lifetimeDays]!,
  'revokedAt': instance.revokedAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'createdBy': instance.createdBy,
  'acceptedCount': instance.acceptedCount,
};

const _$InvitationDtoRoleEnumMap = {
  InvitationDtoRole.member: 'member',
  InvitationDtoRole.reader: 'reader',
  InvitationDtoRole.$unknown: r'$unknown',
};

const _$InvitationDtoStateEnumMap = {
  InvitationDtoState.active: 'active',
  InvitationDtoState.expired: 'expired',
  InvitationDtoState.revoked: 'revoked',
  InvitationDtoState.$unknown: r'$unknown',
};

const _$InvitationDtoLifetimeDaysEnumMap = {
  InvitationDtoLifetimeDays.value1: 1,
  InvitationDtoLifetimeDays.value7: 7,
  InvitationDtoLifetimeDays.value30: 30,
  InvitationDtoLifetimeDays.$unknown: r'$unknown',
};
