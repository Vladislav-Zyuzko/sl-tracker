import 'package:flutter/material.dart';

import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/features/queues/domain/issue_sort.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_status_chip.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Панель фильтров списка задач (`docs/design/screens/queue-issues.md`).
///
/// Фильтр по статусу — единственный в MVP-экране (US-32). Контракт принимает
/// ещё фильтры по исполнителю, автору и приоритету, но в интерфейс они
/// в MVP не выводятся (D-28): панель к ним готова, добавлять их самовольно
/// незачем.
class QueueIssuesToolbar extends StatelessWidget {
  /// @nodoc
  const QueueIssuesToolbar({
    required this.statuses,
    required this.selectedKeys,
    required this.sort,
    required this.onStatusesChanged,
    required this.onSortChanged,
    required this.filterFocusNode,
    this.total,
    super.key,
  });

  /// Статусы очереди в порядке `position`. Пусто — ещё грузятся.
  final List<IssueStatusRef> statuses;

  /// Выбранные ключи статусов.
  final List<String> selectedKeys;

  /// Текущий порядок.
  final IssueSort sort;

  /// Выбор изменился. Пустой список — «Все».
  final ValueChanged<List<String>> onStatusesChanged;

  /// @nodoc
  final ValueChanged<IssueSort> onSortChanged;

  /// Узел фокуса кнопки фильтра: на него наводит `f`.
  final FocusNode filterFocusNode;

  /// Сколько задач подходит под фильтр. `null` — ещё не знаем.
  final int? total;

  /// Со скольких выбранных статусов на кнопке пишется «N выбрано».
  static const namesLimit = 3;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final breakpoint = SLBreakpoint.of(context);
    final density = SLDensity.of(breakpoint);

    return Container(
      height: density.toolbarHeight,
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        border: Border(
          bottom: BorderSide(color: colors.border, width: SLBorders.hairline),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space4),
      child: breakpoint.isPhone
          ? _buildPhone(context)
          : _buildWide(context, breakpoint),
    );
  }

  Widget _buildWide(BuildContext context, SLBreakpoint breakpoint) {
    return Row(
      children: [
        _StatusFilterMenu(
          statuses: statuses,
          selectedKeys: selectedKeys,
          onChanged: onStatusesChanged,
          focusNode: filterFocusNode,
          label: triggerLabel,
        ),
        const SizedBox(width: SLSpacing.space3),
        _SortMenu(sort: sort, onChanged: onSortChanged),
        const Spacer(),
        // На планшете счётчик уходит: место нужнее фильтрам.
        if (!breakpoint.isTablet) _buildCounter(context),
      ],
    );
  }

  /// На телефоне вся панель сворачивается в одну кнопку с бейджем числа
  /// активных фильтров; сами фильтры живут в листе снизу.
  Widget _buildPhone(BuildContext context) {
    final activeCount =
        selectedKeys.length + (sort == IssueSort.initial ? 0 : 1);

    return Row(
      children: [
        SLButton(
          label: activeCount > 0 ? 'Фильтры · $activeCount' : 'Фильтры',
          icon: Icons.tune_rounded,
          variant: SLButtonVariant.secondary,
          focusNode: filterFocusNode,
          onPressed: () => _showSheet(context),
        ),
        const Spacer(),
        _buildCounter(context),
      ],
    );
  }

  Widget _buildCounter(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final value = total;

    return Semantics(
      liveRegion: true,
      child: Text(
        value == null ? '' : 'Показано $value',
        style: text.label.copyWith(color: colors.textMuted),
      ),
    );
  }

  /// Подпись кнопки-триггера: «Все», «В работе, Ревью» или «3 выбрано».
  ///
  /// Названия перечисляются в порядке статусов очереди, а не в порядке
  /// выбора: человек читает их как знакомый ряд, а не как историю кликов.
  String get triggerLabel {
    if (selectedKeys.isEmpty) return 'Все';

    final selected = [
      for (final status in statuses)
        if (selectedKeys.contains(status.key)) status.name,
    ];

    if (selected.isEmpty) return '${selectedKeys.length} выбрано';
    if (selected.length >= namesLimit) return '${selected.length} выбрано';

    return selected.join(', ');
  }

  Future<void> _showSheet(BuildContext context) async {
    final colors = SLColorScheme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      showDragHandle: true,
      builder: (context) => _FilterSheet(
        statuses: statuses,
        selectedKeys: selectedKeys,
        sort: sort,
        onStatusesChanged: onStatusesChanged,
        onSortChanged: onSortChanged,
      ),
    );
  }
}

/// Выпадающий список фильтра по статусу с множественным выбором.
class _StatusFilterMenu extends StatelessWidget {
  const _StatusFilterMenu({
    required this.statuses,
    required this.selectedKeys,
    required this.onChanged,
    required this.focusNode,
    required this.label,
  });

  final List<IssueStatusRef> statuses;
  final List<String> selectedKeys;
  final ValueChanged<List<String>> onChanged;
  final FocusNode focusNode;
  final String label;

  void _toggle(String key, {required bool selected}) {
    final next = [...selectedKeys];
    if (selected) {
      if (!next.contains(key)) next.add(key);
    } else {
      next.remove(key);
    }

    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return MenuAnchor(
      menuChildren: [
        CheckboxMenuButton(
          value: selectedKeys.isEmpty,
          // «Все» не снимается повторным нажатием: снять его нечем,
          // и полупустое состояние «ничего не выбрано, но фильтр включён»
          // не существует.
          onChanged: (_) => onChanged(const []),
          closeOnActivate: false,
          child: Text(
            'Все',
            style: text.bodyS.copyWith(color: colors.textPrimary),
          ),
        ),
        for (final status in statuses)
          CheckboxMenuButton(
            value: selectedKeys.contains(status.key),
            onChanged: (value) => _toggle(status.key, selected: value ?? false),
            closeOnActivate: false,
            child: SLStatusChip(status: status.palette, label: status.name),
          ),
      ],
      builder: (context, controller, child) => SLButton(
        label: 'Статус: $label',
        icon: Icons.expand_more_rounded,
        variant: SLButtonVariant.secondary,
        focusNode: focusNode,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// Выпадающий список сортировки.
class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.sort, required this.onChanged});

  final IssueSort sort;
  final ValueChanged<IssueSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return MenuAnchor(
      menuChildren: [
        for (final value in IssueSort.values)
          MenuItemButton(
            leadingIcon: Icon(
              Icons.check_rounded,
              size: SLIconSizes.icon16,
              color: value == sort ? colors.accent : Colors.transparent,
            ),
            onPressed: () => onChanged(value),
            child: Text(
              value.label,
              style: text.bodyS.copyWith(color: colors.textPrimary),
            ),
          ),
      ],
      builder: (context, controller, child) => SLButton(
        label: 'Сортировка: ${sort.label}',
        icon: Icons.expand_more_rounded,
        variant: SLButtonVariant.ghost,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// Фильтры на телефоне: лист снизу вместо ряда кнопок.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.statuses,
    required this.selectedKeys,
    required this.sort,
    required this.onStatusesChanged,
    required this.onSortChanged,
  });

  final List<IssueStatusRef> statuses;
  final List<String> selectedKeys;
  final IssueSort sort;
  final ValueChanged<List<String>> onStatusesChanged;
  final ValueChanged<IssueSort> onSortChanged;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late var _selected = [...widget.selectedKeys];
  late var _sort = widget.sort;

  void _toggle(String key, {required bool selected}) {
    setState(() {
      if (selected) {
        if (!_selected.contains(key)) _selected.add(key);
      } else {
        _selected.remove(key);
      }
    });
    widget.onStatusesChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(SLSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Статус',
              style: text.overline.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: SLSpacing.space2),
            CheckboxListTile(
              value: _selected.isEmpty,
              onChanged: (_) {
                setState(() => _selected = []);
                widget.onStatusesChanged(const []);
              },
              title: Text(
                'Все',
                style: text.bodyS.copyWith(color: colors.textPrimary),
              ),
            ),
            for (final status in widget.statuses)
              CheckboxListTile(
                value: _selected.contains(status.key),
                onChanged: (value) =>
                    _toggle(status.key, selected: value ?? false),
                title: SLStatusChip(status: status.palette, label: status.name),
              ),
            const SizedBox(height: SLSpacing.space4),
            Text(
              'Сортировка',
              style: text.overline.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: SLSpacing.space2),
            RadioGroup<IssueSort>(
              groupValue: _sort,
              onChanged: (next) {
                if (next == null) return;
                setState(() => _sort = next);
                widget.onSortChanged(next);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final value in IssueSort.values)
                    RadioListTile<IssueSort>(
                      value: value,
                      title: Text(
                        value.label,
                        style: text.bodyS.copyWith(color: colors.textPrimary),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
