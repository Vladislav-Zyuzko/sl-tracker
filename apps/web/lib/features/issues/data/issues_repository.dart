import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/network/network_providers.dart';
import 'package:sl_tracker_web/core/network/partial_update_interceptor.dart';
import 'package:sl_tracker_web/features/queues/domain/issue_sort.dart';

/// Задачи: список очереди, создание, мои активные.
class IssuesRepository {
  /// @nodoc
  const IssuesRepository(this._client);

  final IssuesClient _client;

  /// Порция списка задач очереди. 50 — размер из спеки экрана.
  static const pageSize = 50;

  /// Порция истории изменений. 25 — умолчание контракта.
  static const historyPageSize = 25;

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
  Future<IssueDto> changeStatus(String issueKey, String statusId) =>
      _patch(issueKey, UpdateIssueDto(statusId: statusId));

  /// Задача по ключу (US-41).
  Future<IssueDto> byKey(String issueKey) async {
    try {
      return await _client.issueControllerGet(key: issueKey);
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Переименовывает задачу (US-42).
  Future<IssueDto> changeTitle(String issueKey, String title) =>
      _patch(issueKey, UpdateIssueDto(title: title));

  /// Сохраняет описание. Пустая строка очищает поле (US-48).
  Future<IssueDto> changeDescription(String issueKey, String description) =>
      _patch(issueKey, UpdateIssueDto(description: description));

  /// Меняет приоритет (US-50). Пустым он не бывает никогда (D-15).
  Future<IssueDto> changePriority(String issueKey, int priority) => _patch(
    issueKey,
    UpdateIssueDto(priority: UpdateIssueDtoPriority.fromJson(priority)),
  );

  /// Меняет сложность. `null` снимает оценку и возвращает «не оценено»
  /// (US-51).
  ///
  /// «Снять оценку» и «не трогать поле» — разные намерения, а в Dart-модели
  /// оба выглядят как `null`. Очистка отправляется значением `$unknown`,
  /// которое `PartialUpdateInterceptor` разворачивает в настоящий `null`;
  /// без этого «не трогать» и «очистить» стали бы одним и тем же.
  Future<IssueDto> changeStoryPoints(String issueKey, int? storyPoints) =>
      _patch(
        issueKey,
        UpdateIssueDto(
          storyPoints: storyPoints == null
              ? UpdateIssueDtoStoryPoints.$unknown
              : UpdateIssueDtoStoryPoints.fromJson(storyPoints),
        ),
      );

  /// Меняет автора (US-53). Очистить поле нельзя — контракт этого не даёт.
  Future<IssueDto> changeAuthor(String issueKey, String authorId) =>
      _patch(issueKey, UpdateIssueDto(authorId: authorId));

  /// Меняет исполнителя (US-52). `null` снимает назначение.
  ///
  /// Тот же приём, что и у сложности: очистка едет маркером
  /// [PartialUpdateInterceptor.explicitNull].
  Future<IssueDto> changeAssignee(String issueKey, String? assigneeId) =>
      _patch(
        issueKey,
        UpdateIssueDto(
          assigneeId: assigneeId ?? PartialUpdateInterceptor.explicitNull,
        ),
      );

  /// Удаляет задачу. Только администратор проекта (US-44, D-12).
  Future<void> remove(String issueKey) async {
    try {
      await _client.issueControllerRemove(key: issueKey);
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// История изменений (US-90).
  ///
  /// Страница считается по группам: одно действие не разрывается границей
  /// страницы, поэтому клиенту группировать нечего.
  Future<IssueHistoryListDto> history(String issueKey, {String? cursor}) async {
    try {
      return await _client.issueControllerListHistory(
        key: issueKey,
        cursor: cursor,
        limit: historyPageSize,
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Добавляет внешнюю ссылку (US-47). В ответе — задача целиком.
  Future<IssueDto> addLink(
    String issueKey, {
    required String url,
    String? title,
  }) async {
    try {
      return await _client.issueControllerAddLink(
        key: issueKey,
        body: CreateIssueLinkDto(
          url: url,
          title: title == null || title.isEmpty ? null : title,
        ),
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Удаляет внешнюю ссылку (US-47).
  Future<IssueDto> removeLink(String issueKey, String linkId) async {
    try {
      return await _client.issueControllerRemoveLink(
        key: issueKey,
        linkId: linkId,
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Частичное обновление задачи.
  ///
  /// Все правки поля идут через один метод: `PATCH /api/issues/{key}`
  /// обновляет ровно те поля, что пришли в теле, а незаданные не трогает —
  /// за это отвечает [PartialUpdateInterceptor], убирающий `null` из JSON.
  Future<IssueDto> _patch(String issueKey, UpdateIssueDto body) async {
    try {
      return await _client.issueControllerUpdate(key: issueKey, body: body);
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
