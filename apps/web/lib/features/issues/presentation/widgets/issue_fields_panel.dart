import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/core/utils/sl_date_format.dart';
import 'package:sl_tracker_web/features/issues/domain/issue_fields.dart';
import 'package:sl_tracker_web/features/issues/domain/issue_status_ref.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/issue_field_flash.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/issue_fields.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/issue_skeletons.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Действия панели полей. Собраны в один объект: их семь, и таскать семь
/// колбэков через три раскладки — верный способ что-нибудь забыть.
@immutable
class IssueFieldsActions {
  /// @nodoc
  const IssueFieldsActions({
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onStoryPointsChanged,
    required this.onAuthorChanged,
    required this.onAssigneeChanged,
    required this.onAssignToMe,
    required this.onClearAssignee,
  });

  /// @nodoc
  final ValueChanged<IssueStatusRef> onStatusChanged;

  /// @nodoc
  final ValueChanged<int> onPriorityChanged;

  /// @nodoc
  final ValueChanged<int?> onStoryPointsChanged;

  /// @nodoc
  final ValueChanged<IssueUserDto> onAuthorChanged;

  /// @nodoc
  final ValueChanged<IssueUserDto> onAssigneeChanged;

  /// «Назначить на себя» — самое частое действие с этим полем (US-52).
  final VoidCallback onAssignToMe;

  /// @nodoc
  final VoidCallback onClearAssignee;
}

/// Панель полей задачи (`docs/design/screens/issue.md`).
///
/// Поля идут в порядке частоты обращения, а не алфавита: статус, приоритет,
/// сложность, автор, исполнитель — и только потом служебные сведения.
///
/// Видимость контролов определяется флагом `permissions.canEdit`, **а не
/// ролью** (`README.md`, 8.3): у читателя те же поля показываются текстом,
/// без выпадающих списков, и доступное имя у них тоже без слова «изменить».
class IssueFieldsPanel extends StatelessWidget {
  /// @nodoc
  const IssueFieldsPanel({
    required this.issue,
    required this.statuses,
    required this.actions,
    required this.currentUserId,
    this.statusFieldKey,
    this.assigneeFieldKey,
    super.key,
  });

  /// @nodoc
  final IssueDto issue;

  /// Статусы очереди для выпадающего списка.
  final List<IssueStatusRef> statuses;

  /// @nodoc
  final IssueFieldsActions actions;

  /// Кто смотрит: от этого зависит, показывать ли «Назначить на себя».
  final String? currentUserId;

  /// Ключ поля статуса: по нему экран открывает меню хоткеем `s`.
  final GlobalKey<IssueStatusFieldState>? statusFieldKey;

  /// Ключ селектора исполнителя: хоткей `a`.
  final GlobalKey<IssueUserFieldState>? assigneeFieldKey;

  @override
  Widget build(BuildContext context) {
    final canEdit = issue.permissions.canEdit;
    final showAssignToMe =
        canEdit && currentUserId != null && issue.assignee?.id != currentUserId;

    return Semantics(
      container: true,
      label: 'Поля задачи',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IssueFieldLabel('Статус'),
          IssueFieldFlash(
            issueKey: issue.key,
            field: IssueFieldNames.status,
            child: IssueStatusField(
              key: statusFieldKey,
              status: issue.status.ref,
              statuses: statuses,
              enabled: canEdit,
              onChanged: actions.onStatusChanged,
            ),
          ),
          const SizedBox(height: SLSpacing.space4),

          const IssueFieldLabel('Приоритет'),
          IssueFieldFlash(
            issueKey: issue.key,
            field: IssueFieldNames.priority,
            child: IssuePriorityField(
              value: issue.priority.value,
              enabled: canEdit,
              onChanged: actions.onPriorityChanged,
            ),
          ),
          const SizedBox(height: SLSpacing.space4),

          const IssueFieldLabel('Сложность'),
          IssueFieldFlash(
            issueKey: issue.key,
            field: IssueFieldNames.storyPoints,
            child: IssueComplexityField(
              value: issue.storyPoints?.value,
              enabled: canEdit,
              onChanged: actions.onStoryPointsChanged,
            ),
          ),
          const SizedBox(height: SLSpacing.space4),

          // «Создатель» на экране не используется — только «Автор» (D-13).
          const IssueFieldLabel('Автор'),
          IssueFieldFlash(
            issueKey: issue.key,
            field: IssueFieldNames.author,
            child: IssueUserField(
              projectSlug: issue.project.slug,
              user: issue.author,
              enabled: canEdit,
              onChanged: actions.onAuthorChanged,
            ),
          ),
          const SizedBox(height: SLSpacing.space4),

          const IssueFieldLabel('Исполнитель'),
          IssueFieldFlash(
            issueKey: issue.key,
            field: IssueFieldNames.assignee,
            child: IssueUserField(
              key: assigneeFieldKey,
              projectSlug: issue.project.slug,
              user: issue.assignee,
              enabled: canEdit,
              onChanged: actions.onAssigneeChanged,
              onClear: actions.onClearAssignee,
            ),
          ),
          if (showAssignToMe)
            Padding(
              padding: const EdgeInsets.only(top: SLSpacing.space1),
              child: SLButton(
                label: 'Назначить на себя',
                variant: SLButtonVariant.ghost,
                size: SLButtonSize.sm,
                onPressed: actions.onAssignToMe,
              ),
            ),

          const _Divider(),
          IssueMeta(issue: issue),
        ],
      ),
    );
  }
}

/// Служебные сведения: очередь и даты. Не редактируются.
class IssueMeta extends StatelessWidget {
  /// @nodoc
  const IssueMeta({required this.issue, this.inline = false, super.key});

  /// @nodoc
  final IssueDto issue;

  /// Однострочный вид для планшета: очередь и даты в одну строку.
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    final queue = InkWell(
      onTap: () => context.go(AppRoutes.queuePath(issue.queue.key)),
      child: Text(
        'Очередь: ${issue.queue.name}',
        style: text.bodyS.copyWith(color: colors.accent),
      ),
    );

    final created = Tooltip(
      message: SLDateFormat.exact(issue.createdAt),
      child: Text(
        'Создана: ${SLDateFormat.short(issue.createdAt)}',
        style: text.bodyS.copyWith(color: colors.textMuted),
      ),
    );

    final updated = Tooltip(
      message: SLDateFormat.exact(issue.updatedAt),
      child: Text(
        'Изменена: ${_relative(issue.updatedAt)}',
        style: text.bodyS.copyWith(color: colors.textMuted),
      ),
    );

    if (inline) {
      return Wrap(
        spacing: SLSpacing.space3,
        runSpacing: SLSpacing.space1,
        children: [queue, created, updated],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        queue,
        const SizedBox(height: SLSpacing.space1),
        created,
        const SizedBox(height: SLSpacing.space1),
        updated,
      ],
    );
  }

  /// Относительное время: «2 ч назад», дальше суток — дата.
  static String _relative(DateTime moment, {DateTime? now}) {
    final current = (now ?? DateTime.now()).toLocal();
    final elapsed = current.difference(moment.toLocal());

    if (elapsed.inMinutes < 1) return 'только что';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} мин назад';
    if (elapsed.inHours < 24) return '${elapsed.inHours} ч назад';

    return SLDateFormat.short(moment, now: current);
  }
}

/// Горизонтальная лента полей для планшета (`md` 768–1023).
///
/// Панель уезжает наверх, под название: 320 px справа на планшете съедают
/// содержимое, ради которого экран и открывают.
class IssueFieldsBand extends StatelessWidget {
  /// @nodoc
  const IssueFieldsBand({
    required this.issue,
    required this.statuses,
    required this.actions,
    this.statusFieldKey,
    this.assigneeFieldKey,
    super.key,
  });

  /// @nodoc
  final IssueDto issue;

  /// @nodoc
  final List<IssueStatusRef> statuses;

  /// @nodoc
  final IssueFieldsActions actions;

  /// @nodoc
  final GlobalKey<IssueStatusFieldState>? statusFieldKey;

  /// @nodoc
  final GlobalKey<IssueUserFieldState>? assigneeFieldKey;

  /// Минимальная ширина ячейки ленты.
  static const cellWidth = 160.0;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final canEdit = issue.permissions.canEdit;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: SLRadii.mdAll,
        border: Border.all(color: colors.border, width: SLBorders.hairline),
      ),
      padding: const EdgeInsets.all(SLSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: SLSpacing.space6,
            runSpacing: SLSpacing.space3,
            children: [
              _Cell(
                label: 'Статус',
                issueKey: issue.key,
                field: IssueFieldNames.status,
                child: IssueStatusField(
                  key: statusFieldKey,
                  status: issue.status.ref,
                  statuses: statuses,
                  enabled: canEdit,
                  onChanged: actions.onStatusChanged,
                ),
              ),
              _Cell(
                label: 'Приоритет',
                issueKey: issue.key,
                field: IssueFieldNames.priority,
                child: IssuePriorityField(
                  value: issue.priority.value,
                  enabled: canEdit,
                  onChanged: actions.onPriorityChanged,
                ),
              ),
              _Cell(
                label: 'Сложность',
                issueKey: issue.key,
                field: IssueFieldNames.storyPoints,
                child: IssueComplexityField(
                  value: issue.storyPoints?.value,
                  enabled: canEdit,
                  onChanged: actions.onStoryPointsChanged,
                ),
              ),
              _Cell(
                label: 'Автор',
                issueKey: issue.key,
                field: IssueFieldNames.author,
                child: IssueUserField(
                  projectSlug: issue.project.slug,
                  user: issue.author,
                  enabled: canEdit,
                  onChanged: actions.onAuthorChanged,
                ),
              ),
              _Cell(
                label: 'Исполнитель',
                issueKey: issue.key,
                field: IssueFieldNames.assignee,
                child: IssueUserField(
                  key: assigneeFieldKey,
                  projectSlug: issue.project.slug,
                  user: issue.assignee,
                  enabled: canEdit,
                  onChanged: actions.onAssigneeChanged,
                  onClear: actions.onClearAssignee,
                ),
              ),
            ],
          ),
          const SizedBox(height: SLSpacing.space3),
          IssueMeta(issue: issue, inline: true),
        ],
      ),
    );
  }
}

/// Свёрнутый блок полей для телефона (`sm` < 768).
///
/// Статус вынесен **отдельно и всегда развёрнутым**: ради него чаще всего
/// и открывают задачу с телефона.
class IssueFieldsCompact extends StatefulWidget {
  /// @nodoc
  const IssueFieldsCompact({
    required this.issue,
    required this.statuses,
    required this.actions,
    required this.currentUserId,
    this.statusFieldKey,
    this.assigneeFieldKey,
    super.key,
  });

  /// @nodoc
  final IssueDto issue;

  /// @nodoc
  final List<IssueStatusRef> statuses;

  /// @nodoc
  final IssueFieldsActions actions;

  /// @nodoc
  final String? currentUserId;

  /// @nodoc
  final GlobalKey<IssueStatusFieldState>? statusFieldKey;

  /// @nodoc
  final GlobalKey<IssueUserFieldState>? assigneeFieldKey;

  @override
  State<IssueFieldsCompact> createState() => _IssueFieldsCompactState();
}

class _IssueFieldsCompactState extends State<IssueFieldsCompact> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final issue = widget.issue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IssueFieldFlash(
          issueKey: issue.key,
          field: IssueFieldNames.status,
          child: IssueStatusField(
            key: widget.statusFieldKey,
            status: issue.status.ref,
            statuses: widget.statuses,
            enabled: issue.permissions.canEdit,
            onChanged: widget.actions.onStatusChanged,
          ),
        ),
        const SizedBox(height: SLSpacing.space2),
        // Зона нажатия 44 — требование тач-раскладки, а не украшение.
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            constraints: const BoxConstraints(minHeight: SLSizes.touchTarget),
            padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space3),
            decoration: BoxDecoration(
              color: colors.surfaceSunken,
              borderRadius: SLRadii.smAll,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Приоритет ${issue.priority.value} · '
                    'Исполнитель: '
                    '${issue.assignee?.displayName ?? 'не назначен'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyS.copyWith(color: colors.textSecondary),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: SLIconSizes.icon20,
                  color: colors.iconMuted,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(top: SLSpacing.space3),
            child: IssueFieldsPanel(
              issue: issue,
              statuses: widget.statuses,
              actions: widget.actions,
              currentUserId: widget.currentUserId,
              assigneeFieldKey: widget.assigneeFieldKey,
            ),
          ),
      ],
    );
  }
}

/// Панель полей в состоянии загрузки.
class IssueFieldsPanelLoading extends StatelessWidget {
  /// @nodoc
  const IssueFieldsPanelLoading({super.key});

  @override
  Widget build(BuildContext context) => const FieldsPanelSkeleton();
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.issueKey,
    required this.field,
    required this.child,
  });

  final String label;
  final String issueKey;
  final String field;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: IssueFieldsBand.cellWidth,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IssueFieldLabel(label),
        IssueFieldFlash(issueKey: issueKey, field: field, child: child),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: SLSpacing.space4),
    child: Container(
      height: SLBorders.hairline,
      color: SLColorScheme.of(context).borderSubtle,
    ),
  );
}
