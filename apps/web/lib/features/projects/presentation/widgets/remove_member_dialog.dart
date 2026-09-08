import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/projects/presentation/project_providers.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/overlays/sl_dialog.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Исключение участника или самостоятельный выход (US-16).
///
/// Возвращает число задач, у которых очистился исполнитель, — сервер считает
/// его в той же транзакции (D-31). `null` означает «передумали».
///
/// Модалка называет последствие до действия: задачи исключённого остаются,
/// но поле «Исполнитель» в них очищается. Точное число заранее неизвестно —
/// его знает только сервер, — поэтому оно приходит после и попадает в тост.
class RemoveMemberDialog extends ConsumerStatefulWidget {
  /// @nodoc
  const RemoveMemberDialog({
    required this.slug,
    required this.member,
    super.key,
  });

  /// Короткое имя проекта.
  final String slug;

  /// Кого исключаем.
  final ProjectMemberDto member;

  /// Показывает окно.
  static Future<int?> show(
    BuildContext context, {
    required String slug,
    required ProjectMemberDto member,
  }) => showDialog<int>(
    context: context,
    builder: (context) => RemoveMemberDialog(slug: slug, member: member),
  );

  @override
  ConsumerState<RemoveMemberDialog> createState() => _RemoveMemberDialogState();
}

class _RemoveMemberDialogState extends ConsumerState<RemoveMemberDialog> {
  /// Фокус на «Отмена»: у опасного подтверждения `Enter` не должен исключать.
  final _cancelFocusNode = FocusNode(debugLabel: 'remove-member-cancel');

  ApiFailure? _failure;
  var _submitting = false;

  bool get _isSelf => widget.member.isSelf;

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
      final unassigned = await ref
          .read(projectMembersProvider(widget.slug).notifier)
          .remove(widget.member.userId);

      if (mounted) Navigator.of(context).pop(unassigned);
    } on ApiFailure catch (failure) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
        _failure = failure;
      });
    }
  }

  (String, String) _errorTextOf(ApiFailure failure) =>
      switch ((failure.kind, failure.code)) {
        (_, 'last_project_admin') => (
          'В проекте должен остаться хотя бы один администратор',
          'Сначала назначьте администратором кого-то ещё.',
        ),
        (ApiFailureKind.forbidden, _) => (
          'Недостаточно прав',
          'Похоже, вашу роль в проекте изменили. Обновите страницу.',
        ),
        (ApiFailureKind.notFound, _) => (
          'Участника или проекта больше нет',
          'Обновите страницу, чтобы увидеть актуальный список.',
        ),
        _ => ('Не удалось выполнить действие', 'Попробуйте ещё раз.'),
      };

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final failure = _failure;
    final name = widget.member.displayName;

    return SLDialog(
      title: _isSelf ? 'Выйти из проекта?' : 'Исключить $name из проекта?',
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
          label: _isSelf ? 'Выйти' : 'Исключить',
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
          _Consequence(
            _isSelf
                ? 'вы потеряете доступ к задачам и обсуждениям проекта;'
                : '$name потеряет доступ к задачам и обсуждениям проекта;',
          ),
          _Consequence(
            _isSelf
                ? 'задачи, где вы исполнитель, останутся без исполнителя;'
                : 'задачи, где $name исполнитель, останутся без исполнителя;',
          ),
          const _Consequence(
            'созданные задачи, комментарии и история сохранятся.',
          ),
          const SizedBox(height: SLSpacing.space4),
          Text(
            _isSelf
                ? 'Вернуться в проект можно будет только по новой '
                      'ссылке-приглашению.'
                : 'Вернуть человека в проект можно новой ссылкой-приглашением.',
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
