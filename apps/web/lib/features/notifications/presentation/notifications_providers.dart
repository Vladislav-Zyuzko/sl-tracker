import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/realtime/realtime_frame.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';
import 'package:sl_tracker_web/features/notifications/data/notifications_repository.dart';
import 'package:sl_tracker_web/features/realtime/presentation/realtime_providers.dart';

/// Счётчик непрочитанных уведомлений.
///
/// Один на всё приложение: колокольчик в шапке и шапка центра уведомлений
/// показывают одно и то же число, и расходиться им нельзя.
///
/// Живой: `user:me` приносит `unreadCount` вместе с событием, и отдельный
/// запрос ради счётчика не нужен (`websocket.md`, 5). Событие
/// `notification.read` приходит, когда человек прочитал уведомления
/// **в другой вкладке** — счётчик в шапке обязан уменьшиться и здесь.
final unreadCountProvider =
    AsyncNotifierProvider<UnreadCountController, int>(
      UnreadCountController.new,
      retry: (_, _) => null,
    );

/// Контроллер счётчика непрочитанных.
class UnreadCountController extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    // Без сессии счётчика не существует: запрос вернул бы 401 и увёл бы
    // человека на вход раньше, чем приложение вообще что-то показало.
    final authenticated = ref.watch(
      sessionControllerProvider.select((session) => session.isAuthenticated),
    );
    if (!authenticated) return 0;

    listenRealtimeTopic(ref, RealtimeTopics.me, (signal) {
      switch (signal) {
        case RealtimeEvent():
          final count = signal.number('unreadCount');
          if (count != null) set(count);
        case RealtimeResync():
          // За время обрыва счётчик мог измениться сколько угодно раз.
          unawaited(refresh());
        case RealtimeTopicLost():
          break;
      }
    });

    return ref.read(notificationsRepositoryProvider).unreadCount();
  }

  /// Перечитывает счётчик с сервера.
  Future<void> refresh() async {
    try {
      final count = await ref.read(notificationsRepositoryProvider).unreadCount();
      if (ref.mounted) state = AsyncData(count);
    } on Object {
      // Счётчик в шапке — не повод показывать ошибку на весь экран:
      // остаётся прежнее значение, следующее событие его поправит.
    }
  }

  /// Ставит известное число: из ответа ленты или из события.
  void set(int value) {
    if (ref.mounted) state = AsyncData(value < 0 ? 0 : value);
  }

  /// Уменьшает счётчик на единицу — оптимистичная пометка прочитанным.
  void decrement() => set((state.value ?? 1) - 1);
}

/// Загруженная часть ленты уведомлений.
@immutable
class NotificationsPage {
  /// @nodoc
  const NotificationsPage({
    required this.items,
    required this.nextCursor,
    required this.total,
    required this.unreadCount,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.highlighted = const {},
  });

  /// Сначала новые (US-103).
  final List<NotificationDto> items;

  /// Курсор следующей порции. `null` — больше нет.
  final String? nextCursor;

  /// Всего уведомлений у пользователя.
  final int total;

  /// Непрочитанных: то же число, что и в колокольчике.
  final int unreadCount;

  /// @nodoc
  final bool isLoadingMore;

  /// @nodoc
  final bool loadMoreFailed;

  /// Уведомления, приехавшие при открытом экране: фон `accentSurface`
  /// на 1200 мс.
  final Set<String> highlighted;

  /// @nodoc
  bool get hasMore => nextCursor != null;

  /// @nodoc
  NotificationsPage copyWith({
    List<NotificationDto>? items,
    String? nextCursor,
    bool clearCursor = false,
    int? total,
    int? unreadCount,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    Set<String>? highlighted,
  }) => NotificationsPage(
    items: items ?? this.items,
    nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    total: total ?? this.total,
    unreadCount: unreadCount ?? this.unreadCount,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    highlighted: highlighted ?? this.highlighted,
  );
}

/// Лента уведомлений (US-100 … US-104).
///
/// Автоочистка: экран открывают, чтобы разобрать накопившееся, и при
/// следующем заходе лента должна быть свежей, а не из памяти прошлого визита.
final notificationsProvider =
    AsyncNotifierProvider<NotificationsController, NotificationsPage>(
      NotificationsController.new,
      isAutoDispose: true,
      // Ошибка загрузки — состояние экрана с кнопкой «Повторить»: решение
      // о повторе принимает человек, а не таймер.
      retry: (_, _) => null,
    );

/// Контроллер ленты уведомлений.
class NotificationsController extends AsyncNotifier<NotificationsPage> {
  /// Сколько держится подсветка только что приехавшего уведомления.
  static const highlightDuration = Duration(milliseconds: 1200);

  @override
  Future<NotificationsPage> build() async {
    // Событие несёт только идентификатор и счётчик: строка целиком
    // собирается сервером под конкретного получателя, поэтому лента
    // перечитывает свою первую порцию, а не додумывает содержимое.
    listenRealtimeTopic(ref, RealtimeTopics.me, (signal) {
      switch (signal) {
        case RealtimeEvent():
          unawaited(_pullNewest());
        case RealtimeResync():
          unawaited(_pullNewest());
        case RealtimeTopicLost():
          break;
      }
    });

    final page = await ref.read(notificationsRepositoryProvider).list();
    _publishUnread(page.unreadCount.toInt());

    return NotificationsPage(
      items: page.items,
      nextCursor: page.nextCursor,
      total: page.total.toInt(),
      unreadCount: page.unreadCount.toInt(),
    );
  }

  /// @nodoc
  void refresh() => ref.invalidateSelf();

  /// Догружает следующую порцию.
  ///
  /// Ошибка не рушит ленту: загруженное остаётся, а в конце появляется
  /// строка «Не удалось загрузить ещё» с повтором.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.loadMoreFailed) {
      return;
    }

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );

    try {
      final page = await ref
          .read(notificationsRepositoryProvider)
          .list(cursor: current.nextCursor);

      if (!ref.mounted) return;

      final latest = state.value ?? current;
      final known = {for (final item in latest.items) item.id};

      state = AsyncData(
        latest.copyWith(
          items: [
            ...latest.items,
            for (final item in page.items)
              if (!known.contains(item.id)) item,
          ],
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
          total: page.total.toInt(),
          isLoadingMore: false,
        ),
      );
    } on Object {
      if (!ref.mounted) return;

      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(isLoadingMore: false, loadMoreFailed: true),
      );
    }
  }

  /// Повторяет сорвавшуюся дозагрузку.
  Future<void> retryLoadMore() async {
    final current = state.value;
    if (current == null || !current.loadMoreFailed) return;

    state = AsyncData(current.copyWith(loadMoreFailed: false));
    await loadMore();
  }

  /// Отмечает уведомление прочитанным — **оптимистично**.
  ///
  /// Точка гаснет сразу, счётчик уменьшается сразу. При ошибке точка
  /// возвращается, и экран показывает тост (`notifications.md`, «Поведение»).
  Future<void> markRead(String id) async {
    final current = state.value;
    if (current == null) return;

    final index = current.items.indexWhere((item) => item.id == id);
    if (index < 0 || current.items[index].readAt != null) return;

    final before = current.items[index];
    _replace(current, index, before.copyWith(readAt: DateTime.now()));
    _setUnread((state.value?.unreadCount ?? 1) - 1);

    try {
      final unread = await ref
          .read(notificationsRepositoryProvider)
          .markRead(id);

      if (ref.mounted) _setUnread(unread);
    } on Object {
      final latest = state.value;
      if (ref.mounted && latest != null) {
        final position = latest.items.indexWhere((item) => item.id == id);
        if (position >= 0) _replace(latest, position, before);
        _setUnread(latest.unreadCount + 1);
      }

      rethrow;
    }
  }

  /// Отмечает прочитанными все.
  ///
  /// Строки **не переупорядочиваются и не исчезают** — гаснут только точки
  /// и жирность (US-103).
  Future<void> markAllRead() async {
    final current = state.value;
    if (current == null || current.unreadCount == 0) return;

    final now = DateTime.now();
    state = AsyncData(
      current.copyWith(
        items: [
          for (final item in current.items)
            if (item.readAt == null) item.copyWith(readAt: now) else item,
        ],
        unreadCount: 0,
      ),
    );
    _publishUnread(0);

    try {
      await ref.read(notificationsRepositoryProvider).markAllRead();
    } on Object {
      if (ref.mounted) {
        state = AsyncData(current);
        _publishUnread(current.unreadCount);
      }

      rethrow;
    }
  }

  /// Перечитывает первую порцию и вставляет новое сверху.
  ///
  /// Именно вставляет, а не заменяет ленту: человек мог догрузить пять порций,
  /// и терять их из-за одного нового уведомления нельзя.
  Future<void> _pullNewest() async {
    final current = state.value;
    if (current == null) return;

    final NotificationListDto page;
    try {
      page = await ref.read(notificationsRepositoryProvider).list();
    } on Object {
      // Не беда: счётчик обновится событием, а лента — следующим действием.
      return;
    }

    final latest = state.value;
    if (!ref.mounted || latest == null) return;

    final known = {for (final item in latest.items) item.id};
    final fresh = [
      for (final item in page.items)
        if (!known.contains(item.id)) item,
    ];

    // Уже загруженные строки берём из свежего ответа: в другой вкладке их
    // могли отметить прочитанными, и точка должна погаснуть здесь тоже.
    final updated = {for (final item in page.items) item.id: item};

    state = AsyncData(
      latest.copyWith(
        items: [
          ...fresh,
          for (final item in latest.items) updated[item.id] ?? item,
        ],
        total: page.total.toInt(),
        unreadCount: page.unreadCount.toInt(),
        highlighted: {
          ...latest.highlighted,
          for (final item in fresh) item.id,
        },
      ),
    );
    _publishUnread(page.unreadCount.toInt());

    if (fresh.isEmpty) return;

    Timer(highlightDuration, () {
      final page = state.value;
      if (!ref.mounted || page == null) return;

      state = AsyncData(
        page.copyWith(
          highlighted: {
            for (final id in page.highlighted)
              if (!fresh.any((item) => item.id == id)) id,
          },
        ),
      );
    });
  }

  void _replace(NotificationsPage page, int index, NotificationDto value) {
    state = AsyncData(
      page.copyWith(items: [...page.items]..[index] = value),
    );
  }

  void _setUnread(int value) {
    final page = state.value;
    if (page == null) return;

    final normalized = value < 0 ? 0 : value;
    state = AsyncData(page.copyWith(unreadCount: normalized));
    _publishUnread(normalized);
  }

  /// Держит счётчик в шапке в согласии с лентой.
  void _publishUnread(int value) =>
      ref.read(unreadCountProvider.notifier).set(value);
}

/// Настройки подписки по типам событий (US-103, US-104).
///
/// Живут в разделе уведомлений, а показываются на экране профиля: это одни
/// и те же данные, и второй копии у них быть не должно.
final notificationSettingsProvider =
    AsyncNotifierProvider<
      NotificationSettingsController,
      List<NotificationSettingDto>
    >(NotificationSettingsController.new, retry: (_, _) => null);

/// Контроллер настроек подписки.
class NotificationSettingsController
    extends AsyncNotifier<List<NotificationSettingDto>> {
  @override
  Future<List<NotificationSettingDto>> build() {
    final authenticated = ref.watch(
      sessionControllerProvider.select((session) => session.isAuthenticated),
    );
    if (!authenticated) return Future.value(const []);

    return ref.read(notificationsRepositoryProvider).settings();
  }

  /// @nodoc
  void refresh() => ref.invalidateSelf();

  /// Переключает тип — **оптимистично**.
  ///
  /// Кнопки «Сохранить» на экране нет: положение меняется сразу, запрос
  /// уходит следом. При ошибке тумблер возвращается на место, и экран
  /// показывает тост (`screens/profile.md`, «Поведение»).
  Future<void> toggle(
    NotificationSettingDtoType type, {
    required bool enabled,
  }) async {
    final before = state.value;
    if (before == null) return;

    state = AsyncData([
      for (final item in before)
        if (item.type == type) item.copyWith(enabled: enabled) else item,
    ]);

    try {
      final updated = await ref
          .read(notificationsRepositoryProvider)
          .updateSetting(type, enabled: enabled);

      if (ref.mounted) state = AsyncData(updated);
    } on Object {
      if (ref.mounted) state = AsyncData(before);

      rethrow;
    }
  }
}

/// Все ли типы отключены.
///
/// Отдельная функция, потому что смысл у неё один и тот же в двух местах:
/// баннер `warning` в профиле и баннер `info` в центре уведомлений.
bool allNotificationsDisabled(List<NotificationSettingDto> settings) =>
    settings.isNotEmpty && settings.every((item) => !item.enabled);
