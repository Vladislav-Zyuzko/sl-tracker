import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/network/network_providers.dart';
import 'package:sl_tracker_web/features/issues/domain/issue_status_ref.dart';

/// Очереди проекта и одна очередь.
class QueuesRepository {
  /// @nodoc
  const QueuesRepository(this._client);

  final QueuesClient _client;

  /// Очереди проекта. Курсора в контракте нет: очередей у проекта единицы,
  /// и список приходит целиком.
  Future<QueueListDto> list(String slug) async {
    try {
      return await _client.projectQueuesControllerList(slug: slug);
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Очередь по ключу. Ключ регистронезависим.
  Future<QueueDto> byKey(String key) async {
    try {
      return await _client.queueControllerGet(key: key);
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Статусы очереди (ADR-0003).
  ///
  /// Возвращаются в порядке `position` — том самом, в котором они показываются
  /// в фильтре и в меню смены статуса. Сортировка здесь, а не в виджете:
  /// порядок — свойство данных, а не разметки.
  Future<List<IssueStatusRef>> statuses(String key) async {
    try {
      final page = await _client.queueControllerStatuses(key: key);
      final items = [...page.items]
        ..sort((a, b) => a.position.compareTo(b.position));

      return [for (final status in items) status.ref];
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Создаёт очередь. Ключ задаёт человек, и он неизменяем (D-06).
  ///
  /// Вместе с очередью сервер создаёт пять статусов по умолчанию и отдаёт
  /// их в ответе — второй запрос за ними не нужен.
  Future<CreatedQueueDto> create(
    String slug, {
    required String key,
    required String name,
    String? description,
  }) async {
    try {
      return await _client.projectQueuesControllerCreate(
        slug: slug,
        body: CreateQueueDto(
          key: key,
          name: name,
          description: description == null || description.isEmpty
              ? null
              : description,
        ),
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Переименовывает очередь. Ключ при этом не меняется (US-33, D-06).
  Future<QueueDto> rename(
    String key, {
    required String name,
    required String description,
  }) async {
    try {
      return await _client.queueControllerUpdate(
        key: key,
        body: UpdateQueueDto(
          name: name,
          // Пустая строка очищает описание — так описано в контракте.
          description: description,
        ),
      );
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }

  /// Удаляет очередь. Только пустую: непустая — 409 `queue_not_empty`
  /// (US-34, D-24).
  Future<void> remove(String key) async {
    try {
      await _client.queueControllerRemove(key: key);
    } on Object catch (error) {
      throw ApiFailure.of(error);
    }
  }
}

/// @nodoc
final queuesRepositoryProvider = Provider<QueuesRepository>(
  (ref) => QueuesRepository(ref.watch(apiClientProvider).queues),
);
