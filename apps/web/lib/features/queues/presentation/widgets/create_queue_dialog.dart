import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/queues/domain/queue_key.dart';
import 'package:sl_tracker_web/features/queues/domain/queue_limits.dart';
import 'package:sl_tracker_web/features/queues/presentation/queue_providers.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_text_field.dart';
import 'package:sl_tracker_web/shared/uikit/overlays/sl_dialog.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Создание очереди (US-30, `docs/design/screens/project.md`).
///
/// Возвращает созданную очередь или `null`, если человек передумал.
///
/// Ключ вводится руками и **больше никогда не меняется** (D-06): из него
/// складываются ключи всех задач очереди, и переименование очереди их
/// не затрагивает. Об этом сказано прямо в форме, а не в тултипе.
class CreateQueueDialog extends ConsumerStatefulWidget {
  /// @nodoc
  const CreateQueueDialog({required this.slug, super.key});

  /// Короткое имя проекта.
  final String slug;

  /// Показывает окно.
  static Future<CreatedQueueDto?> show(BuildContext context, String slug) =>
      showDialog<CreatedQueueDto>(
        context: context,
        builder: (context) => CreateQueueDialog(slug: slug),
      );

  @override
  ConsumerState<CreateQueueDialog> createState() => _CreateQueueDialogState();
}

class _CreateQueueDialogState extends ConsumerState<CreateQueueDialog> {
  final _keyController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _keyFocusNode = FocusNode(debugLabel: 'queue-key');

  String? _keyError;
  String? _nameError;
  ApiFailure? _failure;
  var _key = '';
  var _name = '';
  var _submitting = false;

  static const _emptyNameError = 'Без названия очередь не создать';

  @override
  void dispose() {
    _keyController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _keyFocusNode.dispose();
    super.dispose();
  }

  /// Ключ приводится к допустимому виду прямо в поле: человек печатает
  /// `dev-1`, в поле остаётся `DEV1`. Молча отбрасывать символы честнее,
  /// чем показывать ошибку на каждый дефис.
  void _onKeyChanged(String value) {
    final normalized = QueueKey.normalize(value);

    if (normalized != value) {
      _keyController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }

    setState(() {
      _key = normalized;
      _keyError = null;
      _failure = null;
    });
  }

  void _onNameChanged(String value) => setState(() {
    _name = value;
    _nameError = null;
    _failure = null;
  });

  Future<void> _submit() async {
    if (_submitting) return;

    final key = _key;
    final name = _name.trim();
    final keyError = QueueKey.isValid(key)
        ? null
        : (QueueKey.validationError(key) ?? 'Ключ обязателен');

    if (keyError != null || name.isEmpty) {
      setState(() {
        _keyError = keyError;
        _nameError = name.isEmpty ? _emptyNameError : null;
      });
      if (keyError != null) _keyFocusNode.requestFocus();

      return;
    }

    setState(() {
      _submitting = true;
      _failure = null;
    });

    try {
      final created = await ref
          .read(projectQueuesProvider(widget.slug).notifier)
          .create(
            key: key,
            name: name,
            description: _descriptionController.text.trim(),
          );

      if (mounted) Navigator.of(context).pop(created);
    } on ApiFailure catch (failure) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
        // Данные формы сохраняются: набирать всё заново из-за ответа сервера
        // — издевательство.
        switch ((failure.kind, failure.code)) {
          case (ApiFailureKind.conflict, _):
          case (_, 'queue_key_taken'):
            // Ключ уникален на весь трекер, и ключи удалённых очередей
            // остаются занятыми навсегда (D-25). В каком проекте ключ занят,
            // сервер не сообщает — и правильно делает.
            _keyError = 'Такой ключ уже занят, выберите другой';
          case (_, 'invalid_queue_key'):
            _keyError = 'Сервер не принял этот ключ';
          case (_, 'invalid_queue_name'):
            _nameError = 'Сервер не принял это название';
          default:
            _failure = failure;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = QueueKey.isValid(_key) && _name.trim().isNotEmpty;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
      },
      child: SLDialog(
        title: 'Создать очередь',
        onClose: _submitting ? null : () => Navigator.of(context).pop(),
        banner: _failure == null
            ? null
            : SLBanner(
                title: 'Не удалось создать очередь',
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
            label: 'Создать',
            isLoading: _submitting,
            onPressed: canSubmit ? _submit : null,
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SLTextField(
              controller: _keyController,
              focusNode: _keyFocusNode,
              label: 'Ключ *',
              hint: 'DEV',
              errorText: _keyError,
              readOnly: _submitting,
              autofocus: true,
              maxLength: QueueKey.maxLength,
              onChanged: _onKeyChanged,
            ),
            const SizedBox(height: SLSpacing.space2),
            _KeyNotice(queueKey: _key),
            const SizedBox(height: SLSpacing.space4),
            SLTextField(
              controller: _nameController,
              label: 'Название *',
              errorText: _nameError,
              helper: QueueLimits.shouldCount(_name, QueueLimits.nameMaxLength)
                  ? QueueLimits.counterText(_name, QueueLimits.nameMaxLength)
                  : null,
              readOnly: _submitting,
              maxLength: QueueLimits.nameMaxLength,
              onChanged: _onNameChanged,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: SLSpacing.space4),
            SLTextField.multiline(
              controller: _descriptionController,
              label: 'Описание',
              readOnly: _submitting,
              maxLength: QueueLimits.descriptionMaxLength,
            ),
          ],
        ),
      ),
    );
  }
}

/// Что станет с ключом: из него сложатся ключи задач, и изменить его потом
/// будет нельзя.
class _KeyNotice extends StatelessWidget {
  const _KeyNotice({required this.queueKey});

  final String queueKey;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final sample = queueKey.isEmpty ? 'DEV' : queueKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ключи задач будут такими:',
          style: text.label.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: SLSpacing.space1),
        Text(
          '$sample-1, $sample-2, $sample-3',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.mono.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: SLSpacing.space1),
        Text(
          'Ключ задаётся один раз: переименовать очередь можно, '
          'сменить ключ — нет.',
          style: text.label.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }
}
