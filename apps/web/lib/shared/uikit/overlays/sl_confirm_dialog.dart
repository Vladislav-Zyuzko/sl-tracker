import 'package:flutter/material.dart';

import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/overlays/sl_dialog.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Подтверждение действия без запроса к серверу внутри окна
/// (`docs/design/components.md`, 13).
///
/// Возвращает `true`, если человек подтвердил, и `null`, если передумал.
/// Само действие выполняет вызывающий: окно, которое и спрашивает,
/// и ходит в сеть, и показывает ошибку, вырастает в отдельный экран —
/// такие случаи (исключение участника, удаление проекта) сделаны отдельными
/// виджетами.
///
/// У опасного действия фокус при открытии стоит на «Отмена», а не на кнопке
/// подтверждения: случайный `Enter` не должен ничего ломать.
class SLConfirmDialog extends StatefulWidget {
  /// @nodoc
  const SLConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Отмена',
    this.variant = SLButtonVariant.primary,
    super.key,
  });

  /// Заголовок — вопрос, на который человек отвечает.
  final String title;

  /// Что произойдёт. Формулируется последствиями, а не «вы уверены?».
  final String message;

  /// Подпись кнопки подтверждения. Глагол действия.
  final String confirmLabel;

  /// @nodoc
  final String cancelLabel;

  /// Вариант кнопки подтверждения.
  final SLButtonVariant variant;

  /// Показывает окно.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Отмена',
    SLButtonVariant variant = SLButtonVariant.primary,
  }) => showDialog<bool>(
    context: context,
    builder: (context) => SLConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      variant: variant,
    ),
  );

  @override
  State<SLConfirmDialog> createState() => _SLConfirmDialogState();
}

class _SLConfirmDialogState extends State<SLConfirmDialog> {
  final _cancelFocusNode = FocusNode(debugLabel: 'confirm-cancel');

  bool get _isDangerous =>
      widget.variant == SLButtonVariant.danger ||
      widget.variant == SLButtonVariant.dangerGhost;

  @override
  void dispose() {
    _cancelFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return SLDialog(
      title: widget.title,
      onClose: () => Navigator.of(context).pop(),
      actions: [
        SLButton(
          label: widget.cancelLabel,
          variant: SLButtonVariant.secondary,
          focusNode: _cancelFocusNode,
          autofocus: _isDangerous,
          onPressed: () => Navigator.of(context).pop(),
        ),
        SLButton(
          label: widget.confirmLabel,
          variant: widget.variant,
          autofocus: !_isDangerous,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
      child: Text(
        widget.message,
        style: text.body.copyWith(color: colors.textPrimary),
      ),
    );
  }
}
