import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/projects/presentation/project_providers.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/inputs/sl_text_field.dart';
import 'package:sl_tracker_web/shared/uikit/overlays/sl_dialog.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Удаление проекта (US-17).
///
/// Возвращает `true`, если проект удалён.
///
/// Кнопка неактивна, пока не введено точное название: это не бюрократия,
/// а единственная защита от необратимого действия. Фокус при открытии —
/// на поле ввода, а не на кнопке.
class DeleteProjectDialog extends ConsumerStatefulWidget {
  /// @nodoc
  const DeleteProjectDialog({required this.project, super.key});

  /// Проект.
  final ProjectDto project;

  /// Показывает окно.
  static Future<bool?> show(BuildContext context, ProjectDto project) =>
      showDialog<bool>(
        context: context,
        builder: (context) => DeleteProjectDialog(project: project),
      );

  @override
  ConsumerState<DeleteProjectDialog> createState() =>
      _DeleteProjectDialogState();
}

class _DeleteProjectDialogState extends ConsumerState<DeleteProjectDialog> {
  final _controller = TextEditingController();

  ApiFailure? _failure;
  var _confirmation = '';
  var _submitting = false;

  /// Введено точно название проекта. Регистр и лишние пробелы по краям
  /// прощаем: это защита от невнимательности, а не экзамен по набору текста.
  bool get _isConfirmed =>
      _confirmation.trim().toLowerCase() ==
      widget.project.name.trim().toLowerCase();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_isConfirmed) return;

    setState(() {
      _submitting = true;
      _failure = null;
    });

    try {
      await ref.read(projectProvider(widget.project.slug).notifier).remove();

      if (mounted) Navigator.of(context).pop(true);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final failure = _failure;

    return SLDialog(
      title: 'Удалить проект «${widget.project.name}»?',
      onClose: _submitting ? null : () => Navigator.of(context).pop(),
      banner: failure == null
          ? null
          : SLBanner(
              title: 'Не удалось удалить проект',
              description: failure.kind == ApiFailureKind.forbidden
                  ? 'Похоже, вашу роль в проекте изменили.'
                  : 'Проверьте соединение и попробуйте ещё раз.',
              details: failure.toString(),
            ),
      actions: [
        SLButton(
          label: 'Отмена',
          variant: SLButtonVariant.secondary,
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
        ),
        Semantics(
          button: true,
          label: 'Удалить проект, необратимо',
          child: SLButton(
            label: 'Удалить проект',
            variant: SLButtonVariant.danger,
            isLoading: _submitting,
            onPressed: _isConfirmed ? _submit : null,
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Будут удалены безвозвратно:',
            style: text.bodyStrong.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: SLSpacing.space2),
          const _Consequence('все очереди проекта;'),
          const _Consequence('все задачи со статусами и историей;'),
          const _Consequence('все комментарии;'),
          const _Consequence('все вложения.'),
          const SizedBox(height: SLSpacing.space3),
          Text(
            'Ключи очередей и прежние адреса проекта останутся занятыми '
            'и повторно не выдаются.',
            style: text.body.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: SLSpacing.space4),
          SLTextField(
            controller: _controller,
            label: 'Введите название проекта для подтверждения',
            hint: widget.project.name,
            readOnly: _submitting,
            // Фокус при открытии — на поле, а не на кнопке.
            autofocus: true,
            onChanged: (value) => setState(() => _confirmation = value),
            onSubmitted: (_) => _submit(),
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
