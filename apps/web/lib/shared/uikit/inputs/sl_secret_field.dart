import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Поле-секрет: одноразовый показ значения
/// (`docs/design/components.md`, 23.2 и 23.1).
///
/// Значение показывается **один раз** и не может быть восстановлено: секрет
/// токена доступа, а в будущем — ссылка-приглашение. Отсюда все решения:
///
/// - значение живёт только в памяти виджета: ни в локальном хранилище,
///   ни в черновиках, ни в состоянии роутера, ни в логах;
/// - это [SelectableText], а не `TextField`: поле ввода обещает
///   редактирование, которого нет, а выделение мышью — обязательный запасной
///   путь, если буфер обмена недоступен;
/// - копирование выполняется **только по явному действию** человека:
///   автокопирование молча затирает буфер обмена;
/// - отказ `Clipboard` в вебе (нет жеста пользователя, не HTTPS, запрет
///   политики) не остаётся незамеченным: появляется баннер с ручным путём.
///
/// Состояний «показать/скрыть» и «показать ещё раз» у компонента нет: прятать
/// то, что видно единственный раз, бессмысленно, а показывать повторно нечего.
class SLSecretField extends StatefulWidget {
  /// @nodoc
  const SLSecretField({
    required this.value,
    required this.copyAccessibleName,
    required this.copyAnnouncement,
    this.copyLabel = 'Скопировать',
    this.copiedLabel = 'Скопировано',
    this.onCopied,
    this.copyFocusNode,
    this.autofocusCopy = false,
    super.key,
  });

  /// Значение. Наружу этой строки не существует: её не логируют
  /// и не сохраняют.
  final String value;

  /// Доступное имя кнопки копирования. Называет результат и последствие:
  /// «Скопировать токен в буфер обмена. Показать его повторно будет нельзя».
  final String copyAccessibleName;

  /// Что объявляется скринридеру после успешного копирования:
  /// «Токен скопирован в буфер обмена».
  final String copyAnnouncement;

  /// @nodoc
  final String copyLabel;

  /// @nodoc
  final String copiedLabel;

  /// Успешное копирование. Вызывается каждый раз: по этому признаку экран
  /// решает, спрашивать ли подтверждение при закрытии.
  final VoidCallback? onCopied;

  /// @nodoc
  final FocusNode? copyFocusNode;

  /// Фокус при появлении — на кнопке копирования: первое действие здесь одно.
  final bool autofocusCopy;

  /// Сколько держится подтверждение «Скопировано».
  static const confirmationDuration = Duration(milliseconds: 2000);

  /// Максимум строк значения на десктопе, дальше — внутренняя прокрутка.
  static const maxLines = 3;

  /// Максимум строк значения на телефоне: колонка узкая, и прокручивать
  /// секрет в трёх строках неудобно.
  static const maxLinesCompact = 5;

  /// Высота строки моноширинного текста (13/18).
  static const lineHeight = 18.0;

  /// Ширина кнопки копирования.
  ///
  /// Фиксированная: подпись меняется на «Скопировано» на две секунды,
  /// и кнопка не должна при этом менять размер — иначе соседние элементы
  /// прыгают (`components.md`, 23.1).
  static const copyButtonWidth = 168.0;

  /// Текст отказа буфера обмена. Ручной путь назван прямо: значение
  /// выделяемое, и это единственный способ не потерять секрет.
  static const copyFailureTitle = 'Не удалось скопировать';

  /// @nodoc
  static const copyFailureDescription =
      'Выделите значение и скопируйте вручную (Ctrl/Cmd + C).';

  @override
  State<SLSecretField> createState() => SLSecretFieldState();
}

/// Состояние [SLSecretField].
///
/// Публичное ради одного метода — [copy]: `Ctrl/Cmd + C` внутри диалога
/// обязан делать ровно то же, что кнопка, включая объявление результата.
class SLSecretFieldState extends State<SLSecretField> {
  Timer? _confirmationTimer;
  var _copied = false;
  var _failed = false;

  @override
  void dispose() {
    _confirmationTimer?.cancel();
    super.dispose();
  }

  /// Копирует значение в буфер обмена.
  ///
  /// Повторное нажатие разрешено и снова показывает подтверждение:
  /// блокировки на время подтверждения нет.
  Future<void> copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.value));
    } on Object {
      // В вебе `Clipboard` отказывает, когда нет пользовательского жеста
      // или страница не в защищённом контексте. Молчать об этом нельзя:
      // человек решит, что токен у него в буфере, и потеряет его.
      if (!mounted) return;

      setState(() {
        _copied = false;
        _failed = true;
      });
      _announce(
        '${SLSecretField.copyFailureTitle}. '
        '${SLSecretField.copyFailureDescription}',
        // Отказ перебивает скринридер намеренно: молча потерянный токен
        // дороже прерванной фразы.
        assertiveness: Assertiveness.assertive,
      );

      return;
    }

    if (!mounted) return;

    setState(() {
      _copied = true;
      _failed = false;
    });
    _announce(widget.copyAnnouncement);
    widget.onCopied?.call();

    _confirmationTimer?.cancel();
    _confirmationTimer = Timer(SLSecretField.confirmationDuration, () {
      if (!mounted) return;

      setState(() => _copied = false);
    });
  }

  /// Объявление результата копирования.
  ///
  /// `sendAnnouncement`, а не устаревший `announce`: последний предполагает
  /// единственное окно и помечен к удалению.
  void _announce(
    String message, {
    Assertiveness assertiveness = Assertiveness.polite,
  }) => unawaited(
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      TextDirection.ltr,
      assertiveness: assertiveness,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final isPhone = SLBreakpoint.of(context).isPhone;
    final maxLines = isPhone
        ? SLSecretField.maxLinesCompact
        : SLSecretField.maxLines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxLines * SLSecretField.lineHeight + SLSpacing.space4,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceSunken,
              borderRadius: SLRadii.smAll,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(SLSpacing.space2),
              child: SelectableText(
                widget.value,
                // Значение читается скринридером по запросу и не объявляется
                // само: зачитывать вслух 60 случайных символов при открытии —
                // не помощь.
                style: text.mono.copyWith(color: colors.textPrimary),
              ),
            ),
          ),
        ),
        const SizedBox(height: SLSpacing.space2),
        Align(
          alignment: Alignment.centerRight,
          child: _CopyButton(
            label: _copied ? widget.copiedLabel : widget.copyLabel,
            copied: _copied,
            accessibleName: widget.copyAccessibleName,
            focusNode: widget.copyFocusNode,
            autofocus: widget.autofocusCopy,
            expand: isPhone,
            onPressed: copy,
          ),
        ),
        if (_failed) ...[
          const SizedBox(height: SLSpacing.space2),
          const SLBanner(
            title: SLSecretField.copyFailureTitle,
            description: SLSecretField.copyFailureDescription,
          ),
        ],
      ],
    );
  }
}

/// Кнопка копирования (`components.md`, 23.1).
///
/// Ширина фиксирована и не зависит от подписи: между «Скопировать»
/// и «Скопировано» кнопка не меняет размер.
class _CopyButton extends StatelessWidget {
  const _CopyButton({
    required this.label,
    required this.copied,
    required this.accessibleName,
    required this.focusNode,
    required this.autofocus,
    required this.expand,
    required this.onPressed,
  });

  final String label;
  final bool copied;
  final String accessibleName;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool expand;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);

    final button = SLButton(
      label: label,
      icon: copied ? Icons.check_rounded : Icons.content_copy_rounded,
      variant: SLButtonVariant.secondary,
      expand: true,
      focusNode: focusNode,
      autofocus: autofocus,
      // Подтверждение говорит цветом `success`, но не только им: меняются
      // и подпись, и иконка.
      foregroundColor: copied ? colors.success : null,
      onPressed: onPressed,
    );

    return Semantics(
      container: true,
      button: true,
      label: accessibleName,
      excludeSemantics: true,
      child: expand
          ? button
          : SizedBox(width: SLSecretField.copyButtonWidth, child: button),
    );
  }
}
