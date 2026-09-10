import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Размер поля ввода (`docs/design/components.md`, 3.1).
enum SLFieldSize {
  /// Высота 32 на десктопе, 40 на телефоне.
  md,

  /// Высота 40 на десктопе, 44 на телефоне.
  lg,
}

/// Поле ввода SL Tracker.
///
/// Состояния (`components.md`, 3.2): обычное, наведение, фокус, заполненное,
/// отключённое, только для чтения, загрузка значения, ошибка.
///
/// Фокус показывается **утолщением собственной рамки** до 2 px, а не кольцом
/// снаружи: рамка поля и так окрашивается в `borderFocus`, и кольцо давало бы
/// второй синий контур с зазором — тот самый «инпут внутри инпута»
/// (`system.md`, 10.6.1). Утолщение уходит внутрь, `contentPadding` один
/// на все состояния, текст и каретка не сдвигаются.
///
/// «Только для чтения» — это не `disabled`: если у пользователя нет прав
/// на правку поля, оно рендерится обычным текстом `textPrimary` и остаётся
/// читаемым и выделяемым (`system.md`, 3.3).
///
/// Подпись видна всегда: плейсхолдер её не заменяет.
class SLTextField extends StatefulWidget {
  /// @nodoc
  const SLTextField({
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.leadingIcon,
    this.size = SLFieldSize.md,
    this.enabled = true,
    this.readOnly = false,
    this.isLoading = false,
    this.showClearButton = false,
    this.autofocus = false,
    this.focusNode,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  /// Многострочное поле: минимум 3 строки, максимум 12, дальше внутренняя
  /// прокрутка (`components.md`, 3.3).
  const SLTextField.multiline({
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.enabled = true,
    this.readOnly = false,
    this.isLoading = false,
    this.autofocus = false,
    this.focusNode,
    this.maxLength,
    this.onChanged,
    super.key,
  }) : leadingIcon = null,
       size = SLFieldSize.md,
       showClearButton = false,
       minLines = 3,
       maxLines = 12,
       onSubmitted = null;

  /// @nodoc
  final TextEditingController? controller;

  /// Подпись над полем. Видна всегда, в том числе когда поле заполнено.
  final String? label;

  /// Плейсхолдер. Не заменяет [label].
  final String? hint;

  /// Подсказка под полем.
  final String? helper;

  /// Текст ошибки. Непустое значение включает состояние ошибки.
  final String? errorText;

  /// Иконка слева — только если она осмысленна (поиск, календарь).
  final IconData? leadingIcon;

  /// @nodoc
  final SLFieldSize size;

  /// @nodoc
  final bool enabled;

  /// Поле только для чтения: границы нет, текст обычный, курсор `basic`.
  final bool readOnly;

  /// Значение ещё подгружается: вместо текста скелетон-полоска.
  final bool isLoading;

  /// Показывать кнопку очистки, когда поле непустое.
  final bool showClearButton;

  /// @nodoc
  final bool autofocus;

  /// @nodoc
  final FocusNode? focusNode;

  /// @nodoc
  final int? minLines;

  /// @nodoc
  final int? maxLines;

  /// @nodoc
  final int? maxLength;

  /// @nodoc
  final ValueChanged<String>? onChanged;

  /// @nodoc
  final ValueChanged<String>? onSubmitted;

  @override
  State<SLTextField> createState() => _SLTextFieldState();
}

class _SLTextFieldState extends State<SLTextField> {
  late TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late FocusNode _focusNode = widget.focusNode ?? FocusNode();
  var _ownsController = false;
  var _ownsFocusNode = false;
  var _focused = false;
  var _hovered = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _ownsFocusNode = widget.focusNode == null;
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(SLTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onTextChanged);
      if (_ownsController) _controller.dispose();
      _ownsController = widget.controller == null;
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_onTextChanged);
    }

    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChanged);
      if (_ownsFocusNode) _focusNode.dispose();
      _ownsFocusNode = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() => _focused = _focusNode.hasFocus);

  void _onTextChanged() {
    if (widget.showClearButton) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final density = SLDensity.ofContext(context);
    final height = widget.size == SLFieldSize.md
        ? density.fieldMd
        : density.fieldLg;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final isMultiline = (widget.maxLines ?? 1) > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: text.label.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: SLSpacing.space1),
        ],
        // Кольца фокуса у поля нет намеренно: его рамка сама окрашивается
        // в `borderFocus`, и кольцо давало бы два синих контура с зазором —
        // «инпут внутри инпута» (`system.md`, 10.6.1). Фокус показывает
        // утолщение рамки до 2 px.
        MouseRegion(
          cursor: widget.enabled && !widget.readOnly
              ? SystemMouseCursors.text
              : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: isMultiline ? 72 : height),
            child: _buildField(
              colors: colors,
              text: text,
              hasError: hasError,
              isMultiline: isMultiline,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: SLSpacing.space1),
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: SLIconSizes.icon12,
                  color: colors.danger,
                ),
                const SizedBox(width: SLSpacing.space1),
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: text.label.copyWith(color: colors.danger),
                  ),
                ),
              ],
            ),
          ),
        ] else if (widget.helper != null) ...[
          const SizedBox(height: SLSpacing.space1),
          Text(
            widget.helper!,
            style: text.label.copyWith(color: colors.textMuted),
          ),
        ],
      ],
    );
  }

  Widget _buildField({
    required SLColorScheme colors,
    required SLTextScheme text,
    required bool hasError,
    required bool isMultiline,
  }) {
    // Значение подгружается: вместо текста скелетон-полоска внутри поля,
    // габариты не меняются, поле не «прыгает» при появлении данных.
    if (widget.isLoading) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: SLRadii.smAll,
          border: Border.all(color: colors.borderStrong),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: SLSpacing.space2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.6,
              child: SLSkeletonLine(height: 12),
            ),
          ),
        ),
      );
    }

    // Нет прав на правку: данные читаемы и выделяемы, границы нет.
    if (widget.readOnly) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SelectionArea(
            child: Text(
              _controller.text,
              style: text.bodyS.copyWith(color: colors.textPrimary),
              maxLines: widget.maxLines,
            ),
          ),
        ),
      );
    }

    // Цвет означает состояние, толщина — фокус (`system.md`, 10.6.1).
    // Поле с ошибкой в фокусе остаётся красным и просто утолщается: ошибка
    // важнее того, где сейчас каретка.
    final borderColor = hasError
        ? colors.borderDanger
        : _focused
        ? colors.borderFocus
        : _hovered
        ? colors.textMuted
        : colors.borderStrong;
    final borderWidth = _focused ? SLBorders.controlFocus : SLBorders.hairline;

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: text.bodyS.copyWith(
        color: widget.enabled ? colors.textPrimary : colors.textDisabled,
      ),
      cursorColor: colors.accent,
      decoration: InputDecoration(
        hintText: widget.hint,
        counterText: '',
        filled: true,
        fillColor: widget.enabled ? colors.surface : colors.surfaceDisabled,
        contentPadding: EdgeInsets.symmetric(
          horizontal: SLSpacing.space2,
          vertical: isMultiline ? SLSpacing.space2 : SLSpacing.space1,
        ),
        prefixIcon: widget.leadingIcon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(
                  left: SLSpacing.space2,
                  right: SLSpacing.space2,
                ),
                child: Icon(
                  widget.leadingIcon,
                  size: SLIconSizes.icon16,
                  color: colors.iconMuted,
                ),
              ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: _buildClearButton(colors),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        // Границу считаем сами: InputDecorationTheme не различает наведение.
        // Все пять границ заданы явно, чтобы состояние не «протекало»
        // из темы, а `contentPadding` один на все состояния — иначе текст
        // подпрыгивал бы при получении фокуса.
        border: _border(borderColor, borderWidth),
        enabledBorder: _border(borderColor, borderWidth),
        focusedBorder: _border(borderColor, borderWidth),
        errorBorder: _border(colors.borderDanger, SLBorders.hairline),
        focusedErrorBorder: _border(
          colors.borderDanger,
          SLBorders.controlFocus,
        ),
        disabledBorder: _border(colors.border, SLBorders.hairline),
      ),
    );
  }

  Widget? _buildClearButton(SLColorScheme colors) {
    if (!widget.showClearButton || _controller.text.isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.only(right: SLSpacing.space1),
      child: Semantics(
        button: true,
        label: 'Очистить поле',
        child: InkWell(
          borderRadius: SLRadii.smAll,
          onTap: () {
            _controller.clear();
            widget.onChanged?.call('');
          },
          child: SizedBox.square(
            dimension: 24,
            child: Icon(
              Icons.close_rounded,
              size: SLIconSizes.icon16,
              color: colors.iconDefault,
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
    borderRadius: SLRadii.smAll,
    borderSide: BorderSide(color: color, width: width),
  );
}
