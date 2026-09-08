// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/mark_all_read_result_dto.dart';
import '../models/notification_list_dto.dart';
import '../models/notification_settings_dto.dart';
import '../models/unread_count_dto.dart';
import '../models/update_notification_settings_dto.dart';

part 'notifications_client.g.dart';

@RestApi()
abstract class NotificationsClient {
  factory NotificationsClient(Dio dio, {String? baseUrl}) =
      _NotificationsClient;

  /// Мои уведомления.
  ///
  /// Лента, сначала новые. Порция по умолчанию — 30, жёсткий максимум 100; пагинация курсорная (`nextCursor` подставляется как есть).
  ///
  /// Текст строки собирается из `type`, `actor` и `payload`: `payload` — **снимок на момент события**, он не меняется вслед за переименованием задачи или правкой комментария (US-102). Поля `issueKey` и `commentId` верхнего уровня — наоборот, состояние сейчас: `null` в них означает, что переходить некуда (задача удалена или пользователь больше не в проекте; комментарий удалён).
  ///
  /// `unreadCount` в ответе — то же число, что отдаёт `/api/notifications/unread-count`: экран может не делать второй запрос ради счётчика в своей шапке.
  ///
  /// [cursor] - Курсор следующей порции из поля `nextCursor`.
  @GET('/api/notifications')
  Future<NotificationListDto> notificationsControllerList({
    @Query('cursor') String? cursor,
    @Query('limit') num? limit = 30,
  });

  /// Счётчик непрочитанных.
  ///
  /// Дешёвый запрос для колокольчика в шапке: считается по частичному индексу. Отдаётся точное число — «99+» рисует интерфейс (US-103).
  @GET('/api/notifications/unread-count')
  Future<UnreadCountDto> notificationsControllerUnreadCount();

  /// Настройки подписки.
  ///
  /// Все типы уведомлений с признаком «включено». По умолчанию включены все (US-103); типы, которые пользователь никогда не трогал, тоже присутствуют в ответе.
  ///
  /// Канал хранится отдельным измерением, хотя в MVP он один — `in_app`: появление email не должно потребовать от пользователя перенастройки (D-18).
  @GET('/api/notifications/settings')
  Future<NotificationSettingsDto> notificationsControllerSettings();

  /// Изменить настройки подписки.
  ///
  /// Меняются только перечисленные типы, остальные остаются как были. Отключённый тип не создаёт ни записи в центре уведомлений, ни увеличения счётчика — то есть уведомление не появляется вовсе, а не скрывается (US-103). Уже полученные уведомления отключение типа не удаляет.
  @PUT('/api/notifications/settings')
  Future<NotificationSettingsDto> notificationsControllerUpdateSettings({
    @Body() required UpdateNotificationSettingsDto body,
  });

  /// Отметить все как прочитанные.
  ///
  /// Строки не исчезают и не переупорядочиваются — гаснут только точки непрочитанного (US-103). В ответе — сколько записей изменилось.
  @POST('/api/notifications/read-all')
  Future<MarkAllReadResultDto> notificationsControllerMarkAllRead();

  /// Отметить уведомление прочитанным.
  ///
  /// Идемпотентно: повторный вызов не меняет время прочтения. Чужое уведомление — 404: о его существовании клиент не узнаёт.
  @POST('/api/notifications/{id}/read')
  Future<UnreadCountDto> notificationsControllerMarkRead({
    @Path('id') required String id,
  });
}
