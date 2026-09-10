import 'package:flutter/foundation.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/platform/file_drop.dart';
import 'package:sl_tracker_web/core/platform/file_picker.dart';
import 'package:sl_tracker_web/features/issues/data/attachments_repository.dart';
import 'package:sl_tracker_web/features/issues/data/comments_repository.dart';

/// Пользователь задачи для тестов.
IssueUserDto fakeIssueUser({
  String id = 'user-1',
  String displayName = 'Анна Иванова',
}) => IssueUserDto(id: id, displayName: displayName, avatarUrl: null);

/// Задача целиком для тестов.
IssueDto fakeIssue({
  String key = 'DEV-42',
  String title = 'Починить экспорт CSV на больших выгрузках',
  String? description,
  IssueDtoPriority priority = IssueDtoPriority.value80,
  IssueDtoStoryPoints? storyPoints,
  IssueUserDto? author,
  IssueUserDto? assignee,
  List<IssueLinkDto> links = const [],
  bool canEdit = true,
  bool canDelete = true,
}) => IssueDto(
  key: key,
  title: title,
  description: description,
  status: const IssueStatusFullDto(
    id: 'status-in-progress',
    key: 'in_progress',
    name: 'В работе',
    category: IssueStatusFullDtoCategory.inProgress,
    position: 2,
  ),
  priority: priority,
  storyPoints: storyPoints,
  author: author ?? fakeIssueUser(),
  assignee: assignee,
  queue: const IssueQueueRefDto(key: 'DEV', name: 'Разработка'),
  project: const IssueProjectRefDto(slug: 'sweet-limit', name: 'Sweet Limit'),
  links: links,
  role: IssueDtoRole.admin,
  permissions: IssuePermissionsDto(canEdit: canEdit, canDelete: canDelete),
  createdAt: DateTime.utc(2026, 2, 12, 10),
  updatedAt: DateTime.utc(2026, 2, 12, 14),
);

/// Комментарий для тестов.
CommentDto fakeComment({
  required String id,
  String body = 'Проверил на стейдже — падает на 52 000.',
  IssueUserDto? author,
  List<IssueUserDto> mentions = const [],
  DateTime? createdAt,
  DateTime? editedAt,
  bool canEdit = true,
  bool canDelete = true,
}) => CommentDto(
  id: id,
  body: body,
  author: author ?? fakeIssueUser(),
  mentions: mentions,
  editedAt: editedAt,
  createdAt: createdAt ?? DateTime.utc(2026, 2, 12, 14, 32),
  permissions: CommentPermissionsDto(canEdit: canEdit, canDelete: canDelete),
);

/// Вложение для тестов.
AttachmentDto fakeAttachment({
  String id = 'file-1',
  String fileName = 'Спецификация.pdf',
  String contentType = 'application/pdf',
  int sizeBytes = 2411724,
  bool isImage = false,
  bool canDelete = true,
}) => AttachmentDto(
  id: id,
  fileName: fileName,
  contentType: contentType,
  sizeBytes: sizeBytes,
  isImage: isImage,
  url: 'https://files.example/$id',
  downloadUrl: 'https://files.example/$id?download=1',
  uploadedBy: fakeIssueUser(),
  createdAt: DateTime.utc(2026, 2, 12, 11),
  canDelete: canDelete,
);

/// Группа истории для тестов.
IssueHistoryGroupDto fakeHistoryGroup({
  String id = 'group-1',
  IssueUserDto? actor,
  DateTime? createdAt,
  List<IssueHistoryChangeDto> changes = const [],
}) => IssueHistoryGroupDto(
  id: id,
  createdAt: createdAt ?? DateTime.utc(2026, 2, 12, 15),
  actor: actor,
  changes: changes,
);

/// Изменение истории для тестов.
IssueHistoryChangeDto fakeHistoryChange({
  String id = 'change-1',
  IssueHistoryChangeDtoKind kind = IssueHistoryChangeDtoKind.statusChanged,
  String? oldValue = 'Открыт',
  String? newValue = 'В работе',
}) => IssueHistoryChangeDto(
  id: id,
  kind: kind,
  oldValue: oldValue,
  newValue: newValue,
  oldRefId: null,
  newRefId: null,
);

/// Подставной репозиторий комментариев.
class FakeCommentsRepository implements CommentsRepository {
  /// @nodoc
  FakeCommentsRepository({List<CommentDto>? items, this.canComment = true})
    : items = items ?? [];

  /// Лента: сначала старые.
  List<CommentDto> items;

  /// Может ли текущий пользователь комментировать.
  bool canComment;

  /// Курсор более ранних; `null` — их нет.
  String? earlierCursor;

  /// Чем упадёт загрузка ленты.
  ApiFailure? listFailure;

  /// Чем упадёт отправка.
  ApiFailure? createFailure;

  /// Чем упадёт удаление.
  ApiFailure? removeFailure;

  /// Тексты, дошедшие до «сервера».
  final createdBodies = <String>[];

  /// Идентификаторы удалённых комментариев.
  final removedIds = <String>[];

  @override
  Future<CommentListDto> list(String issueKey, {String? cursor}) async {
    final failure = listFailure;
    if (failure != null) throw failure;

    return CommentListDto(
      items: items,
      nextCursor: cursor == null ? earlierCursor : null,
      total: items.length,
      canComment: canComment,
    );
  }

  @override
  Future<CommentDto> create(String issueKey, String body) async {
    createdBodies.add(body);

    final failure = createFailure;
    if (failure != null) throw failure;

    return fakeComment(id: 'created-${createdBodies.length}', body: body);
  }

  @override
  Future<CommentDto> update(
    String issueKey,
    String commentId,
    String body,
  ) async => fakeComment(
    id: commentId,
    body: body,
    editedAt: DateTime.utc(2026, 2, 12, 16),
  );

  @override
  Future<void> remove(String issueKey, String commentId) async {
    removedIds.add(commentId);

    final failure = removeFailure;
    if (failure != null) throw failure;
  }
}

/// Подставной репозиторий вложений.
class FakeAttachmentsRepository implements AttachmentsRepository {
  /// @nodoc
  FakeAttachmentsRepository({List<AttachmentDto>? items, this.canUpload = true})
    : items = items ?? [];

  /// @nodoc
  List<AttachmentDto> items;

  /// @nodoc
  bool canUpload;

  /// Чем упадёт загрузка файла.
  ApiFailure? uploadFailure;

  /// Имена файлов, дошедшие до «сервера».
  final uploadedNames = <String>[];

  /// Идентификаторы удалённых вложений.
  final removedIds = <String>[];

  @override
  Future<AttachmentListDto> list(String issueKey, {String? cursor}) async =>
      AttachmentListDto(
        items: items,
        nextCursor: null,
        total: items.length,
        canUpload: canUpload,
      );

  @override
  Future<AttachmentDto> upload(String issueKey, PickedFile file) async {
    uploadedNames.add(file.name);

    final failure = uploadFailure;
    if (failure != null) throw failure;

    return fakeAttachment(
      id: 'uploaded-${uploadedNames.length}',
      fileName: file.name,
    );
  }

  @override
  Future<void> remove(String issueKey, String attachmentId) async =>
      removedIds.add(attachmentId);
}

/// Подставная подсказка участников.
class FakeMentionsRepository implements MentionsRepository {
  /// @nodoc
  FakeMentionsRepository({List<MentionSuggestionDto>? items})
    : items = items ?? [];

  /// @nodoc
  List<MentionSuggestionDto> items;

  /// Запросы, дошедшие до «сервера»: поиск обязан быть серверным.
  final queries = <String>[];

  @override
  Future<List<MentionSuggestionDto>> suggest(
    String issueKey, {
    required String query,
  }) async {
    queries.add(query);

    return items;
  }
}

/// Подсказка участника для тестов.
MentionSuggestionDto fakeSuggestion({
  String id = '0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0',
  String displayName = 'Анна Иванова',
  String email = 'anna@example.com',
}) => MentionSuggestionDto(
  id: id,
  displayName: displayName,
  email: email,
  avatarUrl: null,
);

/// Подставной приём перетаскивания: событий браузера в тесте нет,
/// но подписка и отписка проверяются.
class FakeFileDropTarget implements FileDropTarget {
  /// Сколько раз подписались.
  int attachCount = 0;

  /// Сколько раз отписались.
  int detachCount = 0;

  ValueChanged<List<PickedFile>>? _onFiles;
  ValueChanged<bool>? _onHover;

  @override
  VoidCallback attach({
    required ValueChanged<bool> onHoverChanged,
    required ValueChanged<List<PickedFile>> onFiles,
  }) {
    attachCount++;
    _onHover = onHoverChanged;
    _onFiles = onFiles;

    return () => detachCount++;
  }

  /// Изображает наведение перетаскиваемого файла на окно.
  void hover({required bool over}) => _onHover?.call(over);

  /// Изображает сброс файлов.
  void drop(List<PickedFile> files) => _onFiles?.call(files);
}

/// Файл для тестов загрузки.
PickedFile fakePickedFile({
  String name = 'screenshot.png',
  String mimeType = 'image/png',
  int size = 1024,
}) => PickedFile(name: name, mimeType: mimeType, bytes: Uint8List(size));

/// Подставной выбор файла в системном диалоге.
class FakeFilePicker implements FilePicker {
  /// @nodoc
  FakeFilePicker({this.file});

  /// Что «выберет» человек. `null` — закрыл диалог.
  PickedFile? file;

  @override
  Future<PickedFile?> pickOne({required String accept}) async => file;
}
