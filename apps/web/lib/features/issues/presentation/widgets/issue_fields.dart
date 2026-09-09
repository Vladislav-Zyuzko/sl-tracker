import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/domain/issue_complexity.dart';
import 'package:sl_tracker_web/core/domain/issue_priority.dart';
import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/features/issues/domain/issue_fields.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_providers.dart';
import 'package:sl_tracker_web/shared/uikit/avatars/sl_avatar.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_complexity_indicator.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_priority_indicator.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_status_chip.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_search_field.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Подпись поля над значением.
class IssueFieldLabel extends StatelessWidget {
  /// @nodoc
  const IssueFieldLabel(this.label, {super.key});

  /// @nodoc
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: SLSpacing.space1),
      child: Text(
        label,
        style: text.label.copyWith(color: colors.textSecondary),
      ),
    );
  }
}

/// Статус задачи выпадающим списком (`components.md`, 5).
///
/// Значения — статусы **этой очереди**, а не зашитая в клиент пятёрка:
/// у каждой очереди свой набор (ADR-0003).
class IssueStatusField extends StatefulWidget {
  /// @nodoc
  const IssueStatusField({
    required this.status,
    required this.statuses,
    required this.onChanged,
    this.enabled = true,
    this.focusNode,
    super.key,
  });

  /// Текущий статус.
  final IssueStatusRef status;

  /// Набор статусов очереди.
  final List<IssueStatusRef> statuses;

  /// @nodoc
  final ValueChanged<IssueStatusRef> onChanged;

  /// @nodoc
  final bool enabled;

  /// @nodoc
  final FocusNode? focusNode;

  @override
  State<IssueStatusField> createState() => IssueStatusFieldState();
}

/// Состояние поля статуса: открывается снаружи по хоткею `s`.
class IssueStatusFieldState extends State<IssueStatusField> {
  final _controller = MenuController();

  /// Открывает меню — вызывается хоткеем экрана.
  void open() {
    if (!widget.enabled) return;
    _controller.open();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    if (!widget.enabled || widget.statuses.isEmpty) {
      // У читателя — плашка без шеврона: обещать действие, которого нет,
      // нельзя ни глазу, ни скринридеру.
      return Semantics(
        label: 'Статус: ${widget.status.name}',
        excludeSemantics: true,
        child: SLStatusChip(
          status: widget.status.palette,
          label: widget.status.name,
          size: SLStatusChipSize.regular,
        ),
      );
    }

    return MenuAnchor(
      controller: _controller,
      childFocusNode: widget.focusNode,
      menuChildren: [
        for (final status in widget.statuses)
          MenuItemButton(
            onPressed: () => widget.onChanged(status),
            trailingIcon: status.key == widget.status.key
                ? Icon(
                    Icons.check_rounded,
                    size: SLIconSizes.icon16,
                    color: colors.accent,
                  )
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SLStatusChip(status: status.palette, label: status.name),
                const SizedBox(width: SLSpacing.space2),
                Text(
                  status.name,
                  style: text.bodyS.copyWith(color: colors.textPrimary),
                ),
              ],
            ),
          ),
      ],
      builder: (context, controller, child) => Semantics(
        label: 'Статус: ${widget.status.name}, изменить',
        button: true,
        excludeSemantics: true,
        child: SLStatusChip(
          status: widget.status.palette,
          label: widget.status.name,
          size: SLStatusChipSize.regular,
          isMenuOpen: controller.isOpen,
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        ),
      ),
    );
  }
}

/// Приоритет: индикатор в расширенной форме плюс меню одиннадцати значений.
class IssuePriorityField extends StatelessWidget {
  /// @nodoc
  const IssuePriorityField({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// @nodoc
  final int value;

  /// @nodoc
  final ValueChanged<int> onChanged;

  /// @nodoc
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final indicator = SLPriorityIndicator(value: value, expanded: true);
    if (!enabled) {
      return Semantics(
        label:
            'Приоритет $value из 100, '
            '${PriorityRange.of(value).label.toLowerCase()}',
        excludeSemantics: true,
        child: indicator,
      );
    }

    return _MenuField(
      semanticLabel:
          'Приоритет $value из 100, '
          '${PriorityRange.of(value).label.toLowerCase()}, изменить',
      menuChildren: [
        for (final option in IssuePriority.descendingValues)
          MenuItemButton(
            onPressed: () => onChanged(option),
            trailingIcon: option == value ? const _Check() : null,
            child: SLPriorityIndicator(value: option, expanded: true),
          ),
      ],
      child: indicator,
    );
  }
}

/// Сложность: шкала Фибоначчи плюс «Снять оценку».
class IssueComplexityField extends StatelessWidget {
  /// @nodoc
  const IssueComplexityField({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// Сложность. `null` — «не оценено» (US-51).
  final int? value;

  /// @nodoc
  final ValueChanged<int?> onChanged;

  /// @nodoc
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    final display = value == null
        ? Text(
            'Не оценено',
            style: text.bodyS.copyWith(color: colors.textMuted),
          )
        : SLComplexityIndicator(value: value);

    if (!enabled) {
      return Semantics(
        label: value == null
            ? 'Сложность не оценена'
            : 'Сложность $value story points',
        excludeSemantics: true,
        child: display,
      );
    }

    return _MenuField(
      semanticLabel: value == null
          ? 'Сложность не оценена, изменить'
          : 'Сложность $value story points, изменить',
      menuChildren: [
        for (final option in IssueComplexity.values)
          MenuItemButton(
            onPressed: () => onChanged(option),
            trailingIcon: option == value ? const _Check() : null,
            child: SLComplexityIndicator(value: option),
          ),
        MenuItemButton(
          onPressed: () => onChanged(null),
          child: Text(
            'Снять оценку',
            style: text.bodyS.copyWith(color: colors.textSecondary),
          ),
        ),
      ],
      child: display,
    );
  }
}

/// Селектор пользователя (`components.md`, 6).
///
/// Поиск идёт **на сервере**, среди участников проекта задачи: списка всех
/// пользователей трекера у клиента нет и быть не должно.
class IssueUserField extends ConsumerStatefulWidget {
  /// @nodoc
  const IssueUserField({
    required this.issueKey,
    required this.user,
    required this.onChanged,
    this.onClear,
    this.enabled = true,
    this.focusNode,
    super.key,
  });

  /// @nodoc
  final String issueKey;

  /// Текущее значение. `null` — «Не назначен».
  final IssueUserDto? user;

  /// @nodoc
  final ValueChanged<IssueUserDto> onChanged;

  /// «Снять назначение». `null` — поле очистить нельзя (так у автора).
  final VoidCallback? onClear;

  /// @nodoc
  final bool enabled;

  /// @nodoc
  final FocusNode? focusNode;

  /// Пауза перед запросом при наборе в поиске.
  static const debounce = Duration(milliseconds: 220);

  /// Высота строки меню.
  static const rowHeight = 32.0;

  /// Ширина меню.
  static const menuWidth = 280.0;

  @override
  ConsumerState<IssueUserField> createState() => IssueUserFieldState();
}

/// Состояние селектора: открывается снаружи по хоткею `a`.
class IssueUserFieldState extends ConsumerState<IssueUserField> {
  final _menu = MenuController();
  final _search = TextEditingController();
  var _query = '';

  /// Открывает меню — вызывается хоткеем экрана.
  void open() {
    if (!widget.enabled) return;
    _menu.open();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    if (mounted) setState(() => _query = value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final trigger = _Trigger(user: widget.user);

    if (!widget.enabled) {
      return Semantics(
        label: widget.user == null
            ? 'Не назначен'
            : widget.user!.displayName,
        excludeSemantics: true,
        child: trigger,
      );
    }

    return MenuAnchor(
      controller: _menu,
      childFocusNode: widget.focusNode,
      onOpen: () {
        _search.clear();
        setState(() => _query = '');
      },
      menuChildren: [
        SizedBox(
          width: IssueUserField.menuWidth,
          child: Padding(
            padding: const EdgeInsets.all(SLSpacing.space2),
            // Дебаунс и минимальная длина запроса — у самого поля:
            // одна буквa здесь уже осмысленный фильтр, поэтому порог 1.
            child: SLSearchField(
              controller: _search,
              hint: 'Начните вводить имя',
              showHotkeyHint: false,
              minQueryLength: 1,
              debounce: IssueUserField.debounce,
              onQueryChanged: _onQueryChanged,
            ),
          ),
        ),
        SizedBox(
          width: IssueUserField.menuWidth,
          child: _Results(
            issueKey: widget.issueKey,
            query: _query,
            selectedId: widget.user?.id,
            onSelect: (user) {
              _menu.close();
              widget.onChanged(user);
            },
          ),
        ),
        if (widget.onClear != null && widget.user != null)
          MenuItemButton(
            onPressed: () {
              _menu.close();
              widget.onClear!();
            },
            leadingIcon: const Icon(
              Icons.block_rounded,
              size: SLIconSizes.icon16,
            ),
            child: const Text('Снять назначение'),
          ),
      ],
      builder: (context, controller, child) => Semantics(
        label:
            '${widget.user?.displayName ?? 'Не назначен'}, изменить',
        button: true,
        excludeSemantics: true,
        child: InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          borderRadius: SLRadii.smAll,
          child: trigger,
        ),
      ),
    );
  }
}

/// Результаты поиска участников. Список виртуализирован: в крупном проекте
/// участников сотни.
class _Results extends ConsumerWidget {
  const _Results({
    required this.issueKey,
    required this.query,
    required this.selectedId,
    required this.onSelect,
  });

  final String issueKey;
  final String query;
  final String? selectedId;
  final ValueChanged<IssueUserDto> onSelect;

  /// Максимальная высота списка результатов.
  static const maxHeight = 200.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final members = ref.watch(
      issueMembersProvider(
        IssueMemberQuery(issueKey: issueKey, query: query),
      ),
    );

    return switch (members) {
      AsyncError() => _Message(
        text: 'Не удалось загрузить список',
        onRetry: () => ref.invalidate(
          issueMembersProvider(
            IssueMemberQuery(issueKey: issueKey, query: query),
          ),
        ),
      ),
      AsyncData(:final value) when value.isEmpty => const _Message(
        text: 'Никого не нашли среди участников проекта',
      ),
      AsyncData(:final value) => ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: maxHeight),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemExtent: IssueUserField.rowHeight,
          itemCount: value.length,
          itemBuilder: (context, index) {
            final item = value[index];

            return InkWell(
              onTap: () => onSelect(issueUserOf(item)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SLSpacing.space3,
                ),
                child: Row(
                  children: [
                    SLAvatar(
                      userId: item.id,
                      fullName: item.displayName,
                      photoUrl: item.avatarUrl,
                      decorative: true,
                    ),
                    const SizedBox(width: SLSpacing.space2),
                    Expanded(
                      child: Text(
                        item.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyS.copyWith(color: colors.textPrimary),
                      ),
                    ),
                    if (item.id == selectedId) const _Check(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      _ => const _Message(text: 'Загружаем участников…'),
    };
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final scheme = SLTextScheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SLSpacing.space3,
        vertical: SLSpacing.space2,
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              text,
              style: scheme.bodyS.copyWith(color: colors.textMuted),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}

/// Триггер селектора: аватар и имя либо заглушка «Не назначен».
class _Trigger extends StatelessWidget {
  const _Trigger({required this.user});

  final IssueUserDto? user;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final value = user;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value == null)
          Container(
            width: SLAvatarSize.xs.diameter,
            height: SLAvatarSize.xs.diameter,
            decoration: BoxDecoration(
              color: colors.surfaceSunken,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: SLIconSizes.icon12,
              color: colors.iconMuted,
            ),
          )
        else
          SLAvatar(
            userId: value.id,
            fullName: value.displayName,
            photoUrl: value.avatarUrl,
            decorative: true,
          ),
        const SizedBox(width: SLSpacing.space2),
        Flexible(
          child: Tooltip(
            message: value?.displayName ?? 'Не назначен',
            child: Text(
              value?.displayName ?? 'Не назначен',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyS.copyWith(
                color: value == null ? colors.textMuted : colors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Поле-меню общего вида: триггер и список пунктов.
class _MenuField extends StatelessWidget {
  const _MenuField({
    required this.semanticLabel,
    required this.menuChildren,
    required this.child,
  });

  final String semanticLabel;
  final List<Widget> menuChildren;
  final Widget child;

  @override
  Widget build(BuildContext context) => MenuAnchor(
    menuChildren: menuChildren,
    builder: (context, controller, _) => Semantics(
      label: semanticLabel,
      button: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: () =>
            controller.isOpen ? controller.close() : controller.open(),
        borderRadius: SLRadii.smAll,
        child: Align(alignment: Alignment.centerLeft, child: child),
      ),
    ),
  );
}

class _Check extends StatelessWidget {
  const _Check();

  @override
  Widget build(BuildContext context) => Icon(
    Icons.check_rounded,
    size: SLIconSizes.icon16,
    color: SLColorScheme.of(context).accent,
  );
}
