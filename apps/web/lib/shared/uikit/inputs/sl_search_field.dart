import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Вид поля поиска (`docs/design/components.md`, 4.1).
enum SLSearchFieldVariant {
  /// Самостоятельное: сайдбар, список доступа, шапка экрана.
  ///
  /// Высота 36 — вровень со строкой списка, — рамка `borderControl`,
  /// минимальная ширина 240.
  standalone,

  /// Встроенное в меню или поповер: высота 32, **рамки нет**, снизу
  /// разделитель во всю ширину меню.
  ///
  /// Рамка внутри рамки меню — та же «коробка в коробке», из-за которой
  /// переделывали кольцо фокуса (`system.md`, 10.6.1).
  embedded;

  /// Высота поля для этой плотности.
  double height(SLDensity density) => switch (this) {
    SLSearchFieldVariant.standalone => density.searchStandalone,
    SLSearchFieldVariant.embedded => density.searchEmbedded,
  };
}

/// Поле поиска (`docs/design/components.md`, 4).
///
/// Отдельный компонент, а не «поле ввода с иконкой»: у него своя геометрия
/// (`system.md`, 10.3.1), своё поведение — дебаунс, подсказка хоткея,
/// обработка `Esc`, — и свои правила текста.
///
/// **Плейсхолдер говорит, что вводить, а не какова область поиска**
/// (`components.md`, 4.2). Правило выведено из дефекта: «Поиск по моим
/// активным задачам» занимает ≈ 207 px, а под текст в поле сайдбара
/// оставалось 184 — плейсхолдер обрезался и переставал что-либо объяснять.
/// Область поиска живёт в заголовке над полем, в подписи под полем при
/// вводе и в тексте пустого результата.
class SLSearchField extends StatefulWidget {
  /// @nodoc
  const SLSearchField({
    required this.hint,
    required this.onQueryChanged,
    this.variant = SLSearchFieldVariant.standalone,
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

  /// Плейсхолдер. Называет то, **что вводить**: «Название или ключ»,
  /// «Поиск по адресу». Область поиска сюда не помещается и здесь
  /// не живёт (`components.md`, 4.2).
  final String hint;

  /// Самостоятельное поле или встроенное в меню.
  final SLSearchFieldVariant variant;

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
    final density = SLDensity.ofContext(context);
    final height = widget.variant.height(density);
    final isEmbedded = widget.variant == SLSearchFieldVariant.embedded;
    final showHint =
        widget.showHotkeyHint && !_focused && _controller.text.isEmpty;

    // Кольца фокуса нет: рамка поиска сама окрашивается в `borderFocus`,
    // и кольцо снаружи давало бы второй синий контур с зазором
    // (`system.md`, 10.6.1). Фокус показывает утолщение рамки до 2 px.
    // У встроенного в меню рамки нет вовсе — фокус утолщает разделитель.
    final field = SizedBox(
      height: height,
      child: Focus(
        onKeyEvent: _onKeyEvent,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          onSubmitted: (_) => widget.onSubmitted?.call(),
          textInputAction: TextInputAction.search,
          // Строка — по центру высоты поля в обоих видах. У самостоятельного
          // (с контуром) это и так поведение `InputDecorator` по умолчанию;
          // у встроенного (без рамки) по умолчанию «прижать к верху», и
          // строка стояла выше иконки поиска, центрованной по высоте поля.
          textAlignVertical: TextAlignVertical.center,
          style: text.bodyS.copyWith(color: colors.textPrimary),
          cursorColor: colors.accent,
          decoration: InputDecoration(
            hintText: widget.hint,
            // Внутри меню фон уже нарисован самим меню: второй слой
            // `surface` поверх него — лишний прямоугольник.
            filled: !isEmbedded,
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
            // Слот иконки поиска — во всю высоту поля: это и держит высоту
            // рамки. `InputDecorator` рисует заливку и контур не по
            // `SizedBox(height)`, а по высоте своего содержимого — при
            // `isDense` и компактной плотности это самый высокий из слотов
            // иконок или строка текста. С `minHeight: 0` рамка зависела от
            // того, что стоит справа: с бейджем `/`, спиннером или пустая —
            // 18, с кнопкой очистки 24 × 24 — 24, и всё это внутри коробки
            // 36. Иконка поиска есть во всех состояниях, поэтому, растянутая
            // на высоту поля, она делает рамку ровно `height` всегда, что бы
            // ни стояло справа (`system.md`, 10.3.1).
            prefixIconConstraints: BoxConstraints(
              minWidth: 0,
              minHeight: height,
            ),
            suffixIcon: _buildSuffix(colors, text, showHint: showHint),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            // `contentPadding` один на все состояния: рамка утолщается
            // внутрь, и текст с кареткой при фокусе не сдвигаются.
            border: _decorationBorder(
              colors,
              isEmbedded: isEmbedded,
              focused: false,
            ),
            enabledBorder: _decorationBorder(
              colors,
              isEmbedded: isEmbedded,
              focused: false,
            ),
            focusedBorder: _decorationBorder(
              colors,
              isEmbedded: isEmbedded,
              focused: true,
            ),
          ),
        ),
      ),
    );

    if (isEmbedded) {
      // Границу внутри меню несёт разделитель, а не контур
      // (`components.md`, 4.1). В фокусе он утолщается до 2 px — ровно
      // так же, как утолщается рамка самостоятельного поля.
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _focused ? colors.borderFocus : colors.borderSubtle,
              width: _focused ? SLBorders.controlFocus : SLBorders.hairline,
            ),
          ),
        ),
        child: field,
      );
    }

    // Минимальная ширина — часть контракта компонента: уже 240 плейсхолдер
    // перестаёт помещаться (`system.md`, 10.3.1). Родитель, задавший тугую
    // ширину, всё равно победит — поэтому 240 живёт токеном и проверяется
    // у каждого места вызова, а здесь стоит как страховка.
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: SLSizes.searchFieldMinWidth),
      child: field,
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

  InputBorder _decorationBorder(
    SLColorScheme colors, {
    required bool isEmbedded,
    required bool focused,
  }) {
    if (isEmbedded) return InputBorder.none;

    return OutlineInputBorder(
      borderRadius: SLRadii.smAll,
      borderSide: BorderSide(
        color: focused ? colors.borderFocus : colors.borderStrong,
        width: focused ? SLBorders.controlFocus : SLBorders.hairline,
      ),
    );
  }
}
