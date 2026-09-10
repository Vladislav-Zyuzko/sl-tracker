import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';

/// Кнопка «Войти с Яндекс ID».
///
/// **Единственное задокументированное исключение из дизайн-системы**
/// (`docs/design/system.md`, 3.4.1; `screens/login.md`). Требования Яндекс ID
/// запрещают менять цвет кнопки, её содержимое, знак и отступы внутри неё,
/// поэтому здесь стоят литералы цвета и размера, а не токены: высота 44,
/// скругление 12 и один из двух опубликованных Яндексом вариантов цвета.
///
/// **Вариантов два, и оба — Яндекса.** Основной чёрный (белый текст) в светлой
/// схеме и дополнительный белый (чёрный текст) в тёмной. Это не изменение
/// кнопки: выбор между двумя опубликованными вариантами разрешён, а знак,
/// надпись, отступы, высота и радиус в обоих одинаковы. Причина замера,
/// а не вкуса: чёрная кнопка на тёмном фоне экрана входа (`surfaceSunken`
/// `#10141C`) даёт **1.14:1** при требуемых WCAG 1.4.11 3:1 — единственный
/// контрол единственного экрана без сессии превращается в дыру. Белый
/// вариант на том же фоне даёт 18.44:1 (`system.md`, 3.4.1).
///
/// Роли системы к кнопке по-прежнему не применяются: цвет берётся не из
/// [SLColorScheme], а из требований Яндекса — тема лишь говорит, какой
/// из двух вариантов сейчас уместен. Расширять исключение нельзя.
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

  /// Фон основного варианта Яндекса — чёрный.
  static const blackBackground = Color(0xFF000000);

  /// Текст и спиннер основного варианта — белый. Контраст 21:1.
  static const blackForeground = Color(0xFFFFFFFF);

  /// Фон дополнительного варианта Яндекса — белый.
  static const whiteBackground = Color(0xFFFFFFFF);

  /// Текст и спиннер дополнительного варианта — чёрный. Контраст 21:1.
  static const whiteForeground = Color(0xFF000000);

  /// Фон варианта, уместного в схеме [brightness].
  static Color backgroundOf(Brightness brightness) =>
      brightness == Brightness.dark ? whiteBackground : blackBackground;

  /// Цвет надписи и спиннера того же варианта.
  ///
  /// Спиннер красится **этим** цветом, а не ролью `textOnAccent`: кнопка
  /// вне системы, а в тёмной схеме `textOnAccent` стал тёмным — белый
  /// спиннер на белой кнопке исчез бы (`screens/login.md`, «Состояния»).
  static Color foregroundOf(Brightness brightness) =>
      brightness == Brightness.dark ? whiteForeground : blackForeground;

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
  Widget build(BuildContext context) {
    // Схема решает только одно: какой из двух вариантов Яндекса показать.
    final brightness = Theme.of(context).brightness;
    final foreground = YandexIdButton.foregroundOf(brightness);

    return SLFocusRing(
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
            // отключённой: она всё ещё сплошная, а не полупрозрачная.
            onPressed: widget.isLoading ? () {} : widget.onPressed,
            style: _styleOf(brightness),
            child: widget.isLoading
                ? _LoadingContent(color: foreground)
                : _LabelContent(color: foreground),
          ),
        ),
      ),
    );
  }

  /// Стиль варианта. Обе версии собираются по одному разу: [ButtonStyle]
  /// не бесплатен, а экран входа перестраивается на каждом кадре спиннера.
  static ButtonStyle _styleOf(Brightness brightness) =>
      brightness == Brightness.dark ? _darkStyle : _lightStyle;

  static final _lightStyle = _buildStyle(Brightness.light);
  static final _darkStyle = _buildStyle(Brightness.dark);

  static ButtonStyle _buildStyle(Brightness brightness) {
    final background = YandexIdButton.backgroundOf(brightness);
    final foreground = YandexIdButton.foregroundOf(brightness);

    return ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(background),
      foregroundColor: WidgetStatePropertyAll(foreground),
      // Цвет кнопки менять нельзя, поэтому наведение и нажатие показываются
      // вуалью цвета надписи поверх фона, а не другим фоном: на чёрном
      // варианте она белая, на белом — чёрная.
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return foreground.withValues(alpha: 0.18);
        }
        if (states.contains(WidgetState.hovered)) {
          return foreground.withValues(alpha: 0.10);
        }

        return null;
      }),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: SLSpacing.space4),
      ),
      fixedSize: const WidgetStatePropertyAll(
        Size.fromHeight(YandexIdButton.height),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, YandexIdButton.height)),
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
}

/// Знак и надпись. Отступ между ними задан Яндексом и не меняется.
class _LabelContent extends StatelessWidget {
  const _LabelContent({required this.color});

  /// Цвет надписи выбранного варианта кнопки.
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const _Mark(),
      const SizedBox(width: SLSpacing.space2),
      Text(
        YandexIdButton.label,
        style: TextStyle(
          color: color,
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
  const _LoadingContent({required this.color});

  /// Цвет спиннера — цвет надписи **этой** кнопки, а не роль `textOnAccent`:
  /// на белом варианте белый спиннер был бы невидим.
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const _Mark(),
      const SizedBox(width: SLSpacing.space2),
      SizedBox.square(
        dimension: SLIconSizes.icon16,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
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
