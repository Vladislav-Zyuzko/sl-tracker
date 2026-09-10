import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/network/network_providers.dart';

/// Центр уведомлений и настройки подписки (US-100 … US-104).
class NotificationsRepository {
  /// @nodoc
  const NotificationsRepository(this._client);

  final NotificationsClient _client;

  /// Порция ленты. 30 — умолчание контракта и размер порции из спеки экрана.
  static const pageSize = 30;

  /// Порция ленты, сначала новые.
  Future<NotificationListDto> list({String? cursor}) async {
    try {
      return await _client.notificationsControllerList(
        cursor: cursor,
        limit: pageSize,
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Счётчик непрочитанных для колокольчика в шапке.
  Future<int> unreadCount() async {
    try {
      final result = await _client.notificationsControllerUnreadCount();

      return result.unreadCount.toInt();
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Отмечает уведомление прочитанным. Возвращает новый счётчик.
  ///
  /// Идемпотентно: повторный вызов не меняет время прочтения, и вызывать его
  /// на уже прочитанном уведомлении безопасно.
  Future<int> markRead(String id) async {
    try {
      final result = await _client.notificationsControllerMarkRead(id: id);

      return result.unreadCount.toInt();
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Отмечает прочитанными все. Возвращает, сколько записей изменилось.
  Future<int> markAllRead() async {
    try {
      final result = await _client.notificationsControllerMarkAllRead();

      return result.updated.toInt();
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Настройки подписки: все типы, включая нетронутые.
  Future<List<NotificationSettingDto>> settings() async {
    try {
      final result = await _client.notificationsControllerSettings();

      return result.items;
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Меняет один тип подписки.
  ///
  /// Меняются только перечисленные типы — остальные остаются как были,
  /// поэтому отправляется ровно один элемент, а не весь список: иначе
  /// одновременное переключение двух тумблеров затирало бы друг друга.
  Future<List<NotificationSettingDto>> updateSetting(
    NotificationSettingDtoType type, {
    required bool enabled,
  }) async {
    try {
      final result = await _client.notificationsControllerUpdateSettings(
        body: UpdateNotificationSettingsDto(
          items: [
            UpdateNotificationSettingDto(
              type: UpdateNotificationSettingDtoType.fromJson(
                type.json ?? type.name,
              ),
              enabled: enabled,
            ),
          ],
        ),
      );

      return result.items;
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }
}

/// @nodoc
final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(apiClientProvider).notifications),
);
