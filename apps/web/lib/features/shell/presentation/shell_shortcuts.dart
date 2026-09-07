import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Обработчик глобальных хоткеев оболочки
/// (`docs/design/screens/README.md`, 5).
///
/// Написан руками, а не через [Shortcuts], по одной причине: последовательности
/// вида `g` затем `p` штатный механизм не умеет. Раз уж обработчик всё равно
/// нужен, в нём же живут и одиночные клавиши — иначе логика «не срабатывать,
/// когда фокус в поле ввода» оказалась бы размазана по двум механизмам.
///
/// Вторая клавиша последовательности ждётся 1500 мс, затем ожидание
/// сбрасывается. Индикации ожидания нет: она отвлекает, а последовательность
/// либо угадана, либо нет.
class ShellShortcuts extends StatefulWidget {
  /// @nodoc
  const ShellShortcuts({
    required this.child,
    required this.onFocusSearch,
    required this.onToggleSidebar,
    required this.onGoProjects,
    required this.onGoNotifications,
    required this.onShowHelp,
    super.key,
  });

  /// Оболочка целиком.
  final Widget child;

  /// `/` и `Ctrl/Cmd + K`, а также `g` затем `i`.
  final VoidCallback onFocusSearch;

  /// `[`.
  final VoidCallback onToggleSidebar;

  /// `g` затем `p`.
  final VoidCallback onGoProjects;

  /// `g` затем `n`.
  final VoidCallback onGoNotifications;

  /// `?`.
  final VoidCallback onShowHelp;

  /// Сколько ждать вторую клавишу последовательности.
  static const sequenceTimeout = Duration(milliseconds: 1500);

  @override
  State<ShellShortcuts> createState() => _ShellShortcutsState();
}

class _ShellShortcutsState extends State<ShellShortcuts> {
  Timer? _sequenceTimer;
  var _awaitingSecondKey = false;

  @override
  void dispose() {
    _sequenceTimer?.cancel();
    super.dispose();
  }

  /// Находится ли фокус в текстовом поле.
  ///
  /// Одиночные буквенные хоткеи в поле ввода не срабатывают — иначе набрать
  /// слово «go» в комментарии было бы невозможно.
  bool get _isTypingInField {
    final focused = FocusManager.instance.primaryFocus;

    return focused?.context?.widget is EditableText ||
        focused?.context?.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  void _startSequence() {
    _sequenceTimer?.cancel();
    _awaitingSecondKey = true;
    _sequenceTimer = Timer(
      ShellShortcuts.sequenceTimeout,
      () => _awaitingSecondKey = false,
    );
  }

  void _endSequence() {
    _sequenceTimer?.cancel();
    _awaitingSecondKey = false;
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final pressed = HardwareKeyboard.instance;
    final withCommand = pressed.isControlPressed || pressed.isMetaPressed;

    // Ctrl/Cmd + K работает всегда, включая поля ввода.
    if (withCommand && key == LogicalKeyboardKey.keyK) {
      widget.onFocusSearch();

      return KeyEventResult.handled;
    }

    if (_isTypingInField || withCommand) return KeyEventResult.ignored;

    if (_awaitingSecondKey) {
      _endSequence();

      if (key == LogicalKeyboardKey.keyP) {
        widget.onGoProjects();

        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyI) {
        widget.onFocusSearch();

        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyN) {
        widget.onGoNotifications();

        return KeyEventResult.handled;
      }

      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.keyG) {
      _startSequence();

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.slash) {
      widget.onFocusSearch();

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.bracketLeft) {
      widget.onToggleSidebar();

      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.question) {
      widget.onShowHelp();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
    onKeyEvent: _onKeyEvent,
    skipTraversal: true,
    canRequestFocus: false,
    child: widget.child,
  );
}
