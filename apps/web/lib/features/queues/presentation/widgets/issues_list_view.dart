import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/features/queues/presentation/queue_issues_providers.dart';
import 'package:sl_tracker_web/shared/uikit/avatars/sl_avatar.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/effects/sl_shimmering_effect.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_status_chip.dart';
import 'package:sl_tracker_web/shared/uikit/lists/sl_issue_row.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/sl_shadows.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Виртуализированный список задач очереди с залипшей шапкой таблицы.
///
/// Всё, что связано со строками, живёт здесь, а не на экране: наведение,
/// клавиатурный курсор, меню статуса и контекстное меню меняются десятки раз
/// в секунду, и перестраивать из-за них шапку экрана и панель фильтров
/// незачем.
class IssuesListView extends StatefulWidget {
  /// @nodoc
  const IssuesListView({
    required this.page,
    required this.statuses,
    required this.layout,
    required this.queueKey,
    required this.onOpenIssue,
    required this.onOpenIssueInNewTab,
    required this.onChangeStatus,
    required this.onLoadMore,
    required this.onRetryLoadMore,
    required this.onEscape,
    super.key,
  });

  /// Загруженная часть списка.
  final QueueIssuesPage page;

  /// Статусы очереди для меню смены статуса.
  final List<IssueStatusRef> statuses;

  /// Набор колонок.
  final SLIssueRowLayout layout;

  /// Ключ очереди: нужен для копирования ссылок.
  final String queueKey;

  /// @nodoc
  final ValueChanged<String> onOpenIssue;

  /// @nodoc
  final ValueChanged<String> onOpenIssueInNewTab;

  /// Сменить статус. Возвращает `false`, если сервер отказал: строка тогда
  /// подсвечивается `dangerSurface`.
  final Future<bool> Function(String issueKey, IssueStatusRef status)
  onChangeStatus;

  /// @nodoc
  final VoidCallback onLoadMore;

  /// @nodoc
  final VoidCallback onRetryLoadMore;

  /// `Esc`: курсор снят, фокус возвращается в панель фильтров.
  final VoidCallback onEscape;

  /// Сколько держится подсветка после успешного изменения.
  static const successFlash = Duration(milliseconds: 200);

  /// Сколько держится подсветка после отката.
  static const failureFlash = Duration(milliseconds: 400);

  @override
  State<IssuesListView> createState() => _IssuesListViewState();
}

/// Чем подсвечена строка после изменения.
enum _Flash {
  /// Изменение применено.
  success,

  /// Изменение откатилось.
  failure,
}

class _IssuesListViewState extends State<IssuesListView> {
  final _scrollController = ScrollController();
  final _listKey = GlobalKey();
  final _focusNode = FocusNode(debugLabel: 'queue-issues-list');

  int? _hoveredIndex;
  int? _cursorIndex;
  int? _statusMenuIndex;
  String? _flashKey;
  _Flash? _flashKind;
  Timer? _flashTimer;
  var _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Правый клик по строке открывает наше меню, а не браузерное. Гасить
    // нативное меню приходится явно: в вебе иначе поверх нашего появится
    // системное (`queue-issues.md`, «Реализация во Flutter»).
    if (kIsWeb) BrowserContextMenu.disableContextMenu();
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _focusNode.dispose();
    if (kIsWeb) unawaited(BrowserContextMenu.enableContextMenu());
    super.dispose();
  }

  @override
  void didUpdateWidget(IssuesListView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Список стал короче — курсор не должен указывать в пустоту.
    final count = widget.page.items.length;
    if (_cursorIndex != null && _cursorIndex! >= count) {
      _cursorIndex = count == 0 ? null : count - 1;
    }
  }

  double get _extent => widget.layout.extent;

  void _onScroll() {
    final scrolled = _scrollController.offset > 0;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
  }

  bool _onScrollNotification(ScrollNotification notification) {
    final threshold = _extent * QueueIssuesController.loadMoreThresholdRows;
    if (notification.metrics.extentAfter < threshold) widget.onLoadMore();

    return false;
  }

  void _setHovered(int index, bool hovered) {
    final next = hovered
        ? index
        : (_hoveredIndex == index ? null : _hoveredIndex);
    if (next == _hoveredIndex) return;

    setState(() => _hoveredIndex = next);
  }

  /// Держит курсор в видимой области без анимации.
  ///
  /// Считаем по индексу, а не через `ensureVisible`: экстент строки
  /// фиксирован, и арифметика здесь точнее и дешевле обхода дерева.
  void _revealCursor() {
    final index = _cursorIndex;
    if (index == null || !_scrollController.hasClients) return;

    final position = _scrollController.position;
    final top = index * _extent;
    final bottom = top + _extent;

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

  void _moveCursor(int delta) {
    final count = widget.page.items.length;
    if (count == 0) return;

    final current = _cursorIndex;
    final next = current == null
        ? (delta > 0 ? 0 : count - 1)
        : (current + delta).clamp(0, count - 1);

    setState(() => _cursorIndex = next);
    _revealCursor();
  }

  void _setCursor(int index) {
    final count = widget.page.items.length;
    if (count == 0) return;

    setState(() => _cursorIndex = index.clamp(0, count - 1));
    _revealCursor();
  }

  int get _pageStep {
    if (!_scrollController.hasClients) return 10;

    return (_scrollController.position.viewportDimension / _extent)
        .floor()
        .clamp(1, 100);
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;
    final withCommand = keyboard.isControlPressed || keyboard.isMetaPressed;
    final cursor = _cursorIndex;

    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyJ) {
      _moveCursor(1);

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
      _setCursor(widget.page.items.length - 1);

      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageDown) {
      _moveCursor(_pageStep);

      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp) {
      _moveCursor(-_pageStep);

      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      setState(() => _cursorIndex = null);
      widget.onEscape();

      return KeyEventResult.handled;
    }

    if (cursor == null) return KeyEventResult.ignored;
    final row = widget.page.items[cursor];

    if (key == LogicalKeyboardKey.enter) {
      if (withCommand) {
        widget.onOpenIssueInNewTab(row.key);
      } else {
        widget.onOpenIssue(row.key);
      }

      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyS && widget.page.canEdit) {
      unawaited(_openStatusMenu(cursor));

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Прямоугольник строки в глобальных координатах.
  ///
  /// Нужен, чтобы открыть меню у самой строки, а не в углу экрана. Считается
  /// по индексу: экстент фиксирован, и обходить дерево ради этого не нужно.
  Rect? _rowRect(int index) {
    final box = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !_scrollController.hasClients) return null;

    final origin = box.localToGlobal(Offset.zero);
    final top = origin.dy + index * _extent - _scrollController.offset;

    return Rect.fromLTWH(origin.dx, top, box.size.width, _extent);
  }

  Future<void> _openStatusMenu(int index, {Offset? at}) async {
    if (!widget.page.canEdit || widget.statuses.isEmpty) return;
    if (index >= widget.page.items.length) return;

    final row = widget.page.items[index];
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final anchor =
        at ??
        _rowRect(index)?.bottomLeft.translate(
          SLIssueRow.horizontalPadding + SLIssueRow.checkboxColumn,
          0,
        ) ??
        Offset.zero;

    setState(() => _statusMenuIndex = index);

    final colors = SLColorScheme.of(context);

    final selected = await showMenu<IssueStatusRef>(
      context: context,
      position: RelativeRect.fromRect(
        anchor & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: [
        for (final status in widget.statuses)
          PopupMenuItem<IssueStatusRef>(
            value: status,
            height: 32,
            child: Row(
              children: [
                SLStatusChip(status: status.palette, label: status.name),
                const Spacer(),
                if (status.key == row.status.key)
                  Icon(
                    Icons.check_rounded,
                    size: SLIconSizes.icon16,
                    color: colors.accent,
                  ),
              ],
            ),
          ),
      ],
    );

    if (!mounted) return;
    setState(() => _statusMenuIndex = null);

    if (selected == null || selected.key == row.status.key) return;

    // Результат объявляется тостом, который показывает экран: подсветка
    // строки — вторая половина сигнала, а не единственная.
    final applied = await widget.onChangeStatus(row.key, selected);
    if (!mounted) return;

    _flash(row.key, applied ? _Flash.success : _Flash.failure);
  }

  void _flash(String issueKey, _Flash kind) {
    _flashTimer?.cancel();
    setState(() {
      _flashKey = issueKey;
      _flashKind = kind;
    });

    _flashTimer = Timer(
      kind == _Flash.success
          ? IssuesListView.successFlash
          : IssuesListView.failureFlash,
      () {
        if (!mounted) return;
        setState(() {
          _flashKey = null;
          _flashKind = null;
        });
      },
    );
  }

  Future<void> _openContextMenu(int index, Offset position) async {
    final row = widget.page.items[index];
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final navigatorOrigin = Uri.base.origin;

    setState(() => _cursorIndex = index);

    PopupMenuItem<String> item(String value, String label, IconData icon) =>
        PopupMenuItem<String>(
          value: value,
          height: 32,
          child: Row(
            children: [
              Icon(icon, size: SLIconSizes.icon16, color: colors.iconDefault),
              const SizedBox(width: SLSpacing.space2),
              Text(
                label,
                style: text.bodyS.copyWith(color: colors.textPrimary),
              ),
            ],
          ),
        );

    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: [
        item('open', 'Открыть', Icons.open_in_browser_rounded),
        item('open_tab', 'Открыть в новой вкладке', Icons.open_in_new_rounded),
        item('copy_key', 'Копировать ключ', Icons.tag_rounded),
        item('copy_link', 'Копировать ссылку', Icons.link_rounded),
        // Читателю менять нечего: пункт не серый, его нет вовсе.
        if (widget.page.canEdit) ...[
          const PopupMenuDivider(),
          item('status', 'Сменить статус', Icons.play_circle_outline_rounded),
        ],
      ],
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'open':
        widget.onOpenIssue(row.key);
      case 'open_tab':
        widget.onOpenIssueInNewTab(row.key);
      case 'copy_key':
        await Clipboard.setData(ClipboardData(text: row.key));
      case 'copy_link':
        await Clipboard.setData(
          ClipboardData(
            text: '$navigatorOrigin${AppRoutes.issuePath(row.key)}',
          ),
        );
      case 'status':
        await _openStatusMenu(index, at: position);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final page = widget.page;
    final extraRows =
        (page.isLoadingMore ? 1 : 0) + (page.loadMoreFailed ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Шапка таблицы залипшая: она лежит над списком, а не внутри него,
        // поэтому не участвует в прокрутке и не ломает `itemExtent`.
        DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: _scrolled ? SLShadows.sm : const [],
          ),
          child: SLIssueTableHeader(layout: widget.layout),
        ),
        Expanded(
          child: Focus(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: _onKeyEvent,
            child: Semantics(
              container: true,
              label: 'Задачи очереди ${widget.queueKey}',
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: ListView.builder(
                  key: _listKey,
                  controller: _scrollController,
                  // Фиксированный экстент обязателен: без него прокрутка
                  // и `Scrollbar` начинают считать весь список.
                  itemExtent: _extent,
                  itemCount: page.items.length + extraRows,
                  itemBuilder: (context, index) {
                    if (index >= page.items.length) {
                      return _buildTailRow(colors);
                    }

                    return _buildRow(index);
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(int index) {
    final row = widget.page.items[index];
    final assignee = row.assignee;
    final flash = row.key == _flashKey ? _flashKind : null;

    final child = SLIssueRow(
      issueKey: row.key,
      title: row.title,
      status: row.status,
      priority: row.priority,
      storyPoints: row.storyPoints,
      assignee: assignee == null
          ? null
          : SLAvatarData(
              userId: assignee.id,
              fullName: assignee.displayName,
              photoUrl: assignee.avatarUrl,
            ),
      layout: widget.layout,
      hovered: _hoveredIndex == index,
      focused: _cursorIndex == index,
      isStatusMenuOpen: _statusMenuIndex == index,
      onHover: (value) => _setHovered(index, value),
      onTap: () => widget.onOpenIssue(row.key),
      onOpenInNewTab: () => widget.onOpenIssueInNewTab(row.key),
      onStatusPressed: widget.page.canEdit
          ? () => unawaited(_openStatusMenu(index))
          : null,
      onSecondaryTap: (position) =>
          unawaited(_openContextMenu(index, position)),
    );

    if (flash == null) return child;

    final colors = SLColorScheme.of(context);

    // Подсветка кладётся поверх строки, а не подменяет её фон: строка
    // остаётся ровно той же, и после угасания ничего не перестраивается.
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: flash == _Flash.success
                  ? colors.accentSurface.withValues(alpha: 0.5)
                  : colors.dangerSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  /// Хвост списка: скелетон дозагрузки либо строка ошибки с «Повторить».
  Widget _buildTailRow(SLColorScheme colors) {
    if (widget.page.loadMoreFailed) {
      final text = SLTextScheme.of(context);

      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SLIssueRow.horizontalPadding,
        ),
        child: Row(
          children: [
            Text(
              'Не удалось загрузить ещё',
              style: text.bodyS.copyWith(color: colors.textMuted),
            ),
            const SizedBox(width: SLSpacing.space2),
            SLButton(
              label: 'Повторить',
              variant: SLButtonVariant.ghost,
              size: SLButtonSize.sm,
              onPressed: widget.onRetryLoadMore,
            ),
          ],
        ),
      );
    }

    return SLShimmeringEffect(
      child: SLIssueRowSkeleton(index: 0, layout: widget.layout),
    );
  }
}
