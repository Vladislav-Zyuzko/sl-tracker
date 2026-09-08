import 'package:flutter/material.dart';

import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_status_colors.dart';
import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/sl_motion.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Размер плашки статуса (`docs/design/components.md`, 7).
enum SLStatusChipSize {
  /// Высота 20. Строка списка задач.
  compact,

  /// Высота 24. Карточка задачи, кликабельна.
  regular,
}

/// Плашка статуса задачи.
///
/// Цвет — четвёртый канал смысла после текста, иконки и позиции. Поэтому
/// текст статуса обязателен всегда: сокращать плашку до одной цветной точки
/// запрещено даже в самых плотных раскладках (`system.md`, 4).
///
/// Текст статуса не обрезается никогда: если места не хватает, сжимается всё
/// остальное в строке. Это единственный элемент строки с таким приоритетом.
class SLStatusChip extends StatelessWidget {
  /// @nodoc
  const SLStatusChip({
    required this.status,
    this.label,
    this.size = SLStatusChipSize.compact,
    this.onPressed,
    this.isMenuOpen = false,
    super.key,
  });

  /// Статус задачи: он задаёт палитру и иконку.
  final IssueStatus status;

  /// Название статуса от сервера. Статусы — данные, а не перечисление
  /// (ADR-0003): очередь вправе назвать статус по-своему, и показывать вместо
  /// её названия зашитую в клиент подпись нельзя. `null` — берём подпись
  /// из [status].
  final String? label;

  /// @nodoc
  final SLStatusChipSize size;

  /// Открыть меню смены статуса. `null` — плашка некликабельна и рисуется
  /// без шеврона: у пользователя нет прав либо это история изменений.
  final VoidCallback? onPressed;

  /// Меню открыто: шеврон повёрнут на 180°.
  final bool isMenuOpen;

  /// Иконка статуса. Формы намеренно непохожи друг на друга: при дейтеранопии
  /// «тестирование» и «закрыт» сливаются по тону, и различает их только форма
  /// (`system.md`, 4).
  static IconData iconOf(IssueStatus status) => switch (status) {
    IssueStatus.open => Icons.circle_outlined,
    IssueStatus.inProgress => Icons.play_circle_outline_rounded,
    IssueStatus.review => Icons.visibility_outlined,
    IssueStatus.testing => Icons.science_outlined,
    IssueStatus.closed => Icons.check_circle_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final statusColors = SLStatusColors.of(context);
    final text = SLTextScheme.of(context);
    final density = SLDensity.ofContext(context);
    final foreground = statusColors.textOf(status);
    final isCompact = size == SLStatusChipSize.compact;

    final height = isCompact ? density.statusChipRow : density.statusChipCard;
    final iconSize = isCompact ? SLIconSizes.icon12 : SLIconSizes.icon16;
    final labelStyle = isCompact ? text.caption : text.labelStrong;
    final isInteractive = onPressed != null;
    final title = label ?? status.label;

    final chip = Container(
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: SLSpacing.space2,
        // 2 px — зафиксированное исключение из шкалы отступов, вшитое
        // внутрь плашки (`system.md`, 10.1).
        vertical: isCompact ? 2 : SLSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: statusColors.surfaceOf(status),
        borderRadius: SLRadii.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconOf(status), size: iconSize, color: foreground),
          const SizedBox(width: SLSpacing.space1),
          Text(
            title,
            style: labelStyle.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
            softWrap: false,
          ),
          if (isInteractive) ...[
            const SizedBox(width: SLSpacing.space1),
            AnimatedRotation(
              turns: isMenuOpen ? 0.5 : 0,
              duration: SLMotion.durationOf(context, SLMotion.fast),
              curve: SLMotion.fastCurve,
              child: Icon(
                Icons.expand_more_rounded,
                size: iconSize,
                color: foreground,
              ),
            ),
          ],
        ],
      ),
    );

    if (!isInteractive) {
      return Semantics(
        label: 'Статус: $title',
        child: ExcludeSemantics(child: chip),
      );
    }

    return Semantics(
      button: true,
      label: 'Статус: $title, изменить',
      child: ExcludeSemantics(
        child: _InteractiveChip(onPressed: onPressed!, child: chip),
      ),
    );
  }
}

/// Кликабельная обёртка плашки: наведение затемняет её `overlayHover`,
/// клавиатурный фокус обводится кольцом, `Enter` и `Space` открывают меню.
class _InteractiveChip extends StatefulWidget {
  const _InteractiveChip({required this.onPressed, required this.child});

  final VoidCallback onPressed;
  final Widget child;

  @override
  State<_InteractiveChip> createState() => _InteractiveChipState();
}

class _InteractiveChipState extends State<_InteractiveChip> {
  var _hovered = false;
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);

    return SLFocusRing(
      focused: _focused,
      borderRadius: SLRadii.full,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed();

              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Stack(
            children: [
              widget.child,
              if (_hovered)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.overlayHover,
                        borderRadius: SLRadii.fullAll,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
