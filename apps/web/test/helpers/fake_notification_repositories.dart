import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/notifications/data/notifications_repository.dart';

/// Уведомление для тестов.
NotificationDto fakeNotification({
  String id = 'n1',
  NotificationDtoType type = NotificationDtoType.issueAssigned,
  String? actorName = 'Анна Иванова',
  String? issueKey = 'DEV-42',
  String? commentId,
  String? projectSlug,
  NotificationPayloadDto? payload,
  DateTime? readAt,
  DateTime? createdAt,
}) => NotificationDto(
  id: id,
  type: type,
  channel: NotificationDtoChannel.inApp,
  actor: actorName == null
      ? null
      : IssueUserDto(id: 'actor-1', displayName: actorName, avatarUrl: null),
  issueKey: issueKey,
  projectSlug: projectSlug,
  commentId: commentId,
  payload:
      payload ??
      NotificationPayloadDto(
        issueKey: issueKey,
        issueTitle: 'Починить экспорт CSV на больших выгрузках',
      ),
  readAt: readAt,
  createdAt: createdAt ?? DateTime.utc(2026, 9, 9, 11, 32),
);

/// Настройка подписки для тестов.
NotificationSettingDto fakeSetting(
  NotificationSettingDtoType type, {
  bool enabled = true,
}) => NotificationSettingDto(
  type: type,
  channel: NotificationSettingDtoChannel.inApp,
  enabled: enabled,
);

/// Все шесть типов подписки во включённом состоянии.
List<NotificationSettingDto> fakeSettings({bool enabled = true}) => [
  for (final type in NotificationSettingDtoType.$valuesDefined)
    fakeSetting(type, enabled: enabled),
];

/// Подставной репозиторий уведомлений.
class FakeNotificationsRepository implements NotificationsRepository {
  /// @nodoc
  FakeNotificationsRepository({
    List<NotificationDto>? items,
    List<NotificationDto>? nextPage,
    List<NotificationSettingDto>? settings,
    this.listFailure,
    this.markReadFailure,
    this.markAllFailure,
    this.settingsFailure,
    this.updateFailure,
  }) : items = items ?? [],
       nextPage = nextPage ?? [],
       settingsItems = settings ?? fakeSettings();

  /// Первая порция ленты.
  List<NotificationDto> items;

  /// Вторая порция: отдаётся по курсору.
  List<NotificationDto> nextPage;

  /// Настройки подписки.
  List<NotificationSettingDto> settingsItems;

  /// @nodoc
  ApiFailure? listFailure;

  /// @nodoc
  ApiFailure? markReadFailure;

  /// @nodoc
  ApiFailure? markAllFailure;

  /// @nodoc
  ApiFailure? settingsFailure;

  /// @nodoc
  ApiFailure? updateFailure;

  /// Сколько раз запрашивали ленту.
  var listCalls = 0;

  /// Что отметили прочитанным.
  final markedRead = <String>[];

  /// Сколько раз отмечали всё прочитанным.
  var markAllCalls = 0;

  /// Последняя изменённая настройка.
  (NotificationSettingDtoType, bool)? lastUpdate;

  @override
  Future<NotificationListDto> list({String? cursor}) async {
    listCalls++;
    final failure = listFailure;
    if (failure != null) throw failure;

    final page = cursor == null ? items : nextPage;

    return NotificationListDto(
      items: page,
      nextCursor: cursor == null && nextPage.isNotEmpty ? 'cursor-2' : null,
      total: items.length + nextPage.length,
      unreadCount: _unread,
    );
  }

  @override
  Future<int> unreadCount() async => _unread;

  @override
  Future<int> markRead(String id) async {
    final failure = markReadFailure;
    if (failure != null) throw failure;

    markedRead.add(id);
    items = [
      for (final item in items)
        if (item.id == id) item.copyWith(readAt: DateTime.utc(2026)) else item,
    ];

    return _unread;
  }

  @override
  Future<int> markAllRead() async {
    markAllCalls++;
    final failure = markAllFailure;
    if (failure != null) throw failure;

    final updated = items.where((item) => item.readAt == null).length;
    items = [
      for (final item in items) item.copyWith(readAt: DateTime.utc(2026)),
    ];

    return updated;
  }

  @override
  Future<List<NotificationSettingDto>> settings() async {
    final failure = settingsFailure;
    if (failure != null) throw failure;

    return settingsItems;
  }

  @override
  Future<List<NotificationSettingDto>> updateSetting(
    NotificationSettingDtoType type, {
    required bool enabled,
  }) async {
    lastUpdate = (type, enabled);
    final failure = updateFailure;
    if (failure != null) throw failure;

    settingsItems = [
      for (final item in settingsItems)
        if (item.type == type) item.copyWith(enabled: enabled) else item,
    ];

    return settingsItems;
  }

  int get _unread =>
      [...items, ...nextPage].where((item) => item.readAt == null).length;
}
