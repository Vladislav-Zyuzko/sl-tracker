import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Поле поиска (`docs/design/components.md`, 4).
///
/// Отдельный компонент, а не «поле ввода с иконкой»: у него своё поведение —
/// дебаунс, подсказка хоткея, обработка `Esc`.
///
/// Плейсхолдер обязан называть область поиска. В оболочке приложения поиск
/// идёт только по моим активным задачам, и обрезанный до «Поиск» плейсхолдер
/// создаёт ощущение поломки (`screens/app-shell.md`).
class SLSearchField extends StatefulWidget {
  /// @nodoc
  const SLSearchField({
    required this.hint,
    required this.onQueryChanged,
    this.controller,
    this.focusNode,
    this.showHotkeyHint = true,
    this.hotkeyHint = '/',
    this.debounce = const Duration(milliseconds: 250),
    this.minQueryLength = 2,
    this.isLoading = false,
    this.onSubmitted,
    this.onArrowDown,
    super.key,
  });

  /// Плейсхолдер. Называет область поиска целиком.
  final String hint;

  /// Вызывается после дебаунса. Пустая строка означает «запрос сброшен».
  final ValueChanged<String> onQueryChanged;

  /// @nodoc
  final TextEditingController? controller;

  /// @nodoc
  final FocusNode? focusNode;

  /// Показывать бейдж с подсказкой хоткея, пока поле не в фокусе.
  final bool showHotkeyHint;

  /// Текст бейджа хоткея.
  final String hotkeyHint;

  /// Дебаунс ввода. По умолчанию 250 мс: US-82 требует не более 300.
  final Duration debounce;

  /// Минимальная длина запроса. Короче — запрос не отправляется, но пустая
  /// строка проходит всегда: это сброс.
  final int minQueryLength;

  /// Идёт ли поиск: справа в поле появляется спиннер.
  final bool isLoading;

  /// `Enter` в поле.
  final VoidCallback? onSubmitted;

  /// `Стрелка вниз` в поле — уход в список результатов.
  final VoidCallback? onArrowDown;

  @override
  State<SLSearchField> createState() => _SLSearchFieldState();
}

class _SLSearchFieldState extends State<SLSearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  Timer? _debounceTimer;
  var _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    if (widget.focusNode == null) _focusNode.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() => _focused = _focusNode.hasFocus);

  void _onChanged(String value) {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () {
      final query = value.trim();
      if (query.isEmpty || query.length >= widget.minQueryLength) {
        widget.onQueryChanged(query);
      }
    });
  }

  /// `Esc` очищает поле; повторный `Esc` снимает фокус (US-82).
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_controller.text.isEmpty) {
        node.unfocus();
      } else {
        _controller.clear();
        _debounceTimer?.cancel();
        widget.onQueryChanged('');
        setState(() {});
      }

      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
        widget.onArrowDown != null) {
      widget.onArrowDown!();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final height = SLDensity.ofContext(context).fieldMd;
    final showHint =
        widget.showHotkeyHint && !_focused && _controller.text.isEmpty;

    // Кольца фокуса нет: рамка поиска сама окрашивается в `borderFocus`,
    // и кольцо снаружи давало бы второй синий контур с зазором
    // (`system.md`, 10.6.1). Фокус показывает утолщение рамки до 2 px.
    return SizedBox(
      height: height,
      child: Focus(
        onKeyEvent: _onKeyEvent,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          onSubmitted: (_) => widget.onSubmitted?.call(),
          textInputAction: TextInputAction.search,
          style: text.bodyS.copyWith(color: colors.textPrimary),
          cursorColor: colors.accent,
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: colors.surface,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: SLSpacing.space1,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space2),
              child: Icon(
                Icons.search_rounded,
                size: SLIconSizes.icon16,
                color: colors.iconMuted,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: _buildSuffix(colors, text, showHint: showHint),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            // `contentPadding` один на все состояния: рамка утолщается
            // внутрь, и текст с кареткой при фокусе не сдвигаются.
            border: _border(colors.borderStrong, SLBorders.hairline),
            enabledBorder: _border(colors.borderStrong, SLBorders.hairline),
            focusedBorder: _border(colors.borderFocus, SLBorders.controlFocus),
          ),
        ),
      ),
    );
  }

  Widget? _buildSuffix(
    SLColorScheme colors,
    SLTextScheme text, {
    required bool showHint,
  }) {
    if (widget.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(right: SLSpacing.space2),
        child: SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.accent,
          ),
        ),
      );
    }

    if (_controller.text.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: SLSpacing.space1),
        child: Semantics(
          button: true,
          label: 'Очистить поиск',
          child: InkWell(
            borderRadius: SLRadii.smAll,
            onTap: () {
              _controller.clear();
              _debounceTimer?.cancel();
              widget.onQueryChanged('');
              setState(() {});
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

    if (!showHint) return null;

    return Padding(
      padding: const EdgeInsets.only(right: SLSpacing.space2),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space1),
          decoration: BoxDecoration(
            color: colors.surfaceSunken,
            borderRadius: SLRadii.smAll,
          ),
          child: Text(
            widget.hotkeyHint,
            style: text.overline.copyWith(color: colors.textMuted),
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
