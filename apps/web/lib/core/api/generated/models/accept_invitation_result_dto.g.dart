// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accept_invitation_result_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AcceptInvitationResultDto _$AcceptInvitationResultDtoFromJson(
  Map<String, dynamic> json,
) => _AcceptInvitationResultDto(
  projectSlug: json['projectSlug'] as String,
  role: AcceptInvitationResultDtoRole.fromJson(json['role'] as String),
  alreadyMember: json['alreadyMember'] as bool,
);

Map<String, dynamic> _$AcceptInvitationResultDtoToJson(
  _AcceptInvitationResultDto instance,
) => <String, dynamic>{
  'projectSlug': instance.projectSlug,
  'role': _$AcceptInvitationResultDtoRoleEnumMap[instance.role]!,
  'alreadyMember': instance.alreadyMember,
};

const _$AcceptInvitationResultDtoRoleEnumMap = {
  AcceptInvitationResultDtoRole.admin: 'admin',
  AcceptInvitationResultDtoRole.member: 'member',
  AcceptInvitationResultDtoRole.reader: 'reader',
  AcceptInvitationResultDtoRole.$unknown: r'$unknown',
};
