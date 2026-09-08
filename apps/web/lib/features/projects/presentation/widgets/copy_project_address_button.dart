import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/core/platform/browser_navigator.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// «Скопировать адрес проекта» — адресная половина D-04.
///
/// Половина, которую **нельзя перепутать** со ссылкой-приглашением: смешение
/// означает утечку доступа. Разведение сделано по семи признакам сразу, и эта
/// кнопка отвечает за свои:
///
/// - живёт в шапке проекта, видна всем участникам, включая читателя;
/// - выглядит нейтрально: текстовая кнопка `textSecondary`, без заливки;
/// - иконка `link_rounded` — звено цепи, а не человек со знаком «плюс»;
/// - глагол «Скопировать адрес проекта»;
/// - одно нажатие, без выбора роли и срока;
/// - рядом написано, что ссылка доступа не даёт;
/// - тост обычный, без предупреждения.
///
/// Слово «приглашение» рядом с ней не появляется никогда.
///
/// Цвет намеренно расходится с вариантом `ghost` из `components.md` (там
/// текст `accent`): акцентный цвет сделал бы адрес похожим на действие,
/// раздающее доступ. Расхождение зафиксировано в D-04 спеки экрана.
class CopyProjectAddressButton extends ConsumerStatefulWidget {
  /// @nodoc
  const CopyProjectAddressButton({
    required this.slug,
    this.compact = false,
    super.key,
  });

  /// Действующее короткое имя проекта.
  final String slug;

  /// Узкая раскладка: остаётся иконка с подсказкой.
  final bool compact;

  /// Доступное имя. Пояснение — часть имени, а не только визуальная подпись:
  /// для незрячего пользователя текст рядом с кнопкой бесполезен.
  static const accessibleName =
      'Скопировать адрес проекта. Ссылка не даёт доступа';

  /// Что написано рядом с кнопкой.
  static const explanation =
      'Ссылка не даёт доступа: откроется только у участников проекта';

  /// Текст тоста после копирования.
  static const toastMessage = 'Адрес скопирован';

  @override
  ConsumerState<CopyProjectAddressButton> createState() =>
      _CopyProjectAddressButtonState();
}

class _CopyProjectAddressButtonState
    extends ConsumerState<CopyProjectAddressButton> {
  var _hovered = false;
  var _focused = false;

  /// Полный адрес проекта.
  ///
  /// Origin нужен именно полный: путь `/projects/sl` из чата не откроется.
  /// Если origin неизвестен (не браузер), остаётся путь — это лучше пустой
  /// строки в буфере обмена.
  String get _address {
    final origin = ref.read(browserNavigatorProvider).origin;

    return '$origin${AppRoutes.projectPath(widget.slug)}';
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _address));
    if (!mounted) return;

    // Тост обычный: адрес проекта ничего не раздаёт, пугать нечем.
    ref
        .read(toastControllerProvider.notifier)
        .success(CopyProjectAddressButton.toastMessage);
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final density = SLDensity.ofContext(context);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.link_rounded,
          size: SLIconSizes.icon16,
          color: colors.textSecondary,
        ),
        if (!widget.compact) ...[
          const SizedBox(width: SLSpacing.space1),
          Text(
            'Скопировать адрес',
            style: text.bodyS.copyWith(color: colors.textSecondary),
          ),
        ],
      ],
    );

    return Semantics(
      container: true,
      button: true,
      label: CopyProjectAddressButton.accessibleName,
      excludeSemantics: true,
      child: Tooltip(
        message: widget.compact
            ? CopyProjectAddressButton.accessibleName
            : CopyProjectAddressButton.explanation,
        child: SLFocusRing(
          focused: _focused,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: Focus(
              onFocusChange: (focused) => setState(() => _focused = focused),
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                final key = event.logicalKey;
                if (key != LogicalKeyboardKey.enter &&
                    key != LogicalKeyboardKey.numpadEnter &&
                    key != LogicalKeyboardKey.space) {
                  return KeyEventResult.ignored;
                }
                unawaited(_copy());

                return KeyEventResult.handled;
              },
              child: GestureDetector(
                onTap: _copy,
                child: Container(
                  height: density.buttonSm,
                  padding: const EdgeInsets.symmetric(
                    horizontal: SLSpacing.space2,
                  ),
                  decoration: BoxDecoration(
                    color: _hovered ? colors.surfaceHover : null,
                    borderRadius: SLRadii.smAll,
                  ),
                  child: Center(child: content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
