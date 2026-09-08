// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_permissions_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IssuePermissionsDto _$IssuePermissionsDtoFromJson(Map<String, dynamic> json) =>
    _IssuePermissionsDto(
      canEdit: json['canEdit'] as bool,
      canDelete: json['canDelete'] as bool,
    );

Map<String, dynamic> _$IssuePermissionsDtoToJson(
  _IssuePermissionsDto instance,
) => <String, dynamic>{
  'canEdit': instance.canEdit,
  'canDelete': instance.canDelete,
};
