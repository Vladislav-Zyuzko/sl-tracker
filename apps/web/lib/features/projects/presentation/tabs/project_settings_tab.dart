import 'package:flutter/material.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/features/projects/presentation/widgets/project_cover_section.dart';
import 'package:sl_tracker_web/features/projects/presentation/widgets/project_details_section.dart';
import 'package:sl_tracker_web/features/projects/presentation/widgets/project_slug_section.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Вкладка «Настройки» (`docs/design/screens/project.md`).
///
/// Видна только администратору. Секции идут сверху вниз в порядке частоты
/// обращения, а опасная зона — последней и отделена явно.
class ProjectSettingsTab extends StatelessWidget {
  /// @nodoc
  const ProjectSettingsTab({
    required this.project,
    required this.onSlugChanged,
    required this.onDelete,
    super.key,
  });

  /// Проект.
  final ProjectDto project;

  /// Короткое имя изменилось — экран заменяет адрес в строке браузера.
  final ValueChanged<String> onSlugChanged;

  /// Удаление проекта.
  final VoidCallback onDelete;

  /// Ширина колонки настроек: формы шире читать неудобно.
  static const contentWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: contentWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SectionTitle('Название и описание'),
            ProjectDetailsSection(project: project),
            const SizedBox(height: SLSpacing.space8),
            const _SectionTitle('Обложка'),
            ProjectCoverSection(project: project),
            const SizedBox(height: SLSpacing.space8),
            const _SectionTitle('Короткое имя в адресе'),
            ProjectSlugSection(project: project, onChanged: onSlugChanged),
            const SizedBox(height: SLSpacing.space8),
            _DangerZone(project: project, onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}

/// Заголовок секции.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: SLSpacing.space3),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: text.title.copyWith(color: colors.textPrimary),
        ),
      ),
    );
  }
}

/// Опасная зона: удаление проекта.
class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.project, required this.onDelete});

  final ProjectDto project;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Container(
      padding: const EdgeInsets.only(top: SLSpacing.space6),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.border, width: SLBorders.hairline),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Удаление проекта',
              style: text.title.copyWith(color: colors.danger),
            ),
          ),
          const SizedBox(height: SLSpacing.space2),
          Text(
            'Удаляются очереди, задачи, комментарии и вложения. '
            'Отменить это нельзя.',
            style: text.body.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: SLSpacing.space3),
          SLButton(
            label: 'Удалить проект',
            variant: SLButtonVariant.danger,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
