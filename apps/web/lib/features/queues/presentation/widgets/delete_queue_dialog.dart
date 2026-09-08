import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/queues/presentation/queue_providers.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/overlays/sl_dialog.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Удаление очереди (US-34, D-24).
///
/// Удалить можно **только пустую** очередь: при наличии хотя бы одной задачи
/// сервер отвечает 409, и окно превращается в отказ «Сначала удалите задачи
/// очереди». Каскадного удаления задач нет и не будет — оно необратимо
/// уничтожало бы работу команды одним нажатием.
///
/// Счётчик в строке очереди показывает только **незавершённые** задачи,
/// поэтому «0 задач» не означает «пустая»: закрытые задачи тоже держат
/// очередь. Спросить об этом заранее клиенту нечем — узнаём из ответа.
class DeleteQueueDialog extends ConsumerStatefulWidget {
  /// @nodoc
  const DeleteQueueDialog({required this.slug, required this.queue, super.key});

  /// Короткое имя проекта.
  final String slug;

  /// Очередь.
  final QueueDto queue;

  /// Показывает окно. Возвращает `true`, если очередь удалена.
  static Future<bool?> show(
    BuildContext context, {
    required String slug,
    required QueueDto queue,
  }) => showDialog<bool>(
    context: context,
    builder: (context) => DeleteQueueDialog(slug: slug, queue: queue),
  );

  @override
  ConsumerState<DeleteQueueDialog> createState() => _DeleteQueueDialogState();
}

class _DeleteQueueDialogState extends ConsumerState<DeleteQueueDialog> {
  var _submitting = false;
  var _notEmpty = false;
  ApiFailure? _failure;

  Future<void> _delete() async {
    if (_submitting) return;

    setState(() {
      _submitting = true;
      _failure = null;
    });

    try {
      await ref
          .read(projectQueuesProvider(widget.slug).notifier)
          .remove(widget.queue.key);

      if (mounted) Navigator.of(context).pop(true);
    } on ApiFailure catch (failure) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
        if (failure.kind == ApiFailureKind.conflict ||
            failure.code == 'queue_not_empty') {
          _notEmpty = true;
        } else {
          _failure = failure;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final queue = widget.queue;

    return SLDialog(
      title: _notEmpty ? 'Очередь не пуста' : 'Удалить очередь?',
      width: SLSizes.dialogSm,
      onClose: _submitting ? null : () => Navigator.of(context).pop(),
      actions: _notEmpty
          ? [
              SLButton(
                label: 'Понятно',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]
          : [
              SLButton(
                label: 'Отмена',
                variant: SLButtonVariant.secondary,
                onPressed: _submitting
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
              SLButton(
                label: 'Удалить',
                variant: SLButtonVariant.danger,
                isLoading: _submitting,
                onPressed: _delete,
              ),
            ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _notEmpty
                ? 'Сначала удалите задачи очереди «${queue.name}». '
                      'Вместе с очередью задачи не удаляются.'
                : 'Очередь «${queue.name}» (${queue.key}) будет удалена. '
                      'Удалить можно только пустую очередь.',
            style: text.body.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: SLSpacing.space3),
          Text(
            'Ключ ${queue.key} останется занятым навсегда и другой очереди '
            'не достанется: иначе старая ссылка на задачу открыла бы '
            'совсем другую задачу.',
            style: text.label.copyWith(color: colors.textMuted),
          ),
          if (_failure != null) ...[
            const SizedBox(height: SLSpacing.space3),
            Text(
              'Не удалось удалить очередь. Проверьте соединение '
              'и попробуйте ещё раз.',
              style: text.bodyS.copyWith(color: colors.danger),
            ),
          ],
        ],
      ),
    );
  }
}
