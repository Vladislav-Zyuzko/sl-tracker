import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/queues/domain/queue_limits.dart';
import 'package:sl_tracker_web/features/queues/presentation/queue_providers.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_text_field.dart';
import 'package:sl_tracker_web/shared/uikit/overlays/sl_dialog.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Переименование очереди (US-33).
///
/// Меняются название и описание. **Ключ не меняется никогда** (D-06):
/// поле ключа показано только для чтения, и рядом сказано почему — иначе
/// человек будет искать, где его редактировать.
class RenameQueueDialog extends ConsumerStatefulWidget {
  /// @nodoc
  const RenameQueueDialog({required this.slug, required this.queue, super.key});

  /// Короткое имя проекта: через него правится список очередей.
  final String slug;

  /// Очередь.
  final QueueDto queue;

  /// Показывает окно. Возвращает обновлённую очередь или `null`.
  static Future<QueueDto?> show(
    BuildContext context, {
    required String slug,
    required QueueDto queue,
  }) => showDialog<QueueDto>(
    context: context,
    builder: (context) => RenameQueueDialog(slug: slug, queue: queue),
  );

  @override
  ConsumerState<RenameQueueDialog> createState() => _RenameQueueDialogState();
}

class _RenameQueueDialogState extends ConsumerState<RenameQueueDialog> {
  late final _nameController = TextEditingController(text: widget.queue.name);
  late final _descriptionController = TextEditingController(
    text: widget.queue.description ?? '',
  );

  late var _name = widget.queue.name;

  String? _nameError;
  ApiFailure? _failure;
  var _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) => setState(() {
    _name = value;
    _nameError = null;
    _failure = null;
  });

  Future<void> _submit() async {
    if (_submitting) return;

    final name = _name.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Без названия очередь не сохранить');

      return;
    }

    setState(() {
      _submitting = true;
      _failure = null;
    });

    try {
      final updated = await ref
          .read(projectQueuesProvider(widget.slug).notifier)
          .rename(
            widget.queue.key,
            name: name,
            description: _descriptionController.text.trim(),
          );

      if (mounted) Navigator.of(context).pop(updated);
    } on ApiFailure catch (failure) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
        switch ((failure.kind, failure.code)) {
          case (_, 'invalid_queue_name'):
            _nameError = 'Сервер не принял это название';
          case (ApiFailureKind.notFound, _):
            _failure = failure;
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
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
      },
      child: SLDialog(
        title: 'Изменить очередь',
        onClose: _submitting ? null : () => Navigator.of(context).pop(),
        banner: _failure == null
            ? null
            : SLBanner(
                title: 'Не удалось сохранить очередь',
                description: _failure!.kind == ApiFailureKind.notFound
                    ? 'Возможно, очередь удалили в другой вкладке.'
                    : 'Проверьте соединение и попробуйте ещё раз.',
                details: _failure!.toString(),
              ),
        actions: [
          SLButton(
            label: 'Отмена',
            variant: SLButtonVariant.secondary,
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          ),
          SLButton(
            label: 'Сохранить',
            isLoading: _submitting,
            onPressed: _name.trim().isEmpty ? null : _submit,
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ключ', style: text.label.copyWith(color: colors.textMuted)),
            const SizedBox(height: SLSpacing.space1),
            Text(
              widget.queue.key,
              style: text.mono.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: SLSpacing.space1),
            Text(
              'Ключ не меняется: он уже в ключах задач очереди.',
              style: text.label.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: SLSpacing.space4),
            SLTextField(
              controller: _nameController,
              label: 'Название *',
              errorText: _nameError,
              helper: QueueLimits.shouldCount(_name, QueueLimits.nameMaxLength)
                  ? QueueLimits.counterText(_name, QueueLimits.nameMaxLength)
                  : null,
              readOnly: _submitting,
              autofocus: true,
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
