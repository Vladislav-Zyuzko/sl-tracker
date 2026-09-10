import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/platform/browser_navigator.dart';
import 'package:sl_tracker_web/features/notifications/domain/notification_line.dart';
import 'package:sl_tracker_web/features/notifications/presentation/notifications_providers.dart';
import 'package:sl_tracker_web/features/notifications/presentation/widgets/notification_row.dart';
import 'package:sl_tracker_web/features/notifications/presentation/widgets/notifications_skeleton.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_icon_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_counter_badge.dart';
import 'package:sl_tracker_web/shared/uikit/keyboard/sl_shortcuts.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_empty_state.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Центр уведомлений (`docs/design/screens/notifications.md`).
///
/// Полноценная страница, а не выпадающая панель: уведомления просматривают
/// пачкой после отсутствия, у страницы есть адрес, а переход по уведомлению
/// всё равно уводит со страницы.
///
/// Лента виртуализирована по `itemExtent`: за 30 дней хранения у активного
/// пользователя набираются сотни записей.
class NotificationsScreen extends ConsumerStatefulWidget {
  /// @nodoc
  const NotificationsScreen({super.key});

  /// Ширина ленты: это текст, а не таблица.
  static const contentWidth = 720.0;

  /// Высота шапки экрана.
  static const headerHeight = 44.0;

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _headerFocusNode = FocusNode(debugLabel: 'notifications-header');
  final _scrollController = ScrollController();

  /// Сколько пикселей до конца списка запускают догрузку.
  static const _loadMoreThreshold = 200.0;

  /// Высота хвоста списка: строка догрузки или её ошибки.
  static const _footerHeight = 44.0;

  /// Строка под клавиатурным курсором. `-1` — курсора нет.
  var _cursor = -1;

  @override
  void initState() {
    super.initState();
    // При входе фокус — на заголовок: скринридер объявляет, куда человек
    // попал (`screens/README.md`, 6).
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _headerFocusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _headerFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<NotificationDto> get _items =>
      ref.read(notificationsProvider).value?.items ?? const [];

  bool get _compact => SLBreakpoint.of(context).isPhone;

  double get _rowExtent =>
      _compact ? NotificationRow.compactHeight : NotificationRow.height;

  // --- Действия -------------------------------------------------------------

  /// Открывает источник уведомления и отмечает его прочитанным.
  ///
  /// Пометка идёт первой и оптимистично: точка гаснет сразу, а человек уже
  /// смотрит на задачу — ждать ответа сервера ему незачем (US-103).
  void _open(NotificationDto notification, {bool newTab = false}) {
    _markRead(notification);

    final target = NotificationLine.targetOf(notification);
    if (target == null) {
      ref
          .read(toastControllerProvider.notifier)
          .show(NotificationLine.noTargetToast, variant: SLToastVariant.info);

      return;
    }

    // Комментарий удалён: открывается сама задача, и человеку говорят,
    // почему он не увидит того, ради чего пришёл (US-102).
    if (NotificationLine.pointsToDeletedComment(notification)) {
      ref
          .read(toastControllerProvider.notifier)
          .show('Комментарий удалён', variant: SLToastVariant.info);
    }

    if (newTab) {
      final navigator = ref.read(browserNavigatorProvider);
      navigator.openInNewTab('${navigator.origin}$target');

      return;
    }

    context.go(target);
  }

  /// Пометка прочитанным без ожидания: ошибка приходит тостом.
  void _markRead(NotificationDto notification) {
    if (notification.readAt != null) return;

    ref
        .read(notificationsProvider.notifier)
        .markRead(notification.id)
        .onError<Object>((_, _) {
          if (!mounted) return;
          ref
              .read(toastControllerProvider.notifier)
              .error('Не удалось отметить прочитанным');
        });
  }

  Future<void> _markAllRead() async {
    try {
      await ref.read(notificationsProvider.notifier).markAllRead();
    } on Object {
      if (!mounted) return;

      ref
          .read(toastControllerProvider.notifier)
          .error(
            'Не удалось отметить всё прочитанным',
            actionLabel: 'Повторить',
            onAction: _markAllRead,
          );
    }
  }

  void _loadMore() {
    ref.read(notificationsProvider.notifier).loadMore();
  }

  // --- Клавиатура -----------------------------------------------------------

  void _moveCursor(int delta) {
    final items = _items;
    if (items.isEmpty) return;

    final next = (_cursor + delta).clamp(0, items.length - 1);
    setState(() => _cursor = next);
    _revealCursor(next);
  }

  void _setCursor(int index) {
    final items = _items;
    if (items.isEmpty) return;

    final next = index.clamp(0, items.length - 1);
    setState(() => _cursor = next);
    _revealCursor(next);
  }

  /// Держит строку под курсором в поле зрения.
  ///
  /// Считаем руками, а не через `ensureVisible`: у строк фиксированная
  /// высота, и это единственный способ не искать `BuildContext` элемента,
  /// которого в виртуализированном списке может не быть вовсе.
  void _revealCursor(int index) {
    if (!_scrollController.hasClients) return;

    final extent = _rowExtent;
    final position = _scrollController.position;
    final top = index * extent;
    final bottom = top + extent;

    if (top < position.pixels) {
      _scrollController.jumpTo(top);
    } else if (bottom > position.pixels + position.viewportDimension) {
      _scrollController.jumpTo(
        (bottom - position.viewportDimension).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || slIsTypingInField()) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;
    final withCommand = keyboard.isControlPressed || keyboard.isMetaPressed;
    final items = _items;

    if (key == LogicalKeyboardKey.escape) {
      _headerFocusNode.requestFocus();

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyJ) {
      _moveCursor(_cursor < 0 ? 0 : 1);

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyK) {
      _moveCursor(-1);

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.home) {
      _setCursor(0);

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.end) {
      _setCursor(items.length - 1);

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter &&
        _cursor >= 0 &&
        _cursor < items.length) {
      _open(items[_cursor], newTab: withCommand);

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyA && keyboard.isShiftPressed) {
      unawaited(_markAllRead());

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // --- Раскладка ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final page = ref.watch(notificationsProvider);
    final unread = page.value?.unreadCount ?? 0;

    return Focus(
      onKeyEvent: _onKeyEvent,
      // `Material`, а не `ColoredBox`: строки ленты — `InkWell`, и им нужна
      // материальная подложка. Оболочка приложения её даёт, но экран
      // не должен зависеть от того, куда его вставили.
      child: Material(
        color: colors.surface,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: NotificationsScreen.contentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SLSpacing.space4,
                vertical: SLSpacing.space3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(
                    focusNode: _headerFocusNode,
                    unread: unread,
                    isLoading: page.isLoading && !page.hasValue,
                    compact: _compact,
                    onMarkAllRead: _markAllRead,
                  ),
                  const _AllDisabledBanner(),
                  Expanded(
                    child: switch (page) {
                      AsyncError(:final error) => _buildError(error),
                      AsyncValue(hasValue: false) => NotificationsSkeleton(
                        compact: _compact,
                      ),
                      AsyncValue(:final value?) => _buildList(value),
                      _ => NotificationsSkeleton(compact: _compact),
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(Object error) {
    final failure = ApiFailure.of(error);

    return SLErrorState(
      title: 'Не удалось загрузить уведомления',
      description: 'Проверьте соединение и попробуйте ещё раз.',
      onAction: ref.read(notificationsProvider.notifier).refresh,
      details: failure.toString(),
    );
  }

  Widget _buildList(NotificationsPage page) {
    if (page.items.isEmpty) {
      // Пустого состояния «все прочитаны» не бывает: прочитанные остаются
      // в ленте, иначе экран внезапно пустел бы после «отметить все».
      return const SLEmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'Уведомлений нет',
        description:
            'Здесь появятся сообщения о задачах, которые вас касаются: '
            'назначения, упоминания, смены статуса и комментарии.',
      );
    }

    final extent = _rowExtent;
    final hasFooter = page.hasMore || page.loadMoreFailed;

    return Semantics(
      container: true,
      label:
          'Уведомления, ${page.unreadCount} непрочитанных '
          'из ${page.total}',
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < _loadMoreThreshold) {
            _loadMore();
          }

          return false;
        },
        // `CustomScrollView`, а не `ListView`: строки ленты одной высоты
        // и виртуализируются по ней, а хвост догрузки — своей, 44.
        // С одним `itemExtent` на всё пришлось бы врать либо в строке,
        // либо в хвосте.
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverFixedExtentList.builder(
              itemExtent: extent,
              itemCount: page.items.length,
              itemBuilder: (context, index) {
                final item = page.items[index];

                return NotificationRow(
                  key: ValueKey(item.id),
                  notification: item,
                  selected: index == _cursor,
                  highlighted: page.highlighted.contains(item.id),
                  compact: _compact,
                  timeInline: SLBreakpoint.of(context) == SLBreakpoint.md,
                  onOpen: () {
                    setState(() => _cursor = index);
                    // Модификатор у нажатия узнаём у клавиатуры: `InkWell`
                    // о `Ctrl` и `Cmd` ничего не сообщает, а в вебе
                    // открывать в новой вкладке — привычка.
                    final keyboard = HardwareKeyboard.instance;

                    _open(
                      item,
                      newTab:
                          keyboard.isControlPressed || keyboard.isMetaPressed,
                    );
                  },
                  onOpenInNewTab: () => _open(item, newTab: true),
                );
              },
            ),
            if (hasFooter)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: _footerHeight,
                  child: _Footer(
                    failed: page.loadMoreFailed,
                    onRetry: ref
                        .read(notificationsProvider.notifier)
                        .retryLoadMore,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Шапка экрана: заголовок, счётчик и «Отметить все как прочитанные».
class _Header extends StatelessWidget {
  const _Header({
    required this.focusNode,
    required this.unread,
    required this.isLoading,
    required this.compact,
    required this.onMarkAllRead,
  });

  final FocusNode focusNode;
  final int unread;
  final bool isLoading;
  final bool compact;
  final Future<void> Function() onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    // Доступное имя с числом: действие понятно по последствиям.
    final label = 'Отметить все $unread как прочитанные';

    return SizedBox(
      height: NotificationsScreen.headerHeight,
      child: Row(
        children: [
          Focus(
            focusNode: focusNode,
            child: Semantics(
              header: true,
              child: Text(
                'Уведомления',
                style: text.h2.copyWith(color: colors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: SLSpacing.space2),
          // Счётчик — живая область: новое уведомление объявляется один раз.
          Semantics(
            liveRegion: true,
            label: unread > 0 ? '$unread непрочитанных' : '',
            child: ExcludeSemantics(
              child: unread > 0
                  ? SLCounterBadge(count: unread, accented: true)
                  : const SizedBox.shrink(),
            ),
          ),
          const Spacer(),
          if (unread > 0 && !isLoading)
            compact
                ? SLIconButton(
                    icon: Icons.done_all_rounded,
                    tooltip: label,
                    onPressed: onMarkAllRead,
                  )
                : Semantics(
                    label: label,
                    child: ExcludeSemantics(
                      child: SLButton(
                        label: 'Отметить все как прочитанные',
                        variant: SLButtonVariant.ghost,
                        size: SLButtonSize.sm,
                        onPressed: onMarkAllRead,
                      ),
                    ),
                  ),
        ],
      ),
    );
  }
}

/// Баннер «все типы уведомлений отключены».
///
/// Показывается только когда настройки уже загружены: ошибка их загрузки
/// не должна превращаться во второе состояние ошибки на экране, который
/// и без настроек полностью работоспособен.
class _AllDisabledBanner extends ConsumerWidget {
  const _AllDisabledBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider).value;
    if (settings == null || !allNotificationsDisabled(settings)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: SLSpacing.space3),
      child: SLBanner(
        title: 'Все типы уведомлений отключены',
        description: 'Новые появляться не будут.',
        variant: SLBannerVariant.info,
        actionLabel: 'Настроить',
        onAction: () => context.go(AppRoutes.profile),
      ),
    );
  }
}

/// Хвост списка: догрузка или её ошибка.
class _Footer extends StatelessWidget {
  const _Footer({required this.failed, required this.onRetry});

  final bool failed;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    if (!failed) {
      return Center(
        child: Text(
          'Загружаем ещё…',
          style: text.label.copyWith(color: colors.textMuted),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Не удалось загрузить ещё',
          style: text.label.copyWith(color: colors.textMuted),
        ),
        const SizedBox(width: SLSpacing.space2),
        SLButton(
          label: 'Повторить',
          variant: SLButtonVariant.ghost,
          size: SLButtonSize.sm,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
