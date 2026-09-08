import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/features/queues/data/queues_repository.dart';

/// Очереди проекта (US-31).
///
/// Курсора в контракте нет: очередей у проекта единицы, и список приходит
/// целиком. Автоочистка — список перечитывается при возвращении на вкладку,
/// а число незавершённых задач стареет быстро.
final projectQueuesProvider =
    AsyncNotifierProvider.family<
      ProjectQueuesController,
      List<QueueDto>,
      String
    >(ProjectQueuesController.new, isAutoDispose: true, retry: (_, _) => null);

/// Контроллер списка очередей проекта.
class ProjectQueuesController extends AsyncNotifier<List<QueueDto>> {
  /// @nodoc
  ProjectQueuesController(this.slug);

  /// Короткое имя проекта.
  final String slug;

  @override
  Future<List<QueueDto>> build() async {
    final page = await ref.watch(queuesRepositoryProvider).list(slug);

    return page.items;
  }

  /// @nodoc
  void refresh() => ref.invalidateSelf();

  /// Создаёт очередь и ставит её на своё место по алфавиту.
  ///
  /// Не перезапрашивает список: сервер вернул очередь целиком, и лишний
  /// запрос ради того же самого — это лишние полсекунды пустого экрана.
  Future<CreatedQueueDto> create({
    required String key,
    required String name,
    String? description,
  }) async {
    final created = await ref
        .read(queuesRepositoryProvider)
        .create(slug, key: key, name: name, description: description);

    if (ref.mounted) {
      state = AsyncData(_sorted([...state.value ?? const [], created.queue]));
    }

    return created;
  }

  /// Переименовывает очередь. Ключ не меняется (D-06).
  Future<QueueDto> rename(
    String key, {
    required String name,
    required String description,
  }) async {
    final updated = await ref
        .read(queuesRepositoryProvider)
        .rename(key, name: name, description: description);

    final current = state.value;
    if (current != null && ref.mounted) {
      state = AsyncData(
        _sorted([
          for (final queue in current)
            if (queue.key == key) updated else queue,
        ]),
      );
    }

    return updated;
  }

  /// Удаляет пустую очередь (US-34).
  ///
  /// Не оптимистично: сервер вправе отказать (409 `queue_not_empty`),
  /// и убирать строку до ответа — врать о результате.
  Future<void> remove(String key) async {
    await ref.read(queuesRepositoryProvider).remove(key);

    final current = state.value;
    if (current == null || !ref.mounted) return;

    state = AsyncData([
      for (final queue in current)
        if (queue.key != key) queue,
    ]);
  }

  /// По названию по возрастанию — порядок, который задаёт сервер (US-31).
  static List<QueueDto> _sorted(List<QueueDto> queues) =>
      [...queues]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

/// Очередь по ключу: шапка экрана задач и хлебные крошки.
final queueProvider =
    AsyncNotifierProvider.family<QueueController, QueueDto, String>(
      QueueController.new,
      isAutoDispose: true,
      retry: (_, _) => null,
    );

/// Контроллер одной очереди.
class QueueController extends AsyncNotifier<QueueDto> {
  /// @nodoc
  QueueController(this.queueKey);

  /// Ключ очереди из адреса.
  final String queueKey;

  @override
  Future<QueueDto> build() =>
      ref.watch(queuesRepositoryProvider).byKey(queueKey);

  /// @nodoc
  void refresh() => ref.invalidateSelf();
}

/// Статусы очереди (ADR-0003).
///
/// Нужны фильтру по статусу и меню смены статуса. Запрос отдельный, потому
/// что он не зависит от фильтра и не должен уходить заново на каждое
/// изменение адреса.
final queueStatusesProvider =
    AsyncNotifierProvider.family<
      QueueStatusesController,
      List<IssueStatusRef>,
      String
    >(QueueStatusesController.new, isAutoDispose: true, retry: (_, _) => null);

/// Контроллер набора статусов очереди.
class QueueStatusesController extends AsyncNotifier<List<IssueStatusRef>> {
  /// @nodoc
  QueueStatusesController(this.queueKey);

  /// @nodoc
  final String queueKey;

  @override
  Future<List<IssueStatusRef>> build() =>
      ref.watch(queuesRepositoryProvider).statuses(queueKey);

  /// @nodoc
  void refresh() => ref.invalidateSelf();
}

/// Созданная очередь в виде обычной строки списка.
///
/// `CreatedQueueDto` отличается от `QueueDto` ровно одним полем — набором
/// статусов по умолчанию, — но это отдельный тип, и без перевода он в список
/// не встанет.
extension CreatedQueueDtoX on CreatedQueueDto {
  /// @nodoc
  QueueDto get queue => QueueDto(
    key: key,
    name: name,
    description: description,
    projectSlug: projectSlug,
    projectName: projectName,
    openIssueCount: openIssueCount,
    role: switch (role) {
      CreatedQueueDtoRole.admin => QueueDtoRole.admin,
      CreatedQueueDtoRole.member => QueueDtoRole.member,
      CreatedQueueDtoRole.reader => QueueDtoRole.reader,
      CreatedQueueDtoRole.$unknown => QueueDtoRole.$unknown,
    },
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
