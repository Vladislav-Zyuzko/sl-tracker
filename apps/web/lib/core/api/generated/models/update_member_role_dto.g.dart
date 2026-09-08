// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_member_role_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UpdateMemberRoleDto _$UpdateMemberRoleDtoFromJson(Map<String, dynamic> json) =>
    _UpdateMemberRoleDto(
      role: UpdateMemberRoleDtoRole.fromJson(json['role'] as String),
    );

Map<String, dynamic> _$UpdateMemberRoleDtoToJson(
  _UpdateMemberRoleDto instance,
) => <String, dynamic>{
  'role': _$UpdateMemberRoleDtoRoleEnumMap[instance.role]!,
};

const _$UpdateMemberRoleDtoRoleEnumMap = {
  UpdateMemberRoleDtoRole.admin: 'admin',
  UpdateMemberRoleDtoRole.member: 'member',
  UpdateMemberRoleDtoRole.reader: 'reader',
  UpdateMemberRoleDtoRole.$unknown: r'$unknown',
};
