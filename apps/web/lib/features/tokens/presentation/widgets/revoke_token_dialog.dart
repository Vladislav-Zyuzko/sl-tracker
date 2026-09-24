import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/tokens/domain/token_presentation.dart';
import 'package:sl_tracker_web/features/tokens/presentation/tokens_providers.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_record_state_badge.dart';
import 'package:sl_tracker_web/shared/uikit/overlays/sl_dialog.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Подтверждение отзыва токена (`docs/design/screens/tokens.md`).
///
/// Ввода названия для подтверждения не требуем: потери ограничены одним
/// конфигом, а не данными. Требование печатать имя превратило бы
/// гигиеническую операцию в мучение и заставило бы копить мёртвые токены.
///
/// **Отзыв не оптимистичный**: строка меняется только после `204`. Пока идёт
/// запрос, окно не закрывается, а кнопка подтверждения в состоянии загрузки.
///
/// Возвращает `true`, если токен отозван.
class RevokeTokenDialog extends ConsumerStatefulWidget {
  /// @nodoc
  const RevokeTokenDialog({required this.token, super.key});

  /// Токен, который отзывают.
  final TokenDto token;

  /// Показывает окно.
  static Future<bool> show(BuildContext context, TokenDto token) async {
    final revoked = await showDialog<bool>(
      context: context,
      builder: (context) => RevokeTokenDialog(token: token),
    );

    return revoked ?? false;
  }

  @override
  ConsumerState<RevokeTokenDialog> createState() => _RevokeTokenDialogState();
}

class _RevokeTokenDialogState extends ConsumerState<RevokeTokenDialog> {
  ApiFailure? _failure;
  var _submitting = false;

  Future<void> _submit() async {
    if (_submitting) return;

    setState(() {
      _submitting = true;
      _failure = null;
    });

    try {
      await ref.read(tokensListProvider.notifier).revoke(widget.token.id);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiFailure catch (failure) {
      // Окно остаётся открытым, строка в списке не трогается.
      if (!mounted) return;

      setState(() {
        _submitting = false;
        _failure = failure;
      });
    }
  }

  /// Текст ошибки по коду сервера.
  (String, String) _errorTextOf(ApiFailure failure) {
    if (failure.code == 'pat_cannot_manage_tokens' ||
        failure.kind == ApiFailureKind.forbidden) {
      return (
        'Управление токенами доступно только из веб-интерфейса',
        'Откройте трекер в браузере под своим аккаунтом.',
      );
    }

    if (failure.kind == ApiFailureKind.notFound) {
      return (
        'Токена больше нет',
        'Похоже, его уже отозвали. Обновите список.',
      );
    }

    return ('Не удалось отозвать токен, повторите', 'Строка списка цела.');
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final failure = _failure;
    final expired =
        TokenPresentation.stateOf(widget.token) == SLRecordState.expired;

    return SLDialog(
      title: 'Отозвать токен «${widget.token.name}»?',
      onClose: _submitting ? null : () => Navigator.of(context).pop(false),
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
          // Фокус при открытии — на безопасной кнопке, чтобы `Enter`
          // не отзывал случайно.
          autofocus: true,
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
        ),
        SLButton(
          label: 'Отозвать токен',
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
          // Пугать последствиями, которых не будет, нельзя: один такой текст,
          // и человек перестанет читать остальные.
          if (expired)
            const _Consequence(
              'токен уже истёк и не работает — отзыв просто уберёт его '
              'из списка;',
            )
          else
            const _Consequence(
              'действующие агенты потеряют доступ немедленно — следующий '
              'их запрос получит отказ;',
            ),
          const _Consequence(
            'задачи и комментарии, созданные с этим токеном, останутся;',
          ),
          const _Consequence(
            'вернуть токен нельзя — при необходимости выпустите новый.',
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
