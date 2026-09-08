import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/utils/sl_date_format.dart';
import 'package:sl_tracker_web/features/access/presentation/widgets/access_source_badge.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_icon_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/sl_motion.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_middle_ellipsis_text.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Строка списка доступа (`docs/design/screens/access-list.md`).
///
/// Высота 40 на десктопе — это `itemExtent` виртуализированного списка,
/// поэтому она задана числом, а не собирается из отступов.
class AccessEntryRow extends StatefulWidget {
  /// @nodoc
  const AccessEntryRow({
    required this.entry,
    required this.onRevoke,
    required this.onToggleOwner,
    this.highlighted = false,
    this.compact = false,
    this.dense = false,
    super.key,
  });

  /// Запись.
  final AccessEntryDto entry;

  /// Открыть подтверждение удаления. `null` — удалять эту запись нельзя.
  final VoidCallback? onRevoke;

  /// Выдать или снять признак владельца.
  final VoidCallback onToggleOwner;

  /// Строка только что добавлена: подсвечена 1200 мс.
  final bool highlighted;

  /// Телефонная раскладка: карточка в две строки вместо таблицы.
  final bool compact;

  /// Узкая колонка даты (`md`): «12.02» вместо «12 фев».
  final bool dense;

  /// Высота строки на десктопе и планшете.
  static const height = 40.0;

  /// Высота карточки на телефоне.
  static const compactHeight = 72.0;

  /// Ширина колонки даты.
  static const dateColumnWidth = 140.0;

  /// Ширина колонки даты на `md`.
  static const denseDateColumnWidth = 96.0;

  /// Ширина колонки действий.
  static const actionsColumnWidth = 40.0;

  @override
  State<AccessEntryRow> createState() => _AccessEntryRowState();
}

class _AccessEntryRowState extends State<AccessEntryRow> {
  final _menuController = MenuController();
  var _hovered = false;
  var _focused = false;

  /// `Enter` открывает меню строки, `Delete` — подтверждение удаления.
  ///
  /// `Delete` намеренно не удаляет сразу: у опасных действий не бывает
  /// хоткея прямого действия.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        node.focusInDirection(TraversalDirection.down);

        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        node.focusInDirection(TraversalDirection.up);

        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        _menuController.open();

        return KeyEventResult.handled;
      case LogicalKeyboardKey.delete:
        widget.onRevoke?.call();

        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final entry = widget.entry;

    final background = switch (widget.highlighted) {
      true => colors.accentSurface,
      false when _hovered => colors.surfaceHover,
      false => colors.surface,
    };

    return Semantics(
      label: _semanticsLabel(entry),
      excludeSemantics: true,
      child: Focus(
        onKeyEvent: _onKeyEvent,
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: SLFocusRing(
            focused: _focused,
            inset: true,
            child: AnimatedContainer(
              duration: SLMotion.durationOf(context, SLMotion.base),
              height: widget.compact
                  ? AccessEntryRow.compactHeight
                  : AccessEntryRow.height,
              decoration: BoxDecoration(
                color: background,
                border: Border(
                  bottom: BorderSide(
                    color: colors.borderSubtle,
                    width: SLBorders.hairline,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space3),
              child: widget.compact
                  ? _buildCompact(context)
                  : _buildRow(context),
            ),
          ),
        ),
      ),
    );
  }

  /// Полное описание строки для скринридера: иначе он прочитает четыре
  /// одинаковые кнопки «Ещё» и ничего больше.
  String _semanticsLabel(AccessEntryDto entry) {
    final parts = [
      entry.email,
      'источник: ${AccessSourceBadge.labelOf(entry.source).toLowerCase()}',
      'добавлен ${SLDateFormat.exact(entry.createdAt)}',
      if (entry.isInstanceOwner) 'владелец трекера',
      if (entry.isSelf) 'это вы',
    ];

    return parts.join(', ');
  }

  Widget _buildRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _EmailCell(entry: widget.entry)),
        const SizedBox(width: SLSpacing.space3),
        SizedBox(
          width: AccessSourceBadge.columnWidth,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AccessSourceBadge(source: widget.entry.source),
          ),
        ),
        SizedBox(
          width: widget.dense
              ? AccessEntryRow.denseDateColumnWidth
              : AccessEntryRow.dateColumnWidth,
          child: _DateCell(date: widget.entry.createdAt, dense: widget.dense),
        ),
        SizedBox(
          width: AccessEntryRow.actionsColumnWidth,
          child: _buildMenu(context),
        ),
      ],
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EmailCell(entry: widget.entry),
              const SizedBox(height: SLSpacing.space1),
              Row(
                children: [
                  AccessSourceBadge(source: widget.entry.source),
                  const SizedBox(width: SLSpacing.space2),
                  Flexible(
                    child: _DateCell(
                      date: widget.entry.createdAt,
                      dense: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildMenu(context),
      ],
    );
  }

  Widget _buildMenu(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final entry = widget.entry;

    return MenuAnchor(
      controller: _menuController,
      menuChildren: [
        MenuItemButton(
          onPressed: widget.onToggleOwner,
          child: Text(
            entry.isInstanceOwner
                ? 'Снять права владельца'
                : 'Сделать владельцем трекера',
            style: text.bodyS.copyWith(color: colors.textPrimary),
          ),
        ),
        if (widget.onRevoke != null)
          MenuItemButton(
            onPressed: widget.onRevoke,
            child: Text(
              'Удалить из списка',
              style: text.bodyS.copyWith(color: colors.danger),
            ),
          )
        else
          // Не выключенный пункт, а пояснение: выключенный контрол выглядит
          // как поломка, а причина всё равно остаётся невысказанной.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SLSpacing.space3,
              vertical: SLSpacing.space2,
            ),
            child: Text(
              'Нельзя удалить собственный доступ',
              style: text.label.copyWith(color: colors.textMuted),
            ),
          ),
      ],
      builder: (context, controller, child) => SLIconButton(
        icon: Icons.more_horiz_rounded,
        tooltip: 'Действия для ${entry.email}',
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// Адрес и пометки «(вы)» и «владелец».
class _EmailCell extends StatelessWidget {
  const _EmailCell({required this.entry});

  final AccessEntryDto entry;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Row(
      children: [
        Flexible(
          child: SLMiddleEllipsisText(
            value: entry.email,
            style: text.bodyS.copyWith(color: colors.textPrimary),
          ),
        ),
        if (entry.isSelf) ...[
          const SizedBox(width: SLSpacing.space2),
          Text('(вы)', style: text.label.copyWith(color: colors.textMuted)),
        ],
        if (entry.isInstanceOwner) ...[
          const SizedBox(width: SLSpacing.space2),
          const _OwnerBadge(),
        ],
      ],
    );
  }
}

/// Пометка «Владелец трекера».
///
/// Владелец — единственная глобальная роль: она даёт право вести список
/// доступа и не даёт никаких прав внутри проектов.
class _OwnerBadge extends StatelessWidget {
  const _OwnerBadge();

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Container(
      height: AccessSourceBadge.height,
      padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space2),
      decoration: BoxDecoration(
        borderRadius: SLRadii.smAll,
        border: Border.all(color: colors.border, width: SLBorders.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.key_rounded,
            size: SLIconSizes.icon12,
            color: colors.iconMuted,
          ),
          const SizedBox(width: SLSpacing.space1),
          Text(
            'Владелец',
            style: text.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Дата добавления. Точное время — в тултипе.
class _DateCell extends StatelessWidget {
  const _DateCell({required this.date, required this.dense});

  final DateTime date;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Tooltip(
      message: SLDateFormat.exact(date),
      child: Text(
        dense ? SLDateFormat.numeric(date) : SLDateFormat.short(date),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.bodyS.copyWith(color: colors.textMuted),
      ),
    );
  }
}
