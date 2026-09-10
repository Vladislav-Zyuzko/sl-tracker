import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Находится ли клавиатурный фокус внутри текстового поля.
///
/// Одиночные буквенные хоткеи (`c`, `s`, `a`, `n`, …) в поле ввода
/// не срабатывают: иначе набрать слово в описании или в поиске было бы
/// невозможно.
///
/// Проверяем по дереву, а не по своему флагу: поле ввода может лежать
/// где угодно ниже — в модалке, в меню, в редакторе комментария, — и
/// перечислить их все на экране нельзя.
bool slIsTypingInField() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return false;

  return context.widget is EditableText ||
      context.findAncestorWidgetOfExactType<EditableText>() != null;
}

/// Одиночные хоткеи экрана, которые **не отбирают клавишу у поля ввода**.
///
/// Замена [CallbackShortcuts]. Причина замены — живой дефект: на русской
/// раскладке «ф» — это физическая клавиша `A`, «н» — `Y`, и в описании
/// задачи эти буквы не набирались вовсе.
///
/// [CallbackShortcuts] считает событие обработанным, как только активатор
/// совпал, — **независимо от того, сделал ли обработчик хоть что-нибудь**.
/// Проверка «фокус в поле, значит выходим» внутри самого обработчика
/// не помогает: клавиша всё равно поглощена, до `EditableText` не доходит,
/// а в вебе поглощённое событие ещё и получает `preventDefault`, и символ
/// не появляется.
///
/// Здесь решение принимается **до** того, как событие объявлено обработанным:
/// пока фокус в текстовом поле (или пока [enabled] равен `false`), виджет
/// возвращает [KeyEventResult.ignored], и событие спокойно уходит дальше
/// по дереву — в поле ввода и в браузер.
///
/// Для сочетаний с модификаторами (`Ctrl/Cmd + Enter` в модалках,
/// `Ctrl + B` в редакторе Markdown) [CallbackShortcuts] по-прежнему годится:
/// они не конфликтуют с набором текста и обязаны работать прямо в поле.
class SLShortcuts extends StatelessWidget {
  /// @nodoc
  const SLShortcuts({
    required this.bindings,
    required this.child,
    this.enabled = true,
    super.key,
  });

  /// Клавиша — действие. Клавиша, которой нет в карте, уходит дальше.
  final Map<ShortcutActivator, VoidCallback> bindings;

  /// Работают ли хоткеи сейчас. `false` — событие не перехватывается вовсе,
  /// а не перехватывается «вхолостую».
  final bool enabled;

  /// @nodoc
  final Widget child;

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (!enabled || slIsTypingInField()) return KeyEventResult.ignored;

    var result = KeyEventResult.ignored;
    for (final entry in bindings.entries) {
      if (entry.key.accepts(event, HardwareKeyboard.instance)) {
        entry.value();
        result = KeyEventResult.handled;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: _onKeyEvent,
    child: child,
  );
}
