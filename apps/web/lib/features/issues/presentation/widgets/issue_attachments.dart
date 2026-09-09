import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/utils/sl_date_format.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_attachments_providers.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/issue_description.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_button.dart';
import 'package:sl_tracker_web/shared/uikit/buttons/sl_icon_button.dart';
import 'package:sl_tracker_web/shared/uikit/colors/sl_color_scheme.dart';
import 'package:sl_tracker_web/shared/uikit/sl_metrics.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_middle_ellipsis_text.dart';
import 'package:sl_tracker_web/shared/uikit/text/sl_text_scheme.dart';

/// Размер файла человеческими словами.
String formatFileSize(int bytes) {
  const kb = 1024;
  const mb = kb * 1024;

  if (bytes >= mb) {
    return '${(bytes / mb).toStringAsFixed(1).replaceAll('.', ',')} МБ';
  }
  if (bytes >= kb) return '${(bytes / kb).round()} КБ';

  return '$bytes Б';
}

/// Блок вложений (US-46, US-48).
///
/// Изображения идут сеткой 160 × 120 первыми, остальные файлы — строками 48.
/// Блок **скрывается целиком, когда вложений нет**: пустого блока не бывает,
/// остаётся только кнопка «Прикрепить» в строке действий.
class IssueAttachments extends ConsumerWidget {
  /// @nodoc
  const IssueAttachments({
    required this.issueKey,
    required this.onOpenImage,
    required this.onDownload,
    super.key,
  });

  /// @nodoc
  final String issueKey;

  /// @nodoc
  final ValueChanged<AttachmentDto> onOpenImage;

  /// @nodoc
  final ValueChanged<AttachmentDto> onDownload;

  /// Габариты плитки изображения.
  static const imageTile = Size(160, 120);

  /// Высота строки файла.
  static const fileRowHeight = 48.0;

  /// Сколько рядов сетки видно, пока не нажали «Показать все».
  static const collapsedImageRows = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(issueAttachmentsProvider(issueKey)).value;
    if (page == null || !page.isVisible) return const SizedBox.shrink();

    final notifier = ref.read(issueAttachmentsProvider(issueKey).notifier);

    return Padding(
      padding: const EdgeInsets.only(top: SLSpacing.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IssueSectionHeader(title: 'ВЛОЖЕНИЯ', count: page.total),
          const SizedBox(height: SLSpacing.space2),
          if (page.images.isNotEmpty)
            _ImageGrid(
              items: page.images,
              onOpen: onOpenImage,
              onDownload: onDownload,
              onDelete: notifier.remove,
            ),
          for (final file in page.files)
            _FileRow(
              attachment: file,
              onDownload: () => onDownload(file),
              onDelete: file.canDelete ? () => notifier.remove(file.id) : null,
            ),
          for (final upload in page.uploads)
            _UploadTile(
              upload: upload,
              onDiscard: () => notifier.discardUpload(upload.localId),
            ),
        ],
      ),
    );
  }
}

/// Сетка изображений. При 20+ сворачивается до двух рядов.
class _ImageGrid extends StatefulWidget {
  const _ImageGrid({
    required this.items,
    required this.onOpen,
    required this.onDownload,
    required this.onDelete,
  });

  final List<AttachmentDto> items;
  final ValueChanged<AttachmentDto> onOpen;
  final ValueChanged<AttachmentDto> onDownload;
  final ValueChanged<String> onDelete;

  @override
  State<_ImageGrid> createState() => _ImageGridState();
}

class _ImageGridState extends State<_ImageGrid> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow =
            (constraints.maxWidth /
                    (IssueAttachments.imageTile.width + SLSpacing.space2))
                .floor()
                .clamp(1, 8);
        final limit = perRow * IssueAttachments.collapsedImageRows;
        final visible = _expanded || widget.items.length <= limit
            ? widget.items
            : widget.items.take(limit).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: SLSpacing.space2,
              runSpacing: SLSpacing.space2,
              children: [
                for (final item in visible)
                  _ImageTile(
                    attachment: item,
                    onOpen: () => widget.onOpen(item),
                    onDownload: () => widget.onDownload(item),
                    onDelete: item.canDelete
                        ? () => widget.onDelete(item.id)
                        : null,
                  ),
              ],
            ),
            if (visible.length < widget.items.length)
              Padding(
                padding: const EdgeInsets.only(top: SLSpacing.space2),
                child: SLButton(
                  label: 'Показать все (${widget.items.length})',
                  variant: SLButtonVariant.ghost,
                  size: SLButtonSize.sm,
                  onPressed: () => setState(() => _expanded = true),
                ),
              ),
            const SizedBox(height: SLSpacing.space2),
          ],
        );
      },
    );
  }
}

class _ImageTile extends StatefulWidget {
  const _ImageTile({
    required this.attachment,
    required this.onOpen,
    required this.onDownload,
    required this.onDelete,
  });

  final AttachmentDto attachment;
  final VoidCallback onOpen;
  final VoidCallback onDownload;
  final VoidCallback? onDelete;

  /// Высота подписи под превью.
  static const captionHeight = 24.0;

  @override
  State<_ImageTile> createState() => _ImageTileState();
}

class _ImageTileState extends State<_ImageTile> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final attachment = widget.attachment;

    return Semantics(
      label:
          'Вложение: ${attachment.fileName}, '
          '${formatFileSize(attachment.sizeBytes.toInt())}, '
          'добавлено ${SLDateFormat.exact(attachment.createdAt)}',
      button: true,
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onOpen,
          child: Container(
            width: IssueAttachments.imageTile.width,
            decoration: BoxDecoration(
              borderRadius: SLRadii.mdAll,
              border: Border.all(
                color: _hovered ? colors.borderStrong : colors.border,
                width: SLBorders.hairline,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: IssueAttachments.imageTile.height,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(SLRadii.md),
                        ),
                        child: Image.network(
                          attachment.url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              ColoredBox(
                                color: colors.surfaceSunken,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: colors.iconMuted,
                                ),
                              ),
                        ),
                      ),
                      if (_hovered)
                        Positioned(
                          top: SLSpacing.space1,
                          right: SLSpacing.space1,
                          child: _TileActions(
                            onDownload: widget.onDownload,
                            onDelete: widget.onDelete,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: _ImageTile.captionHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SLSpacing.space1,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        attachment.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.label.copyWith(color: colors.textMuted),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TileActions extends StatelessWidget {
  const _TileActions({required this.onDownload, required this.onDelete});

  final VoidCallback onDownload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.scrim,
        borderRadius: SLRadii.smAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SLIconButton(
            icon: Icons.download_rounded,
            tooltip: 'Скачать',
            size: SLButtonSize.sm,
            onPressed: onDownload,
          ),
          if (onDelete != null)
            SLIconButton(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Удалить вложение',
              size: SLButtonSize.sm,
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.attachment,
    required this.onDownload,
    required this.onDelete,
  });

  final AttachmentDto attachment;
  final VoidCallback onDownload;
  final VoidCallback? onDelete;

  /// Размер бейджа с расширением.
  static const badgeSize = 32.0;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);
    final extension = attachment.fileName.contains('.')
        ? attachment.fileName.split('.').last.toUpperCase()
        : '?';

    return Semantics(
      label:
          'Вложение: ${attachment.fileName}, '
          '${formatFileSize(attachment.sizeBytes.toInt())}, '
          'добавлено ${SLDateFormat.exact(attachment.createdAt)}',
      excludeSemantics: true,
      child: SizedBox(
        height: IssueAttachments.fileRowHeight,
        child: Row(
          children: [
            Container(
              width: badgeSize,
              height: badgeSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surfaceSunken,
                borderRadius: SLRadii.smAll,
              ),
              child: Text(
                extension.length > 4 ? extension.substring(0, 4) : extension,
                style: text.overline.copyWith(color: colors.textSecondary),
              ),
            ),
            const SizedBox(width: SLSpacing.space2),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Обрезка посередине: расширение файла остаётся видимым.
                  SLMiddleEllipsisText(
                    value: attachment.fileName,
                    style: text.bodyS.copyWith(color: colors.textPrimary),
                  ),
                  Text(
                    '${formatFileSize(attachment.sizeBytes.toInt())} · '
                    '${SLDateFormat.short(attachment.createdAt)}',
                    style: text.label.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
            SLIconButton(
              icon: Icons.download_rounded,
              tooltip: 'Скачать',
              size: SLButtonSize.sm,
              onPressed: onDownload,
            ),
            if (onDelete != null)
              SLIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Удалить вложение',
                size: SLButtonSize.sm,
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

/// Плитка файла, который загружается или отклонён.
class _UploadTile extends StatelessWidget {
  const _UploadTile({required this.upload, required this.onDiscard});

  final AttachmentUpload upload;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);
    final text = SLTextScheme.of(context);

    return Semantics(
      liveRegion: upload.failed,
      child: Container(
        height: IssueAttachments.fileRowHeight,
        margin: const EdgeInsets.only(top: SLSpacing.space1),
        padding: const EdgeInsets.symmetric(horizontal: SLSpacing.space2),
        decoration: BoxDecoration(
          color: upload.failed ? colors.dangerSurface : colors.surfaceSunken,
          borderRadius: SLRadii.smAll,
          border: Border.all(
            color: upload.failed ? colors.dangerBorder : colors.border,
            width: SLBorders.hairline,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SLMiddleEllipsisText(
                    value: upload.fileName,
                    style: text.bodyS.copyWith(color: colors.textPrimary),
                  ),
                  Text(
                    upload.error ?? 'Загружается…',
                    style: text.label.copyWith(
                      color: upload.failed ? colors.danger : colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (upload.failed)
              SLButton(
                label: 'Убрать',
                variant: SLButtonVariant.ghost,
                size: SLButtonSize.sm,
                onPressed: onDiscard,
              )
            else
              // Точного процента нет: сгенерированный клиент не отдаёт
              // прогресс отправки. Показываем честную неопределённость,
              // а не выдуманные проценты.
              SizedBox.square(
                dimension: SLIconSizes.icon16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Полноэкранный просмотрщик изображения.
class ImageViewerDialog extends StatelessWidget {
  /// @nodoc
  const ImageViewerDialog({
    required this.url,
    required this.fileName,
    super.key,
  });

  /// @nodoc
  final String url;

  /// @nodoc
  final String fileName;

  /// Показывает просмотрщик. `Esc` закрывает — это поведение `Dialog`
  /// по умолчанию.
  static Future<void> show(
    BuildContext context, {
    required String url,
    required String fileName,
  }) => showDialog<void>(
    context: context,
    builder: (context) => ImageViewerDialog(url: url, fileName: fileName),
  );

  @override
  Widget build(BuildContext context) {
    final colors = SLColorScheme.of(context);

    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.all(SLSpacing.space8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(SLSpacing.space2),
            child: Row(
              children: [
                Expanded(
                  child: SLMiddleEllipsisText(
                    value: fileName,
                    style: SLTextScheme.of(
                      context,
                    ).bodyS.copyWith(color: colors.textPrimary),
                  ),
                ),
                SLIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Закрыть',
                  size: SLButtonSize.sm,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: InteractiveViewer(
              child: Image.network(
                url,
                errorBuilder: (context, error, stackTrace) => Padding(
                  padding: const EdgeInsets.all(SLSpacing.space8),
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: SLIconSizes.icon48,
                    color: colors.iconMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
