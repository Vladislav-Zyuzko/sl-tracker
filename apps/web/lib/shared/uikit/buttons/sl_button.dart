import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Вариант кнопки (`docs/design/components.md`, 2.1).
///
/// Правило одного действия: на экране одна основная кнопка. Если кажется,
/// что нужны две, одна из них вторичная.
enum SLButtonVariant {
  /// Заливка `accent`. Одно главное действие на экране или в модалке.
  primary,

  /// Фон `surface` и контур `borderControl`. Частые второстепенные действия.
  secondary,

  /// Прозрачная, текст `accent`. Третьестепенное действие.
  ghost,

  /// Заливка `danger`. Удаление, необратимое действие.
  danger,

  /// Прозрачная с контуром `danger`. Удаление в плотном контексте.
  dangerGhost,
}

/// Размер кнопки (`docs/design/components.md`, 2.2).
enum SLButtonSize {
  /// Высота 24 на десктопе, 32 на телефоне.
  sm,

  /// Высота 32 на десктопе, 40 на телефоне. По умолчанию.
  md,

  /// Высота 40 на десктопе, 44 на телефоне.
  lg,
}

/// Кнопка SL Tracker.
///
/// Построена на [FilledButton] с полностью переопределённым [ButtonStyle]:
/// дефолты Material 3 для плотного трекера слишком просторны. Ripple выключен,
/// наведение и нажатие — мгновенная смена цвета фона.
///
/// Состояния (`components.md`, 2.3): обычное, наведение, фокус, нажатое,
/// отключённое, загрузка. Состояния ошибки у кнопки нет — ошибка живёт
/// в тосте либо в баннере рядом.
///
/// Во время загрузки кнопка не нажимается, но **не** выглядит отключённой:
/// она остаётся цветной, чтобы не мигать, а ширина фиксируется по исходному
/// тексту, чтобы кнопка не схлопывалась.
class SLButton extends StatefulWidget {
  /// @nodoc
  const SLButton({
    required this.label,
    required this.onPressed,
    this.variant = SLButtonVariant.primary,
    this.size = SLButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// Текст кнопки. Называется глаголом действия: «Создать задачу», а не «ОК».
  final String label;

  /// Обработчик нажатия. `null` — кнопка отключена и выведена из порядка
  /// табуляции.
  final VoidCallback? onPressed;

  /// Вариант оформления.
  final SLButtonVariant variant;

  /// Размер.
  final SLButtonSize size;

  /// Иконка слева от текста. Декоративна: смысл несёт [label].
  final IconData? icon;

  /// Состояние загрузки: на месте текста спиннер, нажатия игнорируются.
  final bool isLoading;

  /// Растянуть кнопку по ширине родителя. На телефоне кнопки в модалке
  /// занимают всю ширину.
  final bool expand;

  /// @nodoc
  final FocusNode? focusNode;

  /// @nodoc
  final bool autofocus;

  @override
  State<SLButton> createState() => _SLButtonState();
}

class _SLButtonState extends State<SLButton> {
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
    final text = SLTextScheme.of(context);
    final density = SLDensity.ofContext(context);
    final height = switch (widget.size) {
      SLButtonSize.sm => density.buttonSm,
      SLButtonSize.md => density.buttonMd,
      SLButtonSize.lg => density.buttonLg,
    };

    final button = FilledButton(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      statesController: _statesController,
      // Во время загрузки нажатие игнорируется, но вид остаётся обычным.
      onPressed: widget.isLoading ? () {} : widget.onPressed,
      style: _styleOf(colors: colors, text: text, height: height),
      child: _SLButtonContent(
        label: widget.label,
        icon: widget.icon,
        size: widget.size,
        isLoading: widget.isLoading,
      ),
    );

    return SLFocusRing(
      focused: _focused,
      child: widget.expand
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }

  ButtonStyle _styleOf({
    required SLColorScheme colors,
    required SLTextScheme text,
    required double height,
  }) {
    final horizontalPadding = switch (widget.size) {
      SLButtonSize.sm => SLSpacing.space2,
      SLButtonSize.md => SLSpacing.space3,
      SLButtonSize.lg => SLSpacing.space4,
    };
    final labelStyle = widget.size == SLButtonSize.sm
        ? text.bodyS
        : text.bodySStrong;

    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => _backgroundOf(colors, states),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => _foregroundOf(colors, states),
      ),
      iconColor: WidgetStateProperty.resolveWith(
        (states) => _foregroundOf(colors, states),
      ),
      side: WidgetStateProperty.resolveWith(
        (states) => _sideOf(colors, states),
      ),
      textStyle: WidgetStatePropertyAll(labelStyle),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: horizontalPadding),
      ),
      // Минимальная ширина 64, чтобы «ОК» не превращался в квадратик.
      minimumSize: WidgetStatePropertyAll(Size(64, height)),
      fixedSize: WidgetStatePropertyAll(Size.fromHeight(height)),
      maximumSize: const WidgetStatePropertyAll(Size.infinite),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: SLRadii.smAll),
      ),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Color(0x00000000)),
      surfaceTintColor: const WidgetStatePropertyAll(Color(0x00000000)),
      overlayColor: const WidgetStatePropertyAll(Color(0x00000000)),
      splashFactory: NoSplash.splashFactory,
      // Плотность здесь намеренно стандартная, хотя глобально в теме она
      // компактная: все размеры кнопки заданы явно, а `compact` молча
      // вычитает 8 px из минимальной ширины (64 превращается в 56) и урезает
      // зону нажатия на тач-платформах ниже требуемых 44.
      visualDensity: VisualDensity.standard,
      tapTargetSize: _tapTargetSize,
      mouseCursor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
      ),
      animationDuration: Duration.zero,
      alignment: Alignment.center,
    );
  }

  /// Тач-платформа: зона нажатия расширяется, визуальный размер при этом
  /// не растёт (`system.md`, 10.2).
  static bool get _isTouchPlatform => switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.android => true,
    _ => false,
  };

  MaterialTapTargetSize get _tapTargetSize => _isTouchPlatform
      ? MaterialTapTargetSize.padded
      : MaterialTapTargetSize.shrinkWrap;

  Color _backgroundOf(SLColorScheme colors, Set<WidgetState> states) {
    final disabled = states.contains(WidgetState.disabled);
    final pressed = states.contains(WidgetState.pressed);
    final hovered = states.contains(WidgetState.hovered);

    // Во время загрузки кнопка остаётся цветной: вид disabled заставил бы её
    // мигать на быстрой сети.
    if (disabled && !widget.isLoading) {
      return widget.variant == SLButtonVariant.ghost ||
              widget.variant == SLButtonVariant.dangerGhost
          ? const Color(0x00000000)
          : colors.surfaceDisabled;
    }

    return switch (widget.variant) {
      SLButtonVariant.primary =>
        pressed
            ? colors.accentPressed
            : hovered
            ? colors.accentHover
            : colors.accent,
      SLButtonVariant.secondary =>
        pressed
            ? colors.surfacePressed
            : hovered
            ? colors.surfaceHover
            : colors.surface,
      SLButtonVariant.ghost || SLButtonVariant.dangerGhost =>
        pressed
            ? colors.surfacePressed
            : hovered
            ? colors.surfaceHover
            : const Color(0x00000000),
      SLButtonVariant.danger =>
        pressed || hovered ? colors.dangerHover : colors.danger,
    };
  }

  Color _foregroundOf(SLColorScheme colors, Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled) && !widget.isLoading) {
      return colors.textDisabled;
    }

    return switch (widget.variant) {
      SLButtonVariant.primary || SLButtonVariant.danger => colors.textOnAccent,
      SLButtonVariant.secondary => colors.textPrimary,
      SLButtonVariant.ghost => colors.accent,
      SLButtonVariant.dangerGhost => colors.danger,
    };
  }

  BorderSide? _sideOf(SLColorScheme colors, Set<WidgetState> states) {
    final disabled = states.contains(WidgetState.disabled) && !widget.isLoading;

    return switch (widget.variant) {
      SLButtonVariant.secondary => BorderSide(
        color: disabled ? colors.border : colors.borderStrong,
        width: SLBorders.hairline,
      ),
      SLButtonVariant.dangerGhost => BorderSide(
        color: disabled ? colors.border : colors.danger,
        width: SLBorders.hairline,
      ),
      _ => BorderSide.none,
    };
  }
}

/// Содержимое кнопки: иконка, текст и спиннер загрузки поверх них.
class _SLButtonContent extends StatelessWidget {
  const _SLButtonContent({
    required this.label,
    required this.icon,
    required this.size,
    required this.isLoading,
  });

  final String label;
  final IconData? icon;
  final SLButtonSize size;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final iconSize = size == SLButtonSize.lg
        ? SLIconSizes.icon20
        : SLIconSizes.icon16;
    final gap = size == SLButtonSize.lg ? SLSpacing.space2 : SLSpacing.space1;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: iconSize), SizedBox(width: gap)],
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    if (!isLoading) return content;

    // Содержимое остаётся на месте и держит ширину, спиннер рисуется поверх.
    return Semantics(
      label: '$label, выполняется',
      excludeSemantics: true,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 0, child: content),
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              // Спиннер наследует цвет текста кнопки: на primary он белый,
              // на secondary — цвета текста.
              color: IconTheme.of(context).color,
            ),
          ),
        ],
      ),
    );
  }
}
