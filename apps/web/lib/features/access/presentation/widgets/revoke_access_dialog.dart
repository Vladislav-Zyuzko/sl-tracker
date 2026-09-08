import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/access/presentation/access_list_providers.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/overlays/sl_dialog.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Подтверждение отзыва доступа (`docs/design/screens/access-list.md`).
///
/// Самое опасное действие экрана: человека выбрасывает из приложения
/// посреди работы. Модалка обязана сказать это прямо.
///
/// Возвращает число погашенных сессий, если доступ отозван, и `null`,
/// если человек передумал.
class RevokeAccessDialog extends ConsumerStatefulWidget {
  /// @nodoc
  const RevokeAccessDialog({required this.entry, super.key});

  /// Запись, которую отзывают.
  final AccessEntryDto entry;

  /// Показывает окно.
  static Future<int?> show(BuildContext context, AccessEntryDto entry) =>
      showDialog<int>(
        context: context,
        builder: (context) => RevokeAccessDialog(entry: entry),
      );

  @override
  ConsumerState<RevokeAccessDialog> createState() => _RevokeAccessDialogState();
}

class _RevokeAccessDialogState extends ConsumerState<RevokeAccessDialog> {
  /// Фокус при открытии — на «Отмена»: у опасных подтверждений фокус
  /// стоит на безопасной кнопке, чтобы `Enter` не удалял случайно.
  final _cancelFocusNode = FocusNode(debugLabel: 'revoke-cancel');

  ApiFailure? _failure;
  var _submitting = false;

  @override
  void dispose() {
    _cancelFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    setState(() {
      _submitting = true;
      _failure = null;
    });

    try {
      final revoked = await ref
          .read(accessListProvider.notifier)
          .revoke(widget.entry.id);

      if (mounted) Navigator.of(context).pop(revoked);
    } on ApiFailure catch (failure) {
      // Модалка остаётся открытой, строка в списке не трогается.
      if (!mounted) return;

      setState(() {
        _submitting = false;
        _failure = failure;
      });
    }
  }

  /// Текст ошибки по коду сервера.
  ///
  /// Оба конфликта — не «что-то пошло не так», а понятные правила, которые
  /// человек должен узнать словами.
  (String, String) _errorTextOf(ApiFailure failure) => switch (failure.code) {
    'cannot_revoke_self' => (
      'Нельзя удалить собственный доступ',
      'Попросите другого владельца трекера сделать это.',
    ),
    'last_instance_owner' => (
      'В трекере должен остаться хотя бы один владелец',
      'Сначала назначьте владельцем кого-то ещё.',
    ),
    'access_entry_not_found' => (
      'Записи больше нет',
      'Похоже, доступ уже отозвали. Обновите список.',
    ),
    _ => ('Не удалось удалить', 'Попробуйте ещё раз.'),
  };

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final failure = _failure;

    return SLDialog(
      title: 'Удалить ${widget.entry.email} из списка доступа?',
      onClose: _submitting ? null : () => Navigator.of(context).pop(),
      banner: failure == null
          ? null
          : SLBanner(
              title: _errorTextOf(failure).$1,
              description: _errorTextOf(failure).$2,
              details: failure.toString(),
            ),
      actions: [
        SLButton(
          label: 'Отмена',
          variant: SLButtonVariant.secondary,
          focusNode: _cancelFocusNode,
          autofocus: true,
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
        ),
        SLButton(
          label: 'Удалить доступ',
          variant: SLButtonVariant.danger,
          isLoading: _submitting,
          onPressed: _submit,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Что произойдёт:',
            style: text.bodyStrong.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: SLSpacing.space2),
          const _Consequence('человек больше не сможет войти в трекер;'),
          const _Consequence(
            'его открытые сессии будут завершены сразу — если он сейчас '
            'работает, его выбросит из приложения;',
          ),
          const _Consequence(
            'участие в проектах, задачи, комментарии и история сохранятся.',
          ),
          const SizedBox(height: SLSpacing.space4),
          Text(
            'Чтобы вернуть доступ, добавьте адрес заново или пришлите новую '
            'ссылку-приглашение.',
            style: text.body.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Пункт списка последствий.
class _Consequence extends StatelessWidget {
  const _Consequence(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final textScheme = SLTextScheme.of(context);
    final style = textScheme.body.copyWith(color: colors.textPrimary);

    return Padding(
      padding: const EdgeInsets.only(bottom: SLSpacing.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: style),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
