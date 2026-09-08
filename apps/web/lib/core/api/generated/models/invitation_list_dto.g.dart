// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation_list_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InvitationListDto _$InvitationListDtoFromJson(Map<String, dynamic> json) =>
    _InvitationListDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => InvitationDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      total: json['total'] as num,
    );

Map<String, dynamic> _$InvitationListDtoToJson(_InvitationListDto instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
      'total': instance.total,
    };
