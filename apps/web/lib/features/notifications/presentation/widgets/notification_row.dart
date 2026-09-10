import 'package:flutter/material.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/utils/sl_date_format.dart';
import 'package:sl_tracker_web/features/notifications/domain/notification_line.dart';
import 'package:sl_tracker_web/shared/uikit/avatars/sl_avatar.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/sl_motion.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Строка ленты уведомлений (`docs/design/screens/notifications.md`).
///
/// Высота фиксированная: список виртуализируется по `itemExtent`, и «почти
/// одинаковые» строки такого списка не бывает — либо все 56, либо все 72.
///
/// Прочитанное от непрочитанного отличают **три** носителя сразу: точка
/// слева, фон строки и вес имени. Одного цвета мало — его не видно ни
/// дальтонику, ни на плохом мониторе.
class NotificationRow extends StatelessWidget {
  /// @nodoc
  const NotificationRow({
    required this.notification,
    required this.onOpen,
    required this.onOpenInNewTab,
    this.selected = false,
    this.highlighted = false,
    this.compact = false,
    this.timeInline = false,
    super.key,
  });

  /// @nodoc
  final NotificationDto notification;

  /// Открыть источник уведомления.
  final VoidCallback onOpen;

  /// `Ctrl/Cmd + клик` и средний клик: открыть в новой вкладке.
  final VoidCallback onOpenInNewTab;

  /// Строка под клавиатурным курсором.
  final bool selected;

  /// Уведомление только что приехало: фон `accentSurface` на 1200 мс.
  final bool highlighted;

  /// Раскладка телефона: три строки текста вместо двух.
  final bool compact;

  /// Время в конце первой строки, а не отдельной колонкой (`md`).
  final bool timeInline;

  /// Высота строки на десктопе и планшете.
  static const height = 56.0;

  /// Высота строки на телефоне: текст события в одну строку не помещается.
  static const compactHeight = 72.0;

  /// Ширина зоны точки непрочитанного.
  static const dotColumn = 16.0;

  /// Диаметр точки.
  static const dotSize = 6.0;

  /// Ширина колонки времени.
  static const timeColumn = 72.0;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final unread = notification.readAt == null;
    final time = SLDateFormat.timeOrDay(notification.createdAt);
    final context2 = NotificationLine.contextOf(notification);

    final background = highlighted
        ? colors.accentSurface
        : unread
        ? colors.surface
        : colors.surfaceSunken;

    final timeLabel = Text(
      time,
      textAlign: timeInline || compact ? TextAlign.left : TextAlign.right,
      style: text.label.copyWith(color: colors.textMuted),
    );

    final firstLine = Text.rich(
      TextSpan(
        children: [
          for (final span in NotificationLine.spansOf(notification))
            TextSpan(
              text: span.text,
              style: switch (span.kind) {
                NotificationSpanKind.actor => unread
                    ? text.bodySStrong.copyWith(color: colors.textPrimary)
                    : text.bodyS.copyWith(color: colors.textPrimary),
                NotificationSpanKind.plain => text.bodyS.copyWith(
                  color: colors.textSecondary,
                ),
                NotificationSpanKind.key => text.bodySStrong.copyWith(
                  color: colors.accent,
                ),
              },
            ),
        ],
      ),
      maxLines: compact ? 2 : 1,
      overflow: TextOverflow.ellipsis,
    );

    final secondLine = Text(
      context2,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: text.bodyS.copyWith(color: colors.textMuted),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: NotificationLine.semanticsOf(notification, time: time),
      child: ExcludeSemantics(
        child: SLFocusRing(
          focused: selected,
          inset: true,
          child: AnimatedContainer(
            duration: SLMotion.durationOf(context, SLMotion.base),
            height: compact ? compactHeight : height,
            color: selected ? colors.surfaceSelected : background,
            child: InkWell(
              onTap: onOpen,
              onLongPress: onOpenInNewTab,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SLSpacing.space2,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: dotColumn,
                      child: unread
                          ? Center(
                              child: Container(
                                width: dotSize,
                                height: dotSize,
                                decoration: BoxDecoration(
                                  color: colors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          // Место зарезервировано и у прочитанного: иначе
                          // текст всей ленты прыгал бы влево-вправо.
                          : const SizedBox.shrink(),
                    ),
                    _Avatar(notification: notification),
                    const SizedBox(width: SLSpacing.space2),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (timeInline)
                            Row(
                              children: [
                                Flexible(child: firstLine),
                                const SizedBox(width: SLSpacing.space2),
                                timeLabel,
                              ],
                            )
                          else
                            firstLine,
                          if (context2.isNotEmpty) secondLine,
                          if (compact) timeLabel,
                        ],
                      ),
                    ),
                    if (!timeInline && !compact) ...[
                      const SizedBox(width: SLSpacing.space2),
                      SizedBox(width: timeColumn, child: timeLabel),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Аватар инициатора. У системного события — иконка, а не случайный человек.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.notification});

  final NotificationDto notification;

  @override
  Widget build(BuildContext context) {
    final actor = notification.actor;

    if (actor == null) {
      return Icon(
        Icons.settings_rounded,
        size: SLAvatarSize.xs.diameter,
        color: SLColorScheme.of(context).iconMuted,
      );
    }

    return SLAvatar(
      userId: actor.id,
      fullName: actor.displayName,
      photoUrl: actor.avatarUrl,
      // Имя есть в тексте строки — аватар здесь украшение, а не сведения.
      decorative: true,
    );
  }
}
