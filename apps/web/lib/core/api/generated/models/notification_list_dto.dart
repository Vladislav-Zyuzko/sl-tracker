// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'notification_dto.dart';

part 'notification_list_dto.freezed.dart';
part 'notification_list_dto.g.dart';

@Freezed()
abstract class NotificationListDto with _$NotificationListDto {
  const factory NotificationListDto({
    /// Сначала новые (US-103)
    required List<NotificationDto> items,

    /// Курсор следующей порции
    required String? nextCursor,

    /// Всего уведомлений у пользователя
    required num total,

    /// Непрочитанных: то же число, что и в счётчике шапки
    required num unreadCount,
  }) = _NotificationListDto;

  factory NotificationListDto.fromJson(Map<String, Object?> json) =>
      _$NotificationListDtoFromJson(json);
}
