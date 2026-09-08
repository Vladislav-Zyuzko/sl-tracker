import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_icon_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Модальное окно (`docs/design/components.md`, 13).
///
/// Шапка и подвал остаются на месте, тело прокручивается; максимальная
/// высота — 80 % высоты окна. На телефоне кнопки подвала занимают всю ширину
/// и стоят в столбик, основная — сверху.
///
/// Ловушку фокуса и возврат фокуса после закрытия даёт `showDialog`.
class SLDialog extends StatelessWidget {
  /// @nodoc
  const SLDialog({
    required this.title,
    required this.child,
    required this.actions,
    this.width = SLSizes.dialogSm,
    this.banner,
    this.onClose,
    super.key,
  });

  /// Заголовок. Он же — имя маршрута для скринридера.
  final String title;

  /// Тело окна.
  final Widget child;

  /// Кнопки подвала. Основная — последняя: она крайняя справа.
  final List<Widget> actions;

  /// Ширина: `sm` 400, `md` 560, `lg` 800.
  final double width;

  /// Баннер над подвалом — сюда попадает ошибка отправки.
  final Widget? banner;

  /// Закрытие крестиком. `null` — окно закрывается только кнопками:
  /// так поступают, пока идёт отправка.
  final VoidCallback? onClose;

  /// Высота шапки.
  static const headerHeight = 48.0;

  /// Высота подвала.
  static const footerHeight = 56.0;

  /// Какую долю высоты окна модалка не переходит.
  static const maxHeightFactor = 0.8;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final isPhone = SLBreakpoint.of(context).isPhone;
    final maxHeight = MediaQuery.sizeOf(context).height * maxHeightFactor;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: Dialog(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surface,
        shape: const RoundedRectangleBorder(borderRadius: SLRadii.mdAll),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: headerHeight,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: SLSpacing.space4,
                    right: SLSpacing.space2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.title.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      if (onClose != null)
                        SLIconButton(
                          icon: Icons.close_rounded,
                          tooltip: 'Закрыть',
                          size: SLButtonSize.sm,
                          onPressed: onClose,
                        ),
                    ],
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    SLSpacing.space4,
                    0,
                    SLSpacing.space4,
                    SLSpacing.space4,
                  ),
                  child: child,
                ),
              ),
              if (banner != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SLSpacing.space4,
                    0,
                    SLSpacing.space4,
                    SLSpacing.space3,
                  ),
                  child: banner,
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SLSpacing.space4,
                  0,
                  SLSpacing.space4,
                  SLSpacing.space4,
                ),
                child: isPhone
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final action in actions.reversed)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: SLSpacing.space2,
                              ),
                              child: action,
                            ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          for (final action in actions) ...[
                            const SizedBox(width: SLSpacing.space2),
                            action,
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
