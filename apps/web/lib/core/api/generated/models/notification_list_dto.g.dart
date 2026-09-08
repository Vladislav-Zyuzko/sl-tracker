// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_list_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationListDto _$NotificationListDtoFromJson(Map<String, dynamic> json) =>
    _NotificationListDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => NotificationDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      total: json['total'] as num,
      unreadCount: json['unreadCount'] as num,
    );

Map<String, dynamic> _$NotificationListDtoToJson(
  _NotificationListDto instance,
) => <String, dynamic>{
  'items': instance.items,
  'nextCursor': instance.nextCursor,
  'total': instance.total,
  'unreadCount': instance.unreadCount,
};
