// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_invitation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreateInvitationDto _$CreateInvitationDtoFromJson(Map<String, dynamic> json) =>
    _CreateInvitationDto(
      role: CreateInvitationDtoRole.fromJson(json['role'] as String),
      expiresInDays: json['expiresInDays'] == null
          ? CreateInvitationDtoExpiresInDays.value7
          : CreateInvitationDtoExpiresInDays.fromJson(
              json['expiresInDays'] as num,
            ),
    );

Map<String, dynamic> _$CreateInvitationDtoToJson(
  _CreateInvitationDto instance,
) => <String, dynamic>{
  'role': _$CreateInvitationDtoRoleEnumMap[instance.role]!,
  'expiresInDays':
      _$CreateInvitationDtoExpiresInDaysEnumMap[instance.expiresInDays]!,
};

const _$CreateInvitationDtoRoleEnumMap = {
  CreateInvitationDtoRole.member: 'member',
  CreateInvitationDtoRole.reader: 'reader',
  CreateInvitationDtoRole.$unknown: r'$unknown',
};

const _$CreateInvitationDtoExpiresInDaysEnumMap = {
  CreateInvitationDtoExpiresInDays.value1: 1,
  CreateInvitationDtoExpiresInDays.value7: 7,
  CreateInvitationDtoExpiresInDays.value30: 30,
  CreateInvitationDtoExpiresInDays.$unknown: r'$unknown',
};
