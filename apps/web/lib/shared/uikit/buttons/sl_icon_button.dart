import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';

/// Квадратная кнопка только с иконкой (`docs/design/components.md`, 2.2).
///
/// [tooltip] обязателен и не имеет значения по умолчанию: иконка без текста
/// без подсказки недоступна ни мышью, ни скринридером (`components.md`, 2.4).
/// Он же становится доступным именем.
class SLIconButton extends StatefulWidget {
  /// @nodoc
  const SLIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = SLButtonVariant.ghost,
    this.size = SLButtonSize.md,
    this.isSelected = false,
    this.focusNode,
    super.key,
  });

  /// Иконка. Набор — встроенные Material Icons, вариант Rounded.
  final IconData icon;

  /// Подсказка и доступное имя. Обязательна.
  final String tooltip;

  /// Обработчик нажатия. `null` — кнопка отключена.
  final VoidCallback? onPressed;

  /// Вариант оформления. По умолчанию прозрачная.
  final SLButtonVariant variant;

  /// Размер: сторона квадрата равна высоте кнопки того же размера.
  final SLButtonSize size;

  /// Кнопка-переключатель во включённом состоянии: фон `surfaceSelected`.
  final bool isSelected;

  /// @nodoc
  final FocusNode? focusNode;

  @override
  State<SLIconButton> createState() => _SLIconButtonState();
}

class _SLIconButtonState extends State<SLIconButton> {
  final _statesController = WidgetStatesController();
  var _focused = false;

  @override
  void initState() {
    super.initState();
    _statesController.addListener(_onStatesChanged);
  }

  @override
  void dispose() {
    _statesController
      ..removeListener(_onStatesChanged)
      ..dispose();
    super.dispose();
  }

  void _onStatesChanged() {
    final focused = _statesController.value.contains(WidgetState.focused);
    if (focused != _focused) {
      setState(() => _focused = focused);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final density = SLDensity.ofContext(context);
    final side = switch (widget.size) {
      SLButtonSize.sm => density.buttonSm,
      SLButtonSize.md => density.buttonMd,
      SLButtonSize.lg => density.buttonLg,
    };
    final iconSize = widget.size == SLButtonSize.lg
        ? SLIconSizes.icon20
        : SLIconSizes.icon16;

    return SLFocusRing(
      focused: _focused,
      child: SizedBox.square(
        dimension: side,
        child: IconButton(
          focusNode: widget.focusNode,
          statesController: _statesController,
          onPressed: widget.onPressed,
          tooltip: widget.tooltip,
          icon: Icon(widget.icon, size: iconSize),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tight(Size.square(side)),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => _backgroundOf(colors, states),
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => _foregroundOf(colors, states),
            ),
            shape: const WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: SLRadii.smAll),
            ),
            overlayColor: const WidgetStatePropertyAll(Color(0x00000000)),
            splashFactory: NoSplash.splashFactory,
            // Стандартная плотность: сторона квадрата задана явно через
            // constraints, а compact вычел бы из неё лишние пиксели.
            visualDensity: VisualDensity.standard,
            tapTargetSize: switch (defaultTargetPlatform) {
              TargetPlatform.iOS ||
              TargetPlatform.android => MaterialTapTargetSize.padded,
              _ => MaterialTapTargetSize.shrinkWrap,
            },
            mouseCursor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click,
            ),
            animationDuration: Duration.zero,
          ),
        ),
      ),
    );
  }

  Color _backgroundOf(SLColorScheme colors, Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return widget.variant == SLButtonVariant.ghost
          ? const Color(0x00000000)
          : colors.surfaceDisabled;
    }

    final pressed = states.contains(WidgetState.pressed);
    final hovered = states.contains(WidgetState.hovered);

    if (widget.isSelected) {
      return hovered ? colors.surfaceSelectedHover : colors.surfaceSelected;
    }

    return switch (widget.variant) {
      SLButtonVariant.primary =>
        pressed
            ? colors.accentPressed
            : hovered
            ? colors.accentHover
            : colors.accent,
      SLButtonVariant.danger =>
        pressed || hovered ? colors.dangerHover : colors.danger,
      SLButtonVariant.secondary ||
      SLButtonVariant.ghost ||
      SLButtonVariant.dangerGhost =>
        pressed
            ? colors.surfacePressed
            : hovered
            ? colors.surfaceHover
            : const Color(0x00000000),
    };
  }

  Color _foregroundOf(SLColorScheme colors, Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return colors.textDisabled;
    if (widget.isSelected) return colors.accent;

    return switch (widget.variant) {
      SLButtonVariant.primary || SLButtonVariant.danger => colors.textOnAccent,
      SLButtonVariant.secondary || SLButtonVariant.ghost => colors.iconDefault,
      SLButtonVariant.dangerGhost => colors.danger,
    };
  }
}
