import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_icon_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Ошибка на весь экран (`docs/design/components.md`, 17.1).
///
/// Композиция та же, что у пустого состояния, но иконка `error_outline_rounded`
/// цветом `danger`, а кнопка — вариант `secondary`.
///
/// Технические подробности прячутся под раскрывающийся блок: пользователю
/// они не нужны, а в баг-репорте бесценны.
class SLErrorState extends StatefulWidget {
  /// @nodoc
  const SLErrorState({
    required this.title,
    required this.description,
    this.actionLabel = 'Повторить',
    this.onAction,
    this.details,
    super.key,
  });

  /// Что случилось, человеческими словами.
  final String title;

  /// Что делать дальше.
  final String description;

  /// Подпись кнопки. `null` — кнопки нет.
  final String? actionLabel;

  /// @nodoc
  final VoidCallback? onAction;

  /// Технические подробности: код ответа, идентификатор запроса.
  final String? details;

  @override
  State<SLErrorState> createState() => _SLErrorStateState();
}

class _SLErrorStateState extends State<SLErrorState> {
  var _detailsExpanded = false;

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
              Icon(
                Icons.error_outline_rounded,
                size: SLIconSizes.icon48,
                color: colors.danger,
              ),
              const SizedBox(height: SLSpacing.space4),
              Semantics(
                header: true,
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: text.title.copyWith(color: colors.textPrimary),
                ),
              ),
              const SizedBox(height: SLSpacing.space2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  widget.description,
                  textAlign: TextAlign.center,
                  style: text.body.copyWith(color: colors.textMuted),
                ),
              ),
              if (widget.actionLabel != null) ...[
                const SizedBox(height: SLSpacing.space6),
                SLButton(
                  label: widget.actionLabel!,
                  variant: SLButtonVariant.secondary,
                  onPressed: widget.onAction,
                ),
              ],
              if (widget.details != null) ...[
                const SizedBox(height: SLSpacing.space4),
                _buildDetails(colors, text),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(SLColorScheme colors, SLTextScheme text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SLButton(
          label: _detailsExpanded ? 'Скрыть подробности' : 'Подробности',
          variant: SLButtonVariant.ghost,
          size: SLButtonSize.sm,
          onPressed: () => setState(() => _detailsExpanded = !_detailsExpanded),
        ),
        if (_detailsExpanded) ...[
          const SizedBox(height: SLSpacing.space2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: SelectionArea(
                    child: Text(
                      widget.details!,
                      style: text.mono.copyWith(
                        color: colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: SLSpacing.space2),
                SLButton(
                  label: 'Скопировать',
                  variant: SLButtonVariant.ghost,
                  size: SLButtonSize.sm,
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: widget.details!)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Вариант оформления баннера (`docs/design/components.md`, 17.2).
enum SLBannerVariant {
  /// Ошибка.
  danger,

  /// Предупреждение.
  warning,

  /// Нейтральное сообщение.
  info,

  /// Подтверждение.
  success,
}

/// Баннер внутри формы или панели.
///
/// Живая область для скринридера: при появлении фокус на него не переводится,
/// но при отправке формы фокус ставится на первое поле с ошибкой.
///
/// Технический код ошибки пользователю не показывается: он прячется
/// в раскрывающийся блок «Подробности» — там он бесполезен читателю
/// и бесценен в баг-репорте (`screens/login.md`).
class SLBanner extends StatefulWidget {
  /// @nodoc
  const SLBanner({
    required this.title,
    this.description,
    this.variant = SLBannerVariant.danger,
    this.details,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    super.key,
  });

  /// Заголовок сообщения.
  final String title;

  /// Пояснение: что сделать.
  final String? description;

  /// @nodoc
  final SLBannerVariant variant;

  /// Технические подробности: код ошибки, идентификатор запроса.
  /// `null` — блока «Подробности» нет.
  final String? details;

  /// Подпись действия внутри баннера: «Обновить», «Настроить».
  /// `null` — действия нет.
  ///
  /// Действие живёт **в** баннере, а не рядом с ним: баннер объясняет
  /// проблему, и кнопка, решающая её, должна быть на расстоянии взгляда.
  final String? actionLabel;

  /// @nodoc
  final VoidCallback? onAction;

  /// Обработчик закрытия. `null` — баннер не закрывается.
  final VoidCallback? onDismiss;

  /// Ширина цветной полосы слева.
  static const stripeWidth = 3.0;

  @override
  State<SLBanner> createState() => _SLBannerState();
}

class _SLBannerState extends State<SLBanner> {
  var _detailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final variant = widget.variant;
    final title = widget.title;
    final description = widget.description;
    final details = widget.details;
    final actionLabel = widget.actionLabel;
    final onDismiss = widget.onDismiss;

    final (background, border, accent, icon) = switch (variant) {
      SLBannerVariant.danger => (
        colors.dangerSurface,
        colors.dangerBorder,
        colors.danger,
        Icons.error_outline_rounded,
      ),
      SLBannerVariant.warning => (
        colors.warningSurface,
        colors.warningAccent,
        colors.warning,
        Icons.warning_amber_rounded,
      ),
      SLBannerVariant.info => (
        colors.accentSurface,
        colors.accentBorder,
        colors.info,
        Icons.info_outline_rounded,
      ),
      SLBannerVariant.success => (
        colors.successSurface,
        colors.successBorder,
        colors.success,
        Icons.check_circle_outline_rounded,
      ),
    };

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: SLRadii.smAll,
          border: Border.all(color: border, width: SLBorders.hairline),
        ),
        // Полоса слева тянется на всю высоту баннера, а высота эта заранее
        // не известна: баннер живёт и в модалке, и в прокручиваемой колонке,
        // где вертикальные ограничения бесконечны.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: SLBanner.stripeWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(SLRadii.sm),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(SLSpacing.space3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: SLIconSizes.icon16, color: accent),
                      const SizedBox(width: SLSpacing.space2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: text.bodyS.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (description != null) ...[
                              const SizedBox(height: SLSpacing.space1),
                              Text(
                                description,
                                style: text.bodyS.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                            if (actionLabel != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: SLButton(
                                  label: actionLabel,
                                  variant: SLButtonVariant.ghost,
                                  size: SLButtonSize.sm,
                                  onPressed: widget.onAction,
                                ),
                              ),
                            if (details != null)
                              _BannerDetails(
                                details: details,
                                expanded: _detailsExpanded,
                                onToggle: () => setState(
                                  () => _detailsExpanded = !_detailsExpanded,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (onDismiss != null) ...[
                        const SizedBox(width: SLSpacing.space2),
                        SLIconButton(
                          icon: Icons.close_rounded,
                          tooltip: 'Закрыть сообщение',
                          size: SLButtonSize.sm,
                          onPressed: onDismiss,
                        ),
                      ],
                    ],
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

/// Раскрывающийся блок с техническими подробностями внутри баннера.
class _BannerDetails extends StatelessWidget {
  const _BannerDetails({
    required this.details,
    required this.expanded,
    required this.onToggle,
  });

  final String details;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SLButton(
            label: expanded ? 'Скрыть подробности' : 'Подробности',
            variant: SLButtonVariant.ghost,
            size: SLButtonSize.sm,
            onPressed: onToggle,
          ),
        ),
        if (expanded)
          SelectionArea(
            child: Text(
              details,
              style: text.mono.copyWith(color: colors.textMuted, fontSize: 11),
            ),
          ),
      ],
    );
  }
}
