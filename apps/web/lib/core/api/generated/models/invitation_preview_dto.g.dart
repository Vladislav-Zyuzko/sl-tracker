// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation_preview_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InvitationPreviewDto _$InvitationPreviewDtoFromJson(
  Map<String, dynamic> json,
) => _InvitationPreviewDto(
  projectName: json['projectName'] as String,
  projectSlug: json['projectSlug'] as String,
  coverUrl: json['coverUrl'] as String?,
  role: InvitationPreviewDtoRole.fromJson(json['role'] as String),
  alreadyMember: json['alreadyMember'] as bool,
);

Map<String, dynamic> _$InvitationPreviewDtoToJson(
  _InvitationPreviewDto instance,
) => <String, dynamic>{
  'projectName': instance.projectName,
  'projectSlug': instance.projectSlug,
  'coverUrl': instance.coverUrl,
  'role': _$InvitationPreviewDtoRoleEnumMap[instance.role]!,
  'alreadyMember': instance.alreadyMember,
};

const _$InvitationPreviewDtoRoleEnumMap = {
  InvitationPreviewDtoRole.admin: 'admin',
  InvitationPreviewDtoRole.member: 'member',
  InvitationPreviewDtoRole.reader: 'reader',
  InvitationPreviewDtoRole.$unknown: r'$unknown',
};
