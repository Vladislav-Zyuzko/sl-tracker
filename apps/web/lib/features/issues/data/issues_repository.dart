import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/network/network_providers.dart';
import 'package:sl_tracker_web/features/queues/domain/issue_sort.dart';

/// Задачи: список очереди, создание, мои активные.
class IssuesRepository {
  /// @nodoc
  const IssuesRepository(this._client);

  final IssuesClient _client;

  /// Порция списка задач очереди. 50 — размер из спеки экрана.
  static const pageSize = 50;

  /// Порция списка моих активных задач.
  ///
  /// Сайдбар показывает первые 50: дальше человек уходит в очередь, а не
  /// прокручивает панель 240 px. Догрузка по прокрутке всё равно есть —
  /// курсор в контракте не декоративный.
  static const sidebarPageSize = 50;

  /// Задачи очереди (US-32).
  ///
  /// [statusKeys] — **ключи** статусов, а не идентификаторы: именно они
  /// стоят в адресе страницы, и именно их ждёт сервер. Пустой список
  /// означает «без фильтра» и параметр не отправляет.
  Future<IssueListDto> queueIssues(
    String queueKey, {
    String? cursor,
    List<String> statusKeys = const [],
    IssueSort sort = IssueSort.priority,
  }) async {
    try {
      return await _client.queueIssuesControllerList(
        key: queueKey,
        cursor: cursor,
        status: statusKeys.isEmpty ? null : statusKeys.join(','),
        sort: sort.dto,
        limit: pageSize,
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Создаёт задачу в очереди (US-40).
  ///
  /// Ключ, статус по умолчанию и автора назначает сервер — клиент их
  /// не придумывает.
  Future<IssueDto> create(
    String queueKey, {
    required String title,
    String? description,
    String? statusId,
    CreateIssueDtoPriority priority = CreateIssueDtoPriority.value50,
    CreateIssueDtoStoryPoints? storyPoints,
    String? assigneeId,
  }) async {
    try {
      return await _client.queueIssuesControllerCreate(
        key: queueKey,
        body: CreateIssueDto(
          title: title,
          description: description == null || description.isEmpty
              ? null
              : description,
          statusId: statusId,
          priority: priority,
          storyPoints: storyPoints,
          assigneeId: assigneeId,
        ),
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Меняет статус задачи прямо из списка.
  ///
  /// Отдельный метод, а не общий `update`: из списка меняется ровно одно поле,
  /// и метод, принимающий всё сразу, приглашает случайно отправить `null`
  /// туда, где его быть не должно.
  Future<IssueDto> changeStatus(String issueKey, String statusId) async {
    try {
      return await _client.issueControllerUpdate(
        key: issueKey,
        body: UpdateIssueDto(statusId: statusId),
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Мои активные задачи (US-81).
  ///
  /// Поиск выполняет **сервер** (D-20): фильтровать загруженную страницу
  /// на клиенте нельзя — за её пределами останутся задачи, которые человек
  /// как раз и ищет.
  Future<MyIssueListDto> myActive({String? cursor, String? query}) async {
    try {
      return await _client.myIssuesControllerMyActive(
        cursor: cursor,
        q: query == null || query.isEmpty ? null : query,
        limit: sidebarPageSize,
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }
}

/// @nodoc
final issuesRepositoryProvider = Provider<IssuesRepository>(
  (ref) => IssuesRepository(ref.watch(apiClientProvider).issues),
);
