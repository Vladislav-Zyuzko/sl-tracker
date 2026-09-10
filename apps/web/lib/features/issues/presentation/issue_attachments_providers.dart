import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/platform/file_picker.dart';
import 'package:sl_tracker_web/features/issues/data/attachments_repository.dart';

/// Файл, который сейчас загружается или не загрузился.
@immutable
class AttachmentUpload {
  /// @nodoc
  const AttachmentUpload({
    required this.localId,
    required this.fileName,
    required this.sizeBytes,
    this.error,
  });

  /// Локальный идентификатор плитки.
  final int localId;

  /// @nodoc
  final String fileName;

  /// @nodoc
  final int sizeBytes;

  /// Текст ошибки. `null` — файл ещё летит.
  final String? error;

  /// Загрузка сорвалась либо файл отклонён до отправки.
  bool get failed => error != null;

  /// @nodoc
  AttachmentUpload copyWith({String? error}) => AttachmentUpload(
    localId: localId,
    fileName: fileName,
    sizeBytes: sizeBytes,
    error: error ?? this.error,
  );
}

/// Загруженная часть списка вложений.
@immutable
class AttachmentsPage {
  /// @nodoc
  const AttachmentsPage({
    required this.items,
    required this.uploads,
    required this.nextCursor,
    required this.total,
    required this.canUpload,
  });

  /// Вложения в порядке добавления, сначала старые.
  final List<AttachmentDto> items;

  /// Файлы в процессе загрузки и отклонённые.
  final List<AttachmentUpload> uploads;

  /// @nodoc
  final String? nextCursor;

  /// @nodoc
  final int total;

  /// Может ли пользователь прикладывать файлы. У читателя `false`.
  final bool canUpload;

  /// Блок вложений показывается вовсе? Пустого блока не бывает (US-48).
  bool get isVisible => items.isNotEmpty || uploads.isNotEmpty;

  /// Картинки — первыми, сеткой.
  List<AttachmentDto> get images => [
    for (final item in items)
      if (item.isImage) item,
  ];

  /// Остальные файлы — строками под сеткой.
  List<AttachmentDto> get files => [
    for (final item in items)
      if (!item.isImage) item,
  ];

  /// @nodoc
  AttachmentsPage copyWith({
    List<AttachmentDto>? items,
    List<AttachmentUpload>? uploads,
    String? nextCursor,
    bool clearCursor = false,
    int? total,
  }) => AttachmentsPage(
    items: items ?? this.items,
    uploads: uploads ?? this.uploads,
    nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    total: total ?? this.total,
    canUpload: canUpload,
  );
}

/// Вложения задачи (US-46, US-48).
final issueAttachmentsProvider =
    AsyncNotifierProvider.family<
      AttachmentsController,
      AttachmentsPage,
      String
    >(AttachmentsController.new, isAutoDispose: true, retry: (_, _) => null);

/// Контроллер вложений.
///
/// Ссылки на содержимое подписанные и живут 10 минут, поэтому кэшировать их
/// нельзя (D-21): список перезапрашивается при открытии задачи, а не берётся
/// из памяти прошлого визита.
class AttachmentsController extends AsyncNotifier<AttachmentsPage> {
  /// @nodoc
  AttachmentsController(this.issueKey);

  /// @nodoc
  final String issueKey;

  var _nextLocalId = 0;

  @override
  Future<AttachmentsPage> build() async {
    final page = await ref.read(attachmentsRepositoryProvider).list(issueKey);

    return AttachmentsPage(
      items: page.items,
      uploads: const [],
      nextCursor: page.nextCursor,
      total: page.total.toInt(),
      canUpload: page.canUpload,
    );
  }

  /// @nodoc
  void refresh() => ref.invalidateSelf();

  /// Загружает выбранные файлы.
  ///
  /// Файл больше 25 МБ отклоняется **сразу** и на остальные не влияет:
  /// один плохой файл не отменяет пачку (US-46).
  Future<void> upload(List<PickedFile> files) async {
    for (final file in files) {
      await _uploadOne(file);
    }
  }

  /// Убирает плитку отклонённого файла.
  void discardUpload(int localId) {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        uploads: [
          for (final item in current.uploads)
            if (item.localId != localId) item,
        ],
      ),
    );
  }

  /// Удаляет вложение — оптимистично, с возвратом плитки на место
  /// при отказе сервера.
  Future<void> remove(String attachmentId) async {
    final current = state.value;
    if (current == null) return;

    final index = current.items.indexWhere((item) => item.id == attachmentId);
    if (index < 0) return;

    final removed = current.items[index];
    state = AsyncData(
      current.copyWith(
        items: [...current.items]..removeAt(index),
        total: current.total - 1,
      ),
    );

    try {
      await ref
          .read(attachmentsRepositoryProvider)
          .remove(issueKey, attachmentId);
    } on Object {
      final latest = state.value;
      if (ref.mounted && latest != null) {
        state = AsyncData(
          latest.copyWith(
            items: [...latest.items]
              ..insert(index.clamp(0, latest.items.length), removed),
            total: latest.total + 1,
          ),
        );
      }

      rethrow;
    }
  }

  Future<void> _uploadOne(PickedFile file) async {
    final current = state.value;
    if (current == null) return;

    final upload = AttachmentUpload(
      localId: _nextLocalId++,
      fileName: file.name,
      sizeBytes: file.size,
      error: file.size > AttachmentsRepository.maxFileSizeBytes
          ? 'Файл больше 25 МБ'
          : null,
    );

    state = AsyncData(current.copyWith(uploads: [...current.uploads, upload]));

    // Слишком большой файл на сервер не отправляется вовсе: плитка ошибки
    // появляется мгновенно, а 25 МБ не уезжают в сеть ради ответа 413.
    if (upload.failed) return;

    try {
      final created = await ref
          .read(attachmentsRepositoryProvider)
          .upload(issueKey, file);

      final latest = state.value;
      if (!ref.mounted || latest == null) return;

      state = AsyncData(
        latest.copyWith(
          items: [...latest.items, created],
          uploads: [
            for (final item in latest.uploads)
              if (item.localId != upload.localId) item,
          ],
          total: latest.total + 1,
        ),
      );
    } on Object catch (error) {
      final latest = state.value;
      if (!ref.mounted || latest == null) return;

      final failure = ApiFailure.of(error);
      final message = switch (failure.kind) {
        ApiFailureKind.tooLarge => 'Файл больше 25 МБ',
        ApiFailureKind.forbidden => 'Нет прав прикреплять файлы',
        ApiFailureKind.network || ApiFailureKind.timeout => 'Нет соединения',
        _ => 'Не удалось загрузить',
      };

      state = AsyncData(
        latest.copyWith(
          uploads: [
            for (final item in latest.uploads)
              if (item.localId == upload.localId)
                item.copyWith(error: message)
              else
                item,
          ],
        ),
      );
    }
  }
}
