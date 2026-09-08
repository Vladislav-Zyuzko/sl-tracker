import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/access/domain/access_email.dart';
import 'package:sl_tracker_web/features/access/presentation/access_list_providers.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_text_field.dart';
import 'package:sl_tracker_web/shared/uikit/overlays/sl_dialog.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Добавление адреса в список доступа (`docs/design/screens/access-list.md`).
///
/// Возвращает добавленный адрес или `null`, если человек передумал.
/// Массового добавления в MVP нет: оно требует отчёта о том, какие адреса
/// приняты, а какие отклонены, — это отдельный экран.
class AddAccessEntryDialog extends ConsumerStatefulWidget {
  /// @nodoc
  const AddAccessEntryDialog({super.key});

  /// Показывает окно.
  static Future<String?> show(BuildContext context) => showDialog<String>(
    context: context,
    builder: (context) => const AddAccessEntryDialog(),
  );

  @override
  ConsumerState<AddAccessEntryDialog> createState() =>
      _AddAccessEntryDialogState();
}

class _AddAccessEntryDialogState extends ConsumerState<AddAccessEntryDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode(debugLabel: 'access-email');

  String? _fieldError;
  ApiFailure? _failure;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    // Проверка формата — по потере фокуса, а не по каждому символу:
    // подчёркивать ошибку в недописанном адресе бессмысленно.
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) return;

    final value = _controller.text;
    if (value.isEmpty) return;

    setState(() => _fieldError = _validate(value));
  }

  String? _validate(String value) => AccessEmail.isValid(value)
      ? null
      : 'Проверьте адрес: похоже, в нём опечатка';

  /// Приведение к нижнему регистру видно сразу — иначе оно станет сюрпризом
  /// после отправки.
  void _onChanged(String value) {
    final normalized = value.toLowerCase();
    if (normalized != value) {
      _controller.value = _controller.value.copyWith(
        text: normalized,
        selection: TextSelection.collapsed(
          offset: _controller.selection.baseOffset.clamp(0, normalized.length),
        ),
        composing: TextRange.empty,
      );
    }

    if (_fieldError != null || _failure != null) {
      setState(() {
        _fieldError = null;
        _failure = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final email = AccessEmail.normalize(_controller.text);
    final error = _validate(email);
    if (error != null) {
      setState(() => _fieldError = error);
      _focusNode.requestFocus();

      return;
    }

    setState(() {
      _submitting = true;
      _failure = null;
    });

    try {
      await ref.read(accessListProvider.notifier).add(email);
      if (mounted) Navigator.of(context).pop(email);
    } on ApiFailure catch (failure) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
        // Введённый адрес сохраняется: заставлять набирать его заново
        // из-за ошибки сервера — издевательство.
        switch (failure.code) {
          case 'access_entry_exists':
            _fieldError = 'Этот адрес уже в списке';
          case 'invalid_email':
            _fieldError = 'Сервер не принял этот адрес';
          default:
            _failure = failure;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return CallbackShortcuts(
      bindings: {
        // Подтверждение прямо из поля ввода.
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
      },
      child: SLDialog(
        title: 'Добавить адрес',
        // Пока идёт отправка, окно не закрывается ни крестиком, ни `Esc`.
        onClose: _submitting ? null : () => Navigator.of(context).pop(),
        banner: _failure == null
            ? null
            : SLBanner(
                title: 'Не удалось добавить адрес',
                description: 'Проверьте соединение и попробуйте ещё раз.',
                details: _failure!.toString(),
              ),
        actions: [
          SLButton(
            label: 'Отмена',
            variant: SLButtonVariant.secondary,
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          ),
          SLButton(
            label: 'Добавить',
            isLoading: _submitting,
            onPressed: _submit,
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SLTextField(
              controller: _controller,
              focusNode: _focusNode,
              label: 'Email',
              hint: 'ivan@yandex.ru',
              helper:
                  'Адрес из аккаунта Яндекса, которым человек будет входить.',
              errorText: _fieldError,
              readOnly: _submitting,
              autofocus: true,
              maxLength: AccessEmail.maxLength,
              onChanged: _onChanged,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: SLSpacing.space4),
            // Главная защита от путаницы уровней доступа: запись здесь
            // не даёт доступа ни к одному проекту.
            const SLBanner(
              title:
                  'Это откроет вход в трекер, но не даст доступа '
                  'ни к одному проекту',
              description: 'В проект человека добавляют ссылкой-приглашением.',
              variant: SLBannerVariant.info,
            ),
            const SizedBox(height: SLSpacing.space2),
            Text(
              'Регистр не важен: адрес приводится к нижнему регистру.',
              style: text.label.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
