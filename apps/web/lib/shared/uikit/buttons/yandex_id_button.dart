import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';

/// Кнопка «Войти с Яндекс ID».
///
/// **Единственное задокументированное исключение из дизайн-системы**
/// (`docs/design/system.md`, 3.4.1; `screens/login.md`). Требования Яндекс ID
/// запрещают менять цвет кнопки, её содержимое, знак и отступы внутри неё,
/// поэтому здесь стоят литералы цвета и размера, а не токены: чёрный фон,
/// белый текст, высота 44, скругление 12.
///
/// Исключение действует только на этом виджете и только на экране входа.
/// Ни одна другая кнопка продукта так не выглядит; при пересмотре палитры
/// и в тёмной теме эта кнопка остаётся неизменной, потому что она чужая.
/// Расширять исключение нельзя.
///
/// Знак — официальный ассет (`assets/brand/yandex-id-mark.png` в трёх
/// плотностях). Он **уже содержит** оранжевый фон `#FC3F1D` и скругление:
/// подкладывать под него свою подложку нельзя, перекрашивать и рисовать
/// самостоятельно — тем более.
///
/// Основа — [FilledButton] с полностью переопределённым стилем, а не своя
/// разметка: клавиатурная активация, обход фокусом и семантика кнопки
/// достаются даром и работают ровно так же, как у `SLButton`.
class YandexIdButton extends StatefulWidget {
  /// @nodoc
  const YandexIdButton({
    required this.onPressed,
    this.isLoading = false,
    this.focusNode,
    super.key,
  });

  /// Нажатие. `null` — кнопка отключена.
  final VoidCallback? onPressed;

  /// Браузер уже уходит на Яндекс: вместо надписи спиннер, повторные
  /// нажатия игнорируются. Кнопка при этом **не** выглядит отключённой.
  final bool isLoading;

  /// @nodoc
  final FocusNode? focusNode;

  /// Высота из допустимых Яндексом размеров: вариант M.
  static const height = 44.0;

  /// Скругление из допустимых: 12.
  static const radius = 12.0;

  /// Размер знака внутри кнопки.
  static const markSize = 24.0;

  /// Надпись: предустановленный текст, менять нельзя.
  static const label = 'Войти с Яндекс ID';

  /// Доступное имя кнопки (`screens/login.md`, «Доступность»).
  static const semanticLabel = 'Войти через Яндекс';

  /// Ассет знака.
  static const markAsset = 'assets/brand/yandex-id-mark.png';

  /// Фон: основной вариант — чёрный.
  static const background = Color(0xFF000000);

  /// Текст и спиннер: белый. Контраст 21:1.
  static const foreground = Color(0xFFFFFFFF);

  @override
  State<YandexIdButton> createState() => _YandexIdButtonState();
}

class _YandexIdButtonState extends State<YandexIdButton> {
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
    if (focused != _focused) setState(() => _focused = focused);
  }

  @override
  Widget build(BuildContext context) => SLFocusRing(
    focused: _focused,
    borderRadius: YandexIdButton.radius,
    child: SizedBox(
      width: double.infinity,
      child: Semantics(
        label: YandexIdButton.semanticLabel,
        button: true,
        excludeSemantics: true,
        child: FilledButton(
          focusNode: widget.focusNode,
          statesController: _statesController,
          // Во время перехода нажатие игнорируется, но кнопка не выглядит
          // отключённой: она всё ещё чёрная, а не полупрозрачная.
          onPressed: widget.isLoading ? () {} : widget.onPressed,
          style: _style,
          child: widget.isLoading
              ? const _LoadingContent()
              : const _LabelContent(),
        ),
      ),
    ),
  );

  static final _style = ButtonStyle(
    backgroundColor: const WidgetStatePropertyAll(YandexIdButton.background),
    foregroundColor: const WidgetStatePropertyAll(YandexIdButton.foreground),
    // Цвет кнопки менять нельзя, поэтому наведение и нажатие показываются
    // белой вуалью поверх чёрного, а не другим фоном.
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return YandexIdButton.foreground.withValues(alpha: 0.18);
      }
      if (states.contains(WidgetState.hovered)) {
        return YandexIdButton.foreground.withValues(alpha: 0.10);
      }

      return null;
    }),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: SLSpacing.space4),
    ),
    fixedSize: const WidgetStatePropertyAll(
      Size.fromHeight(YandexIdButton.height),
    ),
    minimumSize: const WidgetStatePropertyAll(
      Size(0, YandexIdButton.height),
    ),
    maximumSize: const WidgetStatePropertyAll(Size.infinite),
    shape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(YandexIdButton.radius),
        ),
      ),
    ),
    elevation: const WidgetStatePropertyAll(0),
    shadowColor: const WidgetStatePropertyAll(Color(0x00000000)),
    surfaceTintColor: const WidgetStatePropertyAll(Color(0x00000000)),
    splashFactory: NoSplash.splashFactory,
    visualDensity: VisualDensity.standard,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    mouseCursor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
    ),
    animationDuration: Duration.zero,
    alignment: Alignment.center,
  );
}

/// Знак и надпись. Отступ между ними задан Яндексом и не меняется.
class _LabelContent extends StatelessWidget {
  const _LabelContent();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _Mark(),
      SizedBox(width: SLSpacing.space2),
      Text(
        YandexIdButton.label,
        style: TextStyle(
          color: YandexIdButton.foreground,
          fontSize: 15,
          height: 20 / 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

/// Переход на Яндекс: знак остаётся, надпись сменяется спиннером.
class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _Mark(),
      SizedBox(width: SLSpacing.space2),
      SizedBox.square(
        dimension: SLIconSizes.icon16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: YandexIdButton.foreground,
        ),
      ),
    ],
  );
}

/// Знак Яндекс ID. Декоративен: доступное имя есть у кнопки целиком.
class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) => const Image(
    image: AssetImage(YandexIdButton.markAsset),
    width: YandexIdButton.markSize,
    height: YandexIdButton.markSize,
    excludeFromSemantics: true,
    filterQuality: FilterQuality.medium,
  );
}
