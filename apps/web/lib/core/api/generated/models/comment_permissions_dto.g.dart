// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_permissions_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CommentPermissionsDto _$CommentPermissionsDtoFromJson(
  Map<String, dynamic> json,
) => _CommentPermissionsDto(
  canEdit: json['canEdit'] as bool,
  canDelete: json['canDelete'] as bool,
);

Map<String, dynamic> _$CommentPermissionsDtoToJson(
  _CommentPermissionsDto instance,
) => <String, dynamic>{
  'canEdit': instance.canEdit,
  'canDelete': instance.canDelete,
};
