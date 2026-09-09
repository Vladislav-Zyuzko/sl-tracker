import 'dart:async';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/issues/data/issues_repository.dart';
import 'package:sl_tracker_web/features/queues/data/queues_repository.dart';
import 'package:sl_tracker_web/features/queues/domain/issue_sort.dart';

/// Очередь для тестов.
QueueDto fakeQueue({
  String key = 'DEV',
  String name = 'Разработка',
  String? description,
  String projectSlug = 'sweet-limit',
  String projectName = 'Sweet Limit',
  int openIssueCount = 12,
  QueueDtoRole role = QueueDtoRole.admin,
}) => QueueDto(
  key: key,
  name: name,
  description: description,
  projectSlug: projectSlug,
  projectName: projectName,
  openIssueCount: openIssueCount,
  role: role,
  createdAt: DateTime.utc(2026, 2, 12),
  updatedAt: DateTime.utc(2026, 2, 12),
);

/// Пять статусов очереди по умолчанию (US-60).
List<IssueStatusRef> fakeStatuses() => const [
  IssueStatusRef(
    id: 'status-open',
    key: 'open',
    name: 'Открыт',
    category: IssueStatusCategory.open,
  ),
  IssueStatusRef(
    id: 'status-in-progress',
    key: 'in_progress',
    name: 'В работе',
    category: IssueStatusCategory.inProgress,
  ),
  IssueStatusRef(
    id: 'status-review',
    key: 'review',
    name: 'Ревью',
    category: IssueStatusCategory.inProgress,
  ),
  IssueStatusRef(
    id: 'status-testing',
    key: 'testing',
    name: 'Тестирование',
    category: IssueStatusCategory.inProgress,
  ),
  IssueStatusRef(
    id: 'status-closed',
    key: 'closed',
    name: 'Закрыт',
    category: IssueStatusCategory.done,
  ),
];

/// Строка списка задач для тестов.
IssueRowDto fakeIssueRow({
  required String key,
  String? title,
  String statusKey = 'in_progress',
  String statusName = 'В работе',
  IssueRowStatusDtoCategory category = IssueRowStatusDtoCategory.inProgress,
  int priority = 50,
  int? storyPoints = 3,
  IssueUserDto? assignee,
}) => IssueRowDto(
  key: key,
  title: title ?? 'Задача $key',
  status: IssueRowStatusDto(
    id: 'status-$statusKey',
    key: statusKey,
    name: statusName,
    category: category,
  ),
  priority: priority,
  storyPoints: storyPoints,
  assignee: assignee,
);

/// Моя активная задача для тестов.
MyIssueDto fakeMyIssue({
  required String key,
  String? title,
  int priority = 50,
  String statusKey = 'in_progress',
  String statusName = 'В работе',
}) => MyIssueDto(
  key: key,
  title: title ?? 'Задача $key',
  priority: priority,
  status: IssueStatusDto(
    key: statusKey,
    name: statusName,
    category: IssueStatusDtoCategory.inProgress,
  ),
);

/// Подставной репозиторий очередей.
class FakeQueuesRepository implements QueuesRepository {
  /// @nodoc
  FakeQueuesRepository({List<QueueDto>? queues})
    : queues = queues ?? [fakeQueue()];

  /// Что вернёт список очередей проекта.
  List<QueueDto> queues;

  /// Пока не завершён, список «грузится».
  Completer<void>? gate;

  /// Чем упадёт список.
  ApiFailure? listFailure;

  /// Чем упадёт чтение одной очереди.
  ApiFailure? getFailure;

  /// Чем упадёт удаление.
  ApiFailure? removeFailure;

  /// Статусы очереди.
  List<IssueStatusRef> statusList = fakeStatuses();

  /// Какие очереди удаляли.
  final removedQueues = <String>[];

  @override
  Future<QueueListDto> list(String slug) async {
    await gate?.future;
    final failure = listFailure;
    if (failure != null) throw failure;

    return QueueListDto(items: queues, total: queues.length);
  }

  @override
  Future<QueueDto> byKey(String key) async {
    final failure = getFailure;
    if (failure != null) throw failure;

    return queues.firstWhere(
      (queue) => queue.key == key,
      orElse: () => fakeQueue(key: key),
    );
  }

  @override
  Future<List<IssueStatusRef>> statuses(String key) async => statusList;

  @override
  Future<CreatedQueueDto> create(
    String slug, {
    required String key,
    required String name,
    String? description,
  }) async {
    final created = CreatedQueueDto(
      key: key,
      name: name,
      description: description,
      projectSlug: slug,
      projectName: 'Sweet Limit',
      openIssueCount: 0,
      role: CreatedQueueDtoRole.admin,
      statuses: const [],
      createdAt: DateTime.utc(2026, 2, 12),
      updatedAt: DateTime.utc(2026, 2, 12),
    );

    return created;
  }

  @override
  Future<QueueDto> rename(
    String key, {
    required String name,
    required String description,
  }) async => fakeQueue(
    key: key,
    name: name,
    description: description.isEmpty ? null : description,
  );

  @override
  Future<void> remove(String key) async {
    final failure = removeFailure;
    if (failure != null) throw failure;

    removedQueues.add(key);
  }
}

/// Подставной репозиторий задач.
class FakeIssuesRepository implements IssuesRepository {
  /// @nodoc
  FakeIssuesRepository({List<IssueRowDto>? issues, this.role})
    : issues = issues ?? [];

  /// Полный набор задач очереди: страницы нарезаются из него.
  List<IssueRowDto> issues;

  /// Роль в ответе списка.
  IssueListDtoRole? role;

  /// Размер страницы.
  int pageSize = 50;

  /// Пока не завершён, первая страница «грузится».
  Completer<void>? gate;

  /// Чем упадёт первая загрузка.
  ApiFailure? listFailure;

  /// Чем упадёт дозагрузка.
  ApiFailure? loadMoreFailure;

  /// Чем упадёт смена статуса.
  ApiFailure? changeStatusFailure;

  /// Мои активные задачи.
  List<MyIssueDto> myIssues = [];

  /// Чем упадёт список моих активных задач.
  ApiFailure? myActiveFailure;

  /// Запросы поиска, дошедшие до «сервера»: поиск обязан быть серверным
  /// (D-20), и это проверяется именно так.
  final searchQueries = <String?>[];

  /// Фильтры, с которыми запрашивали список задач.
  final requestedStatusKeys = <List<String>>[];

  /// Сортировки, с которыми запрашивали список.
  final requestedSorts = <IssueSort>[];

  /// Созданные задачи.
  final createdTitles = <String>[];

  @override
  Future<IssueListDto> queueIssues(
    String queueKey, {
    String? cursor,
    List<String> statusKeys = const [],
    IssueSort sort = IssueSort.priority,
  }) async {
    requestedStatusKeys.add(statusKeys);
    requestedSorts.add(sort);

    if (cursor == null) {
      await gate?.future;
      final failure = listFailure;
      if (failure != null) throw failure;
    } else {
      final failure = loadMoreFailure;
      if (failure != null) throw failure;
    }

    final filtered = statusKeys.isEmpty
        ? issues
        : [
            for (final issue in issues)
              if (statusKeys.contains(issue.status.key)) issue,
          ];

    final offset = cursor == null ? 0 : int.parse(cursor);
    final slice = filtered.skip(offset).take(pageSize).toList();
    final next = offset + slice.length;

    return IssueListDto(
      items: slice,
      nextCursor: next < filtered.length ? '$next' : null,
      total: filtered.length,
      role: role,
    );
  }

  @override
  Future<IssueDto> create(
    String queueKey, {
    required String title,
    String? description,
    String? statusId,
    CreateIssueDtoPriority priority = CreateIssueDtoPriority.value50,
    CreateIssueDtoStoryPoints? storyPoints,
    String? assigneeId,
  }) async {
    createdTitles.add(title);

    return _issue(
      key: '$queueKey-${createdTitles.length}',
      title: title,
      status: fakeStatuses().first,
    );
  }

  @override
  Future<IssueDto> changeStatus(String issueKey, String statusId) async {
    patches.add('status');

    final failure = changeStatusFailure ?? patchFailure;
    if (failure != null) throw failure;

    final status = fakeStatuses().firstWhere(
      (item) => item.id == statusId,
      orElse: () => fakeStatuses().first,
    );

    final current = issue;
    if (current != null) {
      return issue = current.copyWith(
        status: IssueStatusFullDto(
          id: status.id!,
          key: status.key,
          name: status.name,
          category: switch (status.category) {
            IssueStatusCategory.open => IssueStatusFullDtoCategory.open,
            IssueStatusCategory.inProgress =>
              IssueStatusFullDtoCategory.inProgress,
            IssueStatusCategory.done => IssueStatusFullDtoCategory.done,
          },
          position: current.status.position,
        ),
      );
    }

    return _issue(key: issueKey, title: 'Задача $issueKey', status: status);
  }

  /// Задача целиком — ответ и на создание, и на смену статуса.
  IssueDto _issue({
    required String key,
    required String title,
    required IssueStatusRef status,
  }) => IssueDto(
    key: key,
    title: title,
    description: null,
    status: IssueStatusFullDto(
      id: status.id!,
      key: status.key,
      name: status.name,
      category: switch (status.category) {
        IssueStatusCategory.open => IssueStatusFullDtoCategory.open,
        IssueStatusCategory.inProgress => IssueStatusFullDtoCategory.inProgress,
        IssueStatusCategory.done => IssueStatusFullDtoCategory.done,
      },
      position: 1,
    ),
    priority: IssueDtoPriority.value50,
    storyPoints: null,
    author: const IssueUserDto(
      id: 'user-1',
      displayName: 'Анна Иванова',
      avatarUrl: null,
    ),
    assignee: null,
    queue: const IssueQueueRefDto(key: 'DEV', name: 'Разработка'),
    project: const IssueProjectRefDto(slug: 'sweet-limit', name: 'Sweet Limit'),
    links: const [],
    role: IssueDtoRole.admin,
    permissions: const IssuePermissionsDto(canEdit: true, canDelete: true),
    createdAt: DateTime.utc(2026, 2, 12),
    updatedAt: DateTime.utc(2026, 2, 12),
  );

  /// Задача, которую отдаёт `byKey` и правки полей.
  ///
  /// Правки применяются к этому объекту: экран задачи проверяет
  /// оптимистичное изменение и откат, а значит подставной репозиторий обязан
  /// вести себя как сервер, а не отдавать всегда одно и то же.
  IssueDto? issue;

  /// Чем упадёт загрузка задачи.
  ApiFailure? issueFailure;

  /// Чем упадёт любая правка поля.
  ApiFailure? patchFailure;

  /// Группы истории.
  List<IssueHistoryGroupDto> historyGroups = [];

  /// Курсор следующей порции истории.
  String? historyCursor;

  /// Чем упадёт загрузка истории.
  ApiFailure? historyFailure;

  /// Сколько раз запрашивали задачу.
  int byKeyCalls = 0;

  /// Тела правок, дошедшие до «сервера»: по ним видно, что ушло на сервер,
  /// а что осталось оптимистичным.
  final patches = <String>[];

  IssueDto get _current =>
      issue ??
      _issue(
        key: 'DEV-42',
        title: 'Задача DEV-42',
        status: fakeStatuses().first,
      );

  Future<IssueDto> _patch(String label, IssueDto Function(IssueDto) apply) {
    patches.add(label);

    final failure = patchFailure;
    if (failure != null) throw failure;

    return Future.value(issue = apply(_current));
  }

  @override
  Future<IssueDto> byKey(String issueKey) async {
    byKeyCalls++;
    await gate?.future;

    final failure = issueFailure;
    if (failure != null) throw failure;

    return _current;
  }

  @override
  Future<IssueDto> changeTitle(String issueKey, String title) =>
      _patch('title', (current) => current.copyWith(title: title));

  @override
  Future<IssueDto> changeDescription(String issueKey, String description) =>
      _patch(
        'description',
        (current) => current.copyWith(description: description),
      );

  @override
  Future<IssueDto> changePriority(String issueKey, int priority) => _patch(
    'priority',
    (current) => current.copyWith(priority: IssueDtoPriority.fromJson(priority)),
  );

  @override
  Future<IssueDto> changeStoryPoints(String issueKey, int? storyPoints) =>
      _patch(
        'storyPoints',
        (current) => current.copyWith(
          storyPoints: storyPoints == null
              ? null
              : IssueDtoStoryPoints.fromJson(storyPoints),
        ),
      );

  @override
  Future<IssueDto> changeAuthor(String issueKey, String authorId) => _patch(
    'author',
    (current) => current.copyWith(
      author: IssueUserDto(
        id: authorId,
        displayName: 'Автор $authorId',
        avatarUrl: null,
      ),
    ),
  );

  @override
  Future<IssueDto> changeAssignee(String issueKey, String? assigneeId) =>
      _patch(
        'assignee',
        (current) => current.copyWith(
          assignee: assigneeId == null
              ? null
              : IssueUserDto(
                  id: assigneeId,
                  displayName: 'Исполнитель $assigneeId',
                  avatarUrl: null,
                ),
        ),
      );

  @override
  Future<void> remove(String issueKey) async {
    final failure = patchFailure;
    if (failure != null) throw failure;

    patches.add('remove');
  }

  @override
  Future<IssueHistoryListDto> history(
    String issueKey, {
    String? cursor,
  }) async {
    final failure = historyFailure;
    if (failure != null) throw failure;

    return IssueHistoryListDto(
      items: historyGroups,
      nextCursor: cursor == null ? historyCursor : null,
      total: historyGroups.length,
    );
  }

  @override
  Future<IssueDto> addLink(
    String issueKey, {
    required String url,
    String? title,
  }) => _patch(
    'addLink',
    (current) => current.copyWith(
      links: [
        ...current.links,
        IssueLinkDto(
          id: 'link-${current.links.length + 1}',
          url: url,
          title: title,
          createdBy: current.author,
          createdAt: DateTime.utc(2026, 2, 12),
        ),
      ],
    ),
  );

  @override
  Future<IssueDto> removeLink(String issueKey, String linkId) => _patch(
    'removeLink',
    (current) => current.copyWith(
      links: [
        for (final link in current.links)
          if (link.id != linkId) link,
      ],
    ),
  );

  @override
  Future<MyIssueListDto> myActive({String? cursor, String? query}) async {
    searchQueries.add(query);
    await gate?.future;

    final failure = myActiveFailure;
    if (failure != null) throw failure;

    // Сервер ищет сам: подставной репозиторий повторяет его поведение,
    // но список отдаёт целиком тот, что ему положили.
    return MyIssueListDto(
      items: myIssues,
      nextCursor: null,
      total: myIssues.length,
    );
  }
}

/// Статус «В работе» для тестов, где сам статус не важен.
const fakeStatusInProgress = IssueStatusRef(
  id: 'status-in-progress',
  key: 'in_progress',
  name: 'В работе',
  category: IssueStatusCategory.inProgress,
);
