import 'package:flutter/material.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/features/projects/presentation/widgets/copy_project_address_button.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_icon_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/effects/sl_shimmering_effect.dart';
import 'package:sl_tracker_web/shared/uikit/media/sl_cover_image.dart';
import 'package:sl_tracker_web/shared/uikit/sl_breakpoints.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Шапка экрана проекта (`docs/design/screens/project.md`).
///
/// Описание в шапке — одна строка; полный текст раскрывается по клику.
/// Markdown в MVP не рендерится (`components.md`, 18.4: отдельная задача
/// с внешней зависимостью), поэтому раскрытый текст показывается как есть,
/// выделяемым.
class ProjectHeader extends StatefulWidget {
  /// @nodoc
  const ProjectHeader({
    required this.project,
    required this.focusNode,
    required this.canManage,
    required this.showAddress,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  /// Проект.
  final ProjectDto project;

  /// Фокус на названии: при входе на экран он встаёт сюда.
  final FocusNode focusNode;

  /// Показывать ли меню «⋯». У участника и читателя его нет вовсе.
  final bool canManage;

  /// Показывать ли «Скопировать адрес».
  ///
  /// Обычно да — кнопка доступна всем участникам, включая читателя (US-13).
  /// Исключение одно: открыта вкладка «Приглашения». D-04 требует, чтобы
  /// адрес проекта и ссылка-приглашение **никогда не были видны
  /// одновременно**, иначе человек копирует не то, что думает, и раздаёт
  /// членство в проекте. Раскладка спеки держит кнопку в шапке всегда,
  /// и это единственное место, где два её требования расходятся;
  /// выбрано то, которое про безопасность.
  final bool showAddress;

  /// «Изменить проект» — переход на вкладку настроек.
  final VoidCallback onEdit;

  /// «Удалить проект».
  final VoidCallback onDelete;

  /// Высота шапки на десктопе.
  static const height = 96.0;

  /// Высота шапки на телефоне.
  static const compactHeight = 72.0;

  /// Ширина обложки на десктопе.
  static const coverWidth = 96.0;

  /// Ширина обложки на телефоне.
  static const compactCoverWidth = 64.0;

  /// Соотношение сторон обложки.
  static const coverAspectRatio = 16 / 9;

  @override
  State<ProjectHeader> createState() => _ProjectHeaderState();
}

class _ProjectHeaderState extends State<ProjectHeader> {
  var _descriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final breakpoint = SLBreakpoint.of(context);
    final isPhone = breakpoint.isPhone;
    final project = widget.project;
    final coverWidth = isPhone
        ? ProjectHeader.compactCoverWidth
        : ProjectHeader.coverWidth;
    final description = project.description?.trim() ?? '';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.border, width: SLBorders.hairline),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: isPhone
                ? ProjectHeader.compactHeight
                : ProjectHeader.height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space4),
              child: Row(
                children: [
                  SLCoverImage(
                    projectId: project.id,
                    projectName: project.name,
                    coverUrl: project.coverUrl,
                    width: coverWidth,
                    height: coverWidth / ProjectHeader.coverAspectRatio,
                    borderRadius: SLRadii.smAll,
                  ),
                  const SizedBox(width: SLSpacing.space3),
                  Expanded(
                    child: _buildTitle(
                      colors,
                      SLTextScheme.of(context),
                      description,
                      isPhone: isPhone,
                    ),
                  ),
                  const SizedBox(width: SLSpacing.space3),
                  _buildActions(breakpoint),
                ],
              ),
            ),
          ),
          if (_descriptionExpanded && description.isNotEmpty)
            _ExpandedDescription(description: description),
        ],
      ),
    );
  }

  Widget _buildTitle(
    SLColorScheme colors,
    SLTextScheme text,
    String description, {
    required bool isPhone,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Focus(
          focusNode: widget.focusNode,
          child: Semantics(
            header: true,
            child: Tooltip(
              message: widget.project.name,
              child: Text(
                widget.project.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.h2.copyWith(color: colors.textPrimary),
              ),
            ),
          ),
        ),
        if (description.isNotEmpty && !isPhone) ...[
          const SizedBox(height: SLSpacing.space1),
          Semantics(
            button: true,
            label: _descriptionExpanded
                ? 'Свернуть описание проекта'
                : 'Показать описание проекта целиком',
            excludeSemantics: true,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(
                  () => _descriptionExpanded = !_descriptionExpanded,
                ),
                child: Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyS.copyWith(color: colors.textMuted),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions(SLBreakpoint breakpoint) {
    // «Скопировать адрес» остаётся у всех участников, включая читателя
    // (US-13): это не действие над проектом, а способ дать ссылку.
    final copy = widget.showAddress
        ? CopyProjectAddressButton(
            slug: widget.project.slug,
            compact: !breakpoint.isDesktop,
          )
        : const SizedBox.shrink();

    if (!widget.canManage) return copy;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        copy,
        if (widget.showAddress) const SizedBox(width: SLSpacing.space2),
        _ProjectMenu(onEdit: widget.onEdit, onDelete: widget.onDelete),
      ],
    );
  }
}

/// Меню «⋯» шапки. Только администратору.
class _ProjectMenu extends StatelessWidget {
  const _ProjectMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          onPressed: onEdit,
          child: Text(
            'Изменить проект',
            style: text.bodyS.copyWith(color: colors.textPrimary),
          ),
        ),
        MenuItemButton(
          onPressed: onDelete,
          child: Text(
            'Удалить проект',
            style: text.bodyS.copyWith(color: colors.danger),
          ),
        ),
      ],
      builder: (context, controller, child) => SLIconButton(
        icon: Icons.more_horiz_rounded,
        tooltip: 'Действия с проектом',
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// Раскрытое описание проекта под шапкой.
class _ExpandedDescription extends StatelessWidget {
  const _ExpandedDescription({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SLSpacing.space4,
        0,
        SLSpacing.space4,
        SLSpacing.space4,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: SLSizes.readableTextWidth),
        // В вебе текст ожидают выделять и копировать.
        child: SelectionArea(
          child: Text(
            description,
            style: text.body.copyWith(color: colors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Скелетон шапки: геометрия реального контента, без прыжка при загрузке.
class ProjectHeaderSkeleton extends StatelessWidget {
  /// @nodoc
  const ProjectHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final isPhone = SLBreakpoint.of(context).isPhone;
    final coverWidth = isPhone
        ? ProjectHeader.compactCoverWidth
        : ProjectHeader.coverWidth;

    return Container(
      height: isPhone ? ProjectHeader.compactHeight : ProjectHeader.height,
      padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space4),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.border, width: SLBorders.hairline),
        ),
      ),
      child: SLShimmeringEffect(
        child: Row(
          children: [
            SLSkeletonBox(
              width: coverWidth,
              height: coverWidth / ProjectHeader.coverAspectRatio,
            ),
            const SizedBox(width: SLSpacing.space3),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SLSkeletonLine(width: 200, height: 20),
                SizedBox(height: SLSpacing.space2),
                SLSkeletonLine(width: 320, height: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Кнопка «Создать очередь» и подобные ей на вкладках.
///
/// Вынесена сюда, чтобы вкладки не собирали одну и ту же кнопку по-разному.
class ProjectTabAction extends StatelessWidget {
  /// @nodoc
  const ProjectTabAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  /// @nodoc
  final String label;

  /// @nodoc
  final IconData icon;

  /// @nodoc
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isPhone = SLBreakpoint.of(context).isPhone;

    return Align(
      alignment: isPhone ? Alignment.center : Alignment.centerRight,
      child: SLButton(
        label: label,
        icon: icon,
        expand: isPhone,
        onPressed: onPressed,
      ),
    );
  }
}
