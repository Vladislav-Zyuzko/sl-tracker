import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/features/projects/domain/project_role.dart';
import 'package:sl_tracker_web/shared/uikit/avatars/sl_avatar_group.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/focus/sl_focus_ring.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_role_badge.dart';
import 'package:sl_tracker_web/shared/uikit/media/sl_cover_image.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/sl_motion.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Карточка проекта (`docs/design/screens/projects.md`).
///
/// Тени нет намеренно: тень означает всплытие над контентом (`system.md`,
/// 10.7), а карточка лежит в общем потоке. Наведение отмечается границей
/// и лёгким увеличением обложки.
class ProjectCard extends StatefulWidget {
  /// @nodoc
  const ProjectCard({
    required this.project,
    required this.onOpen,
    required this.onOpenInNewTab,
    this.width = ProjectCard.defaultWidth,
    super.key,
  });

  /// Проект.
  final ProjectDto project;

  /// Открыть проект в этой вкладке.
  final VoidCallback onOpen;

  /// `Ctrl/Cmd + клик` и средний клик: в вебе это привычка.
  final VoidCallback onOpenInNewTab;

  /// Ширина карточки. На телефоне карточка занимает всю ширину колонки.
  final double width;

  /// Ширина карточки на десктопе.
  static const defaultWidth = 280.0;

  /// Высота обложки при [defaultWidth] — соотношение 16:9.
  static const coverAspectRatio = 16 / 9;

  /// Высота строки названия.
  static const titleHeight = 22.0;

  /// Высота описания: ровно две строки `bodyS` (13/18).
  static const descriptionHeight = 36.0;

  /// Высота подвала с аватарами и бейджем роли.
  static const footerHeight = 28.0;

  /// Высота обложки при [defaultWidth].
  static const defaultCoverHeight = defaultWidth / coverAspectRatio;

  /// Высота карточки при [defaultWidth].
  ///
  /// Спека называет 268; здесь 269.5, и расхождение не случайно: 16:9
  /// от 280 — это 157.5, а не 158, плюс по пикселю границы сверху и снизу.
  /// Значение считается, а не округляется, потому что оно же идёт
  /// в `mainAxisExtent` ленивой сетки — там ошибка в полтора пикселя
  /// накапливается построчно.
  static const defaultHeight =
      defaultCoverHeight +
      titleHeight +
      descriptionHeight +
      footerHeight +
      SLSpacing.space3 * 2 +
      SLBorders.hairline * 2;

  /// Насколько увеличивается обложка при наведении.
  static const coverHoverScale = 1.02;

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  var _hovered = false;
  var _focused = false;
  var _pressed = false;

  /// `Ctrl` (или `Cmd` на macOS) в момент клика.
  bool get _isModifierPressed {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;

    return keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight) ||
        keys.contains(LogicalKeyboardKey.metaLeft) ||
        keys.contains(LogicalKeyboardKey.metaRight);
  }

  void _onTap() =>
      _isModifierPressed ? widget.onOpenInNewTab() : widget.onOpen();

  void _onPointerDown(PointerDownEvent event) {
    if (event.buttons == kMiddleMouseButton) widget.onOpenInNewTab();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final project = widget.project;
    final coverHeight = widget.width / ProjectCard.coverAspectRatio;

    return Semantics(
      button: true,
      label: _semanticsLabel(project),
      excludeSemantics: true,
      child: SLFocusRing(
        focused: _focused,
        child: Listener(
          onPointerDown: _onPointerDown,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() {
              _hovered = false;
              _pressed = false;
            }),
            child: GestureDetector(
              onTap: _onTap,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              child: Focus(
                onFocusChange: (focused) => setState(() => _focused = focused),
                onKeyEvent: (node, event) {
                  if (event is! KeyDownEvent) return KeyEventResult.ignored;
                  final key = event.logicalKey;
                  if (key != LogicalKeyboardKey.enter &&
                      key != LogicalKeyboardKey.numpadEnter) {
                    return KeyEventResult.ignored;
                  }
                  widget.onOpen();

                  return KeyEventResult.handled;
                },
                child: Container(
                  width: widget.width,
                  decoration: BoxDecoration(
                    color: _pressed ? colors.surfaceHover : colors.surface,
                    borderRadius: SLRadii.mdAll,
                    border: Border.all(
                      color: _hovered ? colors.borderStrong : colors.border,
                      width: SLBorders.hairline,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCover(coverHeight),
                      Padding(
                        padding: const EdgeInsets.all(SLSpacing.space3),
                        child: _buildBody(project),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover(double height) {
    return SizedBox(
      height: height,
      child: ClipRect(
        child: AnimatedScale(
          scale: _hovered ? ProjectCard.coverHoverScale : 1,
          duration: SLMotion.durationOf(context, SLMotion.fast),
          curve: SLMotion.fastCurve,
          child: SLCoverImage(
            projectId: widget.project.id,
            projectName: widget.project.name,
            coverUrl: widget.project.coverUrl,
            width: widget.width,
            height: height,
            // Верхние углы скругляет сама карточка через `clipBehavior`:
            // собственный радиус здесь дал бы двойное скругление.
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ProjectDto project) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final description = project.description?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: ProjectCard.titleHeight,
          child: Tooltip(
            message: project.name,
            child: Text(
              project.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.title.copyWith(color: colors.textPrimary),
            ),
          ),
        ),
        SizedBox(
          height: ProjectCard.descriptionHeight,
          // Описание занимает ровно две строки и при пустом значении тоже:
          // иначе сетка карточек выравнивалась бы рвано.
          child: description.isEmpty
              ? Text(
                  '—',
                  style: text.bodyS.copyWith(color: colors.textDisabled),
                )
              : Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyS.copyWith(color: colors.textMuted),
                ),
        ),
        SizedBox(
          height: ProjectCard.footerHeight,
          child: Row(
            children: [
              SLAvatarGroup(
                members: [
                  for (final member in project.members)
                    SLAvatarGroupMember(
                      id: member.id,
                      name: member.displayName,
                      photoUrl: member.avatarUrl,
                    ),
                ],
                total: project.memberCount.toInt(),
              ),
              const Spacer(),
              // На этом экране бейдж показывается всегда, включая «Участник»:
              // роль отвечает на вопрос «куда я могу вносить изменения»
              // (`screens/projects.md`, осознанное отступление от system.md 7).
              SLRoleBadge(role: project.role.role, short: true),
            ],
          ),
        ),
      ],
    );
  }

  String _semanticsLabel(ProjectDto project) {
    final description = project.description?.trim() ?? '';
    final members = project.memberCount.toInt();

    return [
      project.name,
      if (description.isNotEmpty) description,
      'участников: $members',
      'ваша роль: ${project.role.role.label.toLowerCase()}',
    ].join(', ');
  }
}
