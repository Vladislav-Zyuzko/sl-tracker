import 'package:flutter/material.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Плашка источника записи в списке доступа (ADR-0006).
///
/// Источников **три**, а не два: `config` — из конфигурации инстанса,
/// `manual` — добавлена владельцем вручную через этот экран, `invitation` —
/// появилась сама при приёме приглашения. Спека дизайна описывает только
/// `config` и `invitation`; пара для `manual` подобрана здесь и вынесена
/// на подтверждение дизайнеру (см. отчёт).
///
/// Цвет — не единственный носитель смысла: плашка всегда с текстом и иконкой.
class AccessSourceBadge extends StatelessWidget {
  /// @nodoc
  const AccessSourceBadge({required this.source, super.key});

  /// @nodoc
  final AccessEntryDtoSource source;

  /// Высота плашки. Равна высоте плашки статуса в строке списка.
  static const height = 20.0;

  /// Ширина колонки источника.
  static const columnWidth = 160.0;

  /// Подпись источника. Отдельно от вёрстки — её же читает скринридер
  /// в описании строки.
  static String labelOf(AccessEntryDtoSource source) => switch (source) {
    AccessEntryDtoSource.config => 'Конфигурация',
    AccessEntryDtoSource.manual => 'Вручную',
    AccessEntryDtoSource.invitation => 'Приглашение',
    // Бэкенд завёл новый источник, а клиент ещё не знает какой. Показываем
    // честное «неизвестно» вместо пустого места и не падаем.
    AccessEntryDtoSource.$unknown => 'Неизвестно',
  };

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    final (background, foreground, icon) = switch (source) {
      AccessEntryDtoSource.config => (
        colors.surfaceSunken,
        colors.textSecondary,
        Icons.settings_rounded,
      ),
      AccessEntryDtoSource.manual => (
        colors.successSurface,
        colors.textSecondary,
        Icons.add_circle_outline_rounded,
      ),
      AccessEntryDtoSource.invitation => (
        colors.accentSurface,
        colors.accentPressed,
        Icons.person_add_alt_1_rounded,
      ),
      AccessEntryDtoSource.$unknown => (
        colors.surfaceSunken,
        colors.textSecondary,
        Icons.help_outline_rounded,
      ),
    };

    return Semantics(
      label: 'Источник: ${labelOf(source).toLowerCase()}',
      excludeSemantics: true,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: SLRadii.smAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: SLIconSizes.icon12, color: foreground),
            const SizedBox(width: SLSpacing.space1),
            // Подпись сжимается, а не выпирает за колонку: длина названия
            // источника зависит от языка и от того, что заведёт бэкенд.
            Flexible(
              child: Text(
                labelOf(source),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: text.caption.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
