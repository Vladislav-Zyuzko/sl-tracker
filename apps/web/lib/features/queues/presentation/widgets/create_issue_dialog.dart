import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/issues/data/issues_repository.dart';
import 'package:sl_tracker_web/features/queues/domain/queue_limits.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_text_field.dart';
import 'package:sl_tracker_web/shared/uikit/overlays/sl_dialog.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Создание задачи в очереди (US-40, US-42).
///
/// Обязательное поле одно — тема. Остальное сервер проставляет сам: первый
/// статус очереди, приоритет 50, автор — создатель, исполнитель не назначен
/// (D-13, D-15, D-16). Клиент эти умолчания не дублирует: два источника
/// умолчаний рано или поздно разойдутся.
///
/// **Отдельной спеки у этого окна нет.** Полей ровно столько, сколько нужно,
/// чтобы задача появилась; выбор исполнителя, приоритета и сложности живёт
/// на странице задачи, которую делают отдельно.
class CreateIssueDialog extends ConsumerStatefulWidget {
  /// @nodoc
  const CreateIssueDialog({required this.queueKey, super.key});

  /// Ключ очереди.
  final String queueKey;

  /// Показывает окно. Возвращает созданную задачу или `null`.
  static Future<IssueDto?> show(BuildContext context, String queueKey) =>
      showDialog<IssueDto>(
        context: context,
        builder: (context) => CreateIssueDialog(queueKey: queueKey),
      );

  @override
  ConsumerState<CreateIssueDialog> createState() => _CreateIssueDialogState();
}

class _CreateIssueDialogState extends ConsumerState<CreateIssueDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocusNode = FocusNode(debugLabel: 'issue-title');

  String? _titleError;
  ApiFailure? _failure;
  var _title = '';
  var _submitting = false;

  static const _emptyTitleError = 'Без темы задачу не создать';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _onTitleChanged(String value) => setState(() {
    _title = value;
    _titleError = null;
    _failure = null;
  });

  Future<void> _submit() async {
    if (_submitting) return;

    final title = _title.trim();
    if (title.isEmpty) {
      setState(() => _titleError = _emptyTitleError);
      _titleFocusNode.requestFocus();

      return;
    }

    setState(() {
      _submitting = true;
      _failure = null;
    });

    try {
      final created = await ref
          .read(issuesRepositoryProvider)
          .create(
            widget.queueKey,
            title: title,
            description: _descriptionController.text.trim(),
          );

      if (mounted) Navigator.of(context).pop(created);
    } on ApiFailure catch (failure) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
        switch ((failure.kind, failure.code)) {
          case (_, 'invalid_issue_title'):
            _titleError = 'Сервер не принял эту тему';
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
        title: 'Создать задачу',
        onClose: _submitting ? null : () => Navigator.of(context).pop(),
        banner: _failure == null
            ? null
            : SLBanner(
                title: 'Не удалось создать задачу',
                description: switch (_failure!.kind) {
                  ApiFailureKind.forbidden =>
                    'Создавать задачи в этой очереди могут только '
                        'участники проекта.',
                  ApiFailureKind.notFound =>
                    'Очереди больше нет — возможно, её удалили '
                        'в другой вкладке.',
                  _ => 'Проверьте соединение и попробуйте ещё раз.',
                },
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
            onPressed: _title.trim().isEmpty ? null : _submit,
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SLTextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              label: 'Тема *',
              errorText: _titleError,
              helper:
                  QueueLimits.shouldCount(
                    _title,
                    QueueLimits.issueTitleMaxLength,
                  )
                  ? QueueLimits.counterText(
                      _title,
                      QueueLimits.issueTitleMaxLength,
                    )
                  : null,
              readOnly: _submitting,
              autofocus: true,
              maxLength: QueueLimits.issueTitleMaxLength,
              onChanged: _onTitleChanged,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: SLSpacing.space4),
            SLTextField.multiline(
              controller: _descriptionController,
              label: 'Описание',
              helper: 'Markdown',
              readOnly: _submitting,
              maxLength: QueueLimits.issueDescriptionMaxLength,
            ),
            const SizedBox(height: SLSpacing.space3),
            Text(
              'Ключ, статус и автора проставит сервер: задача получит '
              'следующий номер очереди ${widget.queueKey} и первый статус.',
              style: text.label.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
