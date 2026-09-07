import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Пустое состояние (`docs/design/components.md`, 16).
///
/// Пустых состояний в трекере несколько, и они разные по тексту и действию.
/// Подменять их одним универсальным «Нет данных» нельзя — поэтому [title],
/// [description] и действие обязательны к осмысленному заполнению на каждом
/// экране, а не имеют значений по умолчанию.
///
/// Иллюстраций не используем: иконка из набора, никаких персонажей.
/// Это рабочий инструмент, а не онбординг.
class SLEmptyState extends StatelessWidget {
  /// @nodoc
  const SLEmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.actionVariant = SLButtonVariant.primary,
    super.key,
  });

  /// Иконка размером `icon48`, цвет `iconMuted`.
  final IconData icon;

  /// Заголовок. Объявляется скринридеру как заголовок.
  final String title;

  /// Пояснение: что это значит и что делать.
  final String description;

  /// Подпись кнопки. `null` — кнопки нет (например, нет прав на действие).
  final String? actionLabel;

  /// @nodoc
  final VoidCallback? onAction;

  /// @nodoc
  final SLButtonVariant actionVariant;

  /// Максимальная ширина пояснения.
  static const descriptionWidth = 360.0;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Semantics(
      container: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: SLSpacing.space8,
            horizontal: SLSpacing.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: SLIconSizes.icon48, color: colors.iconMuted),
              const SizedBox(height: SLSpacing.space4),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: text.title.copyWith(color: colors.textPrimary),
                ),
              ),
              const SizedBox(height: SLSpacing.space2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: descriptionWidth),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: text.body.copyWith(color: colors.textMuted),
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: SLSpacing.space6),
                SLButton(
                  label: actionLabel!,
                  variant: actionVariant,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
