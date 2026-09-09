import 'package:flutter/material.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/domain/issue_priority.dart';
import 'package:sl_tracker_web/core/utils/sl_date_format.dart';
import 'package:sl_tracker_web/shared/uikit/avatars/sl_avatar.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Названия полей в истории.
///
/// Совпадают с подписями в панели полей и с глоссарием (US-92): «Сложность»,
/// а не «story points», «Автор», а не «Создатель».
///
/// Незнакомый вид изменения не роняет экран и не исчезает — он читается как
/// «изменил поле» с самим кодом: клиент не обязан знать о поле, которого
/// ещё не было, когда его собирали (`components.md`, 21).
String historyActionLabel(IssueHistoryChangeDtoKind kind) => switch (kind) {
  IssueHistoryChangeDtoKind.issueCreated => 'создал задачу',
  IssueHistoryChangeDtoKind.titleChanged => 'изменил название',
  IssueHistoryChangeDtoKind.descriptionChanged => 'изменил описание',
  IssueHistoryChangeDtoKind.statusChanged => 'изменил статус',
  IssueHistoryChangeDtoKind.priorityChanged => 'изменил приоритет',
  IssueHistoryChangeDtoKind.storyPointsChanged => 'изменил сложность',
  IssueHistoryChangeDtoKind.authorChanged => 'изменил автора',
  IssueHistoryChangeDtoKind.assigneeChanged => 'изменил исполнителя',
  IssueHistoryChangeDtoKind.attachmentAdded => 'приложил файл',
  IssueHistoryChangeDtoKind.attachmentRemoved => 'удалил файл',
  IssueHistoryChangeDtoKind.linkAdded => 'добавил ссылку',
  IssueHistoryChangeDtoKind.linkRemoved => 'удалил ссылку',
  IssueHistoryChangeDtoKind.commentDeleted => 'удалил комментарий',
  IssueHistoryChangeDtoKind.$unknown => 'изменил поле',
};

/// Пустое значение словами, а не пустой строкой (US-91).
///
/// «не назначен» и «не оценено» — разные слова для разных полей: одно общее
/// «пусто» читалось бы как ошибка выгрузки.
String historyValueLabel(String? value, IssueHistoryChangeDtoKind kind) {
  if (value != null && value.isNotEmpty) {
    return value.length > _valueLimit
        ? '${value.substring(0, _valueLimit)}…'
        : value;
  }

  return switch (kind) {
    IssueHistoryChangeDtoKind.assigneeChanged => 'не назначен',
    IssueHistoryChangeDtoKind.storyPointsChanged => 'не оценено',
    _ => 'пусто',
  };
}

/// Длинное значение обрезается, полное — в тултипе.
const _valueLimit = 120;

/// Одна группа изменений (`docs/design/components.md`, 21).
///
/// Группировать нечего: сервер уже прислал одно действие одной группой
/// с общим временем и автором (US-90).
class HistoryGroupRow extends StatefulWidget {
  /// @nodoc
  const HistoryGroupRow({required this.group, super.key});

  /// @nodoc
  final IssueHistoryGroupDto group;

  @override
  State<HistoryGroupRow> createState() => _HistoryGroupRowState();
}

class _HistoryGroupRowState extends State<HistoryGroupRow> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final actor = widget.group.actor;
    final actorName = actor?.displayName ?? 'Система';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        color: _hovered ? colors.surfaceHover : null,
        padding: const EdgeInsets.symmetric(
          horizontal: SLSpacing.space2,
          vertical: SLSpacing.space1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Системное изменение — иконка вместо аватара: приписывать его
            // случайному человеку нельзя (US-91).
            if (actor == null)
              Icon(
                Icons.settings_rounded,
                size: SLAvatarSize.xs.diameter,
                color: colors.iconMuted,
              )
            else
              SLAvatar(
                userId: actor.id,
                fullName: actor.displayName,
                photoUrl: actor.avatarUrl,
                decorative: true,
              ),
            const SizedBox(width: SLSpacing.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final change in widget.group.changes)
                    _ChangeLine(actorName: actorName, change: change),
                ],
              ),
            ),
            const SizedBox(width: SLSpacing.space2),
            Tooltip(
              message: SLDateFormat.exact(widget.group.createdAt),
              child: Text(
                _shortTime(widget.group.createdAt),
                style: text.label.copyWith(color: colors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _shortTime(DateTime moment) {
    final local = moment.toLocal();

    return '${SLDateFormat.short(local)}, '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

/// Одна строка изменения: кто, что, из чего во что.
class _ChangeLine extends StatelessWidget {
  const _ChangeLine({required this.actorName, required this.change});

  final String actorName;
  final IssueHistoryChangeDto change;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    // Значения не показываются там, где их нет: у создания задачи и
    // у изменения описания. Diff в MVP не хранится, раскрытия здесь нет
    // намеренно (US-91).
    final showValues =
        change.kind != IssueHistoryChangeDtoKind.issueCreated &&
        change.kind != IssueHistoryChangeDtoKind.descriptionChanged &&
        (change.oldValue != null || change.newValue != null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: SLSpacing.space1,
        children: [
          Text(
            actorName,
            style: text.bodySStrong.copyWith(color: colors.textPrimary),
          ),
          Text(
            historyActionLabel(change.kind),
            style: text.bodyS.copyWith(color: colors.textSecondary),
          ),
          if (showValues) ...[
            _Value(text: historyValueLabel(change.oldValue, change.kind)),
            Icon(
              Icons.arrow_forward_rounded,
              size: SLIconSizes.icon12,
              color: colors.iconMuted,
            ),
            _Value(text: historyValueLabel(change.newValue, change.kind)),
          ],
          if (change.kind == IssueHistoryChangeDtoKind.priorityChanged)
            _PriorityHint(value: change.newValue),
        ],
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final scheme = SLTextScheme.of(context);

    return Tooltip(
      message: text,
      child: Text(
        text,
        style: scheme.bodyS.copyWith(color: colors.textPrimary),
      ),
    );
  }
}

/// Название диапазона рядом с числом приоритета: «80» само по себе
/// ни о чём не говорит (D-32).
class _PriorityHint extends StatelessWidget {
  const _PriorityHint({required this.value});

  final String? value;

  @override
  Widget build(BuildContext context) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null) return const SizedBox.shrink();

    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Text(
      '· ${PriorityRange.of(parsed).label}',
      style: text.label.copyWith(color: colors.textMuted),
    );
  }
}
