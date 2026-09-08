import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/platform/file_picker.dart';
import 'package:sl_tracker_web/features/projects/domain/project_cover.dart';
import 'package:sl_tracker_web/features/projects/presentation/project_providers.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/feedback/sl_toast.dart';
import 'package:sl_tracker_web/shared/uikit/media/sl_cover_image.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Секция «Обложка» вкладки настроек (US-12).
///
/// Ограничения написаны рядом **до** выбора файла, а не в сообщении об ошибке
/// после: узнавать про 5 МБ, потратив минуту на загрузку, — плохой способ
/// об этом узнать.
///
/// Ссылка на обложку подписана и живёт 10 минут. Специально её не кэшируем:
/// провайдер проекта самоочищается, а если ссылка всё же протухла на открытом
/// экране, вместо картинки молча появится монограмма — не «сломанное
/// изображение».
class ProjectCoverSection extends ConsumerStatefulWidget {
  /// @nodoc
  const ProjectCoverSection({
    required this.project,
    this.onCoverExpired,
    super.key,
  });

  /// Подписанная ссылка истекла: проект перезапрашивается ради свежего адреса.
  final VoidCallback? onCoverExpired;

  /// Проект.
  final ProjectDto project;

  /// Ширина превью.
  static const previewWidth = 240.0;

  /// Высота превью — 16:9.
  static const previewHeight = 135.0;

  @override
  ConsumerState<ProjectCoverSection> createState() =>
      _ProjectCoverSectionState();
}

class _ProjectCoverSectionState extends ConsumerState<ProjectCoverSection> {
  String? _error;
  var _busy = false;

  Future<void> _upload() async {
    if (_busy) return;

    final picked = await ref
        .read(filePickerProvider)
        .pickOne(accept: ProjectCover.acceptAttribute);

    // Человек закрыл диалог — это не ошибка и сообщать не о чем.
    if (picked == null || !mounted) return;

    final problem = ProjectCover.problemOf(picked);
    if (problem != null) {
      // Прежняя обложка остаётся на месте: отклонённый файл её не трогает.
      setState(
        () => _error = switch (problem) {
          ProjectCoverProblem.unsupportedType =>
            'Это не PNG, JPEG или WEBP. Выберите другой файл.',
          ProjectCoverProblem.tooLarge =>
            'Файл ${ProjectCover.formatSize(picked.size)} — '
                'это больше 5 МБ. Выберите файл поменьше.',
        },
      );

      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref
          .read(projectProvider(widget.project.slug).notifier)
          .uploadCover(picked);

      if (!mounted) return;
      setState(() => _busy = false);
      ref.read(toastControllerProvider.notifier).success('Обложка загружена');
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _messageOf(failure);
      });
    }
  }

  Future<void> _remove() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref
          .read(projectProvider(widget.project.slug).notifier)
          .removeCover();

      if (!mounted) return;
      setState(() => _busy = false);
      ref.read(toastControllerProvider.notifier).success('Обложка удалена');
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _messageOf(failure);
      });
    }
  }

  /// Текст по коду сервера. Сервер определяет тип по содержимому файла,
  /// поэтому отказ возможен и после клиентской проверки — например, если
  /// файл переименовали в `.png`.
  String _messageOf(ApiFailure failure) =>
      switch ((failure.kind, failure.code)) {
        (_, 'cover_unsupported_type') =>
          'Сервер не принял файл: это не PNG, JPEG или WEBP.',
        (ApiFailureKind.tooLarge, _) ||
        (_, 'cover_too_large') => 'Файл больше 5 МБ.',
        (_, 'cover_file_required') =>
          'Файл не дошёл до сервера. Попробуйте ещё раз.',
        (ApiFailureKind.forbidden, _) =>
          'Недостаточно прав: похоже, вашу роль в проекте изменили.',
        _ => 'Не удалось изменить обложку. Попробуйте ещё раз.',
      };

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final project = widget.project;
    final error = _error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SLCoverImage(
          projectId: project.id,
          projectName: project.name,
          coverUrl: project.coverUrl,
          width: ProjectCoverSection.previewWidth,
          height: ProjectCoverSection.previewHeight,
          onCoverExpired: widget.onCoverExpired,
        ),
        const SizedBox(height: SLSpacing.space2),
        Text(
          ProjectCover.limitsHint,
          style: text.label.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: SLSpacing.space3),
        Row(
          children: [
            SLButton(
              label: project.coverUrl == null ? 'Загрузить' : 'Заменить',
              icon: Icons.upload_rounded,
              variant: SLButtonVariant.secondary,
              isLoading: _busy,
              onPressed: _upload,
            ),
            if (project.coverUrl != null) ...[
              const SizedBox(width: SLSpacing.space2),
              SLButton(
                label: 'Удалить',
                variant: SLButtonVariant.dangerGhost,
                onPressed: _busy ? null : _remove,
              ),
            ],
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: SLSpacing.space3),
          SLBanner(
            title: 'Обложка не изменилась',
            description: error,
            onDismiss: () => setState(() => _error = null),
          ),
        ],
      ],
    );
  }
}
