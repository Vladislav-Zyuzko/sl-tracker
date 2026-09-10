import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/features/issues/data/attachments_repository.dart';
import 'package:sl_tracker_web/features/issues/data/issues_repository.dart';
import 'package:sl_tracker_web/core/domain/issue_status.dart';
import 'package:sl_tracker_web/features/issues/domain/issue_fields.dart';

/// Сигнал «состав моих активных задач мог измениться».
///
/// Живёт в фиче задач, а слушает его сайдбар оболочки: правку делает экран
/// задачи, а список «мои активные задачи» о ней узнать иначе не может.
/// В теме `user:me` события `issue.updated` нет (`docs/api/websocket.md`, 5),
/// то есть на живые обновления здесь опереться не на что: сервер рассылает
/// его только в тему `issue:<KEY>`, на которую сайдбар не подписан.
///
/// Счётчик, а не `void`-поток: провайдер списка просто `watch`-ит число
/// и перечитывает первую страницу, когда оно изменилось. Перечитываем,
/// а не правим строку на месте: порядок в списке задаёт сервер (приоритет,
/// затем время изменения), и вычислять место новой задачи на клиенте —
/// значит однажды показать её не там, где сервер.
final myActiveIssuesRevisionProvider =
    NotifierProvider<MyActiveIssuesRevisionController, int>(
      MyActiveIssuesRevisionController.new,
    );

/// Контроллер счётчика правок.
class MyActiveIssuesRevisionController extends Notifier<int> {
  @override
  int build() => 0;

  /// Сообщает, что список пора перечитать.
  void bump() => state = state + 1;
}

/// Задача целиком (US-41).
///
/// Экран не перезапрашивает задачу после каждой правки: `PATCH` возвращает
/// её целиком, и ответ просто занимает место оптимистичного значения.
final issueProvider =
    AsyncNotifierProvider.family<IssueController, IssueDto, String>(
      IssueController.new,
      isAutoDispose: true,
      retry: (_, _) => null,
    );

/// Контроллер одной задачи.
///
/// Все правки полей — **оптимистичные с явным откатом**: значение меняется
/// мгновенно, а при ошибке возвращается ровно то поле, которое меняли
/// (`screens/issue.md`, «Поведение»). Откат именно поля, а не всей задачи:
/// пока запрос летел, соседнее поле мог поменять другой человек, и стирать
/// его чужое изменение из-за своей неудачи нельзя.
class IssueController extends AsyncNotifier<IssueDto> {
  /// @nodoc
  IssueController(this.issueKey);

  /// Ключ задачи из адреса.
  final String issueKey;

  @override
  Future<IssueDto> build() =>
      ref.watch(issuesRepositoryProvider).byKey(issueKey);

  /// @nodoc
  void refresh() => ref.invalidateSelf();

  /// Смена статуса (US-54). Самое частое действие экрана.
  Future<void> changeStatus(IssueStatusRef status) async {
    final statusId = status.id;
    if (statusId == null) return;

    final before = state.value;
    if (before == null || before.status.id == statusId) return;

    await _apply(
      optimistic: before.copyWith(
        status: IssueStatusFullDto(
          id: statusId,
          key: status.key,
          name: status.name,
          category: categoryDtoOf(status.category),
          position: before.status.position,
        ),
      ),
      rollback: (current) => current.copyWith(status: before.status),
      request: () => _repository.changeStatus(issueKey, statusId),
      affectsMyActive: true,
    );
  }

  /// Смена приоритета (US-50).
  Future<void> changePriority(int priority) async {
    final before = state.value;
    if (before == null || before.priority.value == priority) return;

    await _apply(
      optimistic: before.copyWith(priority: priorityDtoOf(priority)),
      rollback: (current) => current.copyWith(priority: before.priority),
      request: () => _repository.changePriority(issueKey, priority),
      affectsMyActive: true,
    );
  }

  /// Смена сложности (US-51). `null` — «не оценено».
  Future<void> changeStoryPoints(int? storyPoints) async {
    final before = state.value;
    if (before == null || before.storyPoints?.value == storyPoints) return;

    await _apply(
      optimistic: before.copyWith(storyPoints: storyPointsDtoOf(storyPoints)),
      rollback: (current) => current.copyWith(storyPoints: before.storyPoints),
      request: () => _repository.changeStoryPoints(issueKey, storyPoints),
    );
  }

  /// Смена автора (US-53). Пустым поле не бывает.
  Future<void> changeAuthor(IssueUserDto author) async {
    final before = state.value;
    if (before == null || before.author.id == author.id) return;

    await _apply(
      optimistic: before.copyWith(author: author),
      rollback: (current) => current.copyWith(author: before.author),
      request: () => _repository.changeAuthor(issueKey, author.id),
    );
  }

  /// Смена исполнителя (US-52). `null` снимает назначение.
  Future<void> changeAssignee(IssueUserDto? assignee) async {
    final before = state.value;
    if (before == null || before.assignee?.id == assignee?.id) return;

    await _apply(
      optimistic: before.copyWith(assignee: assignee),
      rollback: (current) => current.copyWith(assignee: before.assignee),
      request: () => _repository.changeAssignee(issueKey, assignee?.id),
      affectsMyActive: true,
    );
  }

  /// Переименование на месте (US-42).
  Future<void> changeTitle(String title) async {
    final before = state.value;
    final trimmed = title.trim();
    if (before == null || trimmed.isEmpty || before.title == trimmed) return;

    await _apply(
      optimistic: before.copyWith(title: trimmed),
      rollback: (current) => current.copyWith(title: before.title),
      request: () => _repository.changeTitle(issueKey, trimmed),
      affectsMyActive: true,
    );
  }

  /// Сохранение описания.
  ///
  /// Не оптимистично намеренно: описание — самое дорогое поле экрана, его
  /// правят в редакторе с явной кнопкой «Сохранить», и мгновенно показать
  /// результат, который сервер отверг, здесь хуже, чем подождать ответ.
  Future<void> saveDescription(String description) async {
    final updated = await _repository.changeDescription(issueKey, description);

    if (ref.mounted) state = AsyncData(updated);
  }

  /// Добавляет внешнюю ссылку (US-47).
  Future<void> addLink({required String url, String? title}) async {
    final updated = await _repository.addLink(issueKey, url: url, title: title);

    if (ref.mounted) state = AsyncData(updated);
  }

  /// Удаляет внешнюю ссылку — оптимистично: строка исчезает сразу.
  Future<void> removeLink(String linkId) async {
    final before = state.value;
    if (before == null) return;

    await _apply(
      optimistic: before.copyWith(
        links: [
          for (final link in before.links)
            if (link.id != linkId) link,
        ],
      ),
      rollback: (current) => current.copyWith(links: before.links),
      request: () => _repository.removeLink(issueKey, linkId),
    );
  }

  /// Удаляет задачу (US-44). Не оптимистично: экран после этого закрывается.
  Future<void> remove() async {
    await _repository.remove(issueKey);
    _notifyMyActiveChanged();
  }

  IssuesRepository get _repository => ref.read(issuesRepositoryProvider);

  /// Просит сайдбар перечитать «мои активные задачи».
  ///
  /// Вызывается только после успешного ответа сервера: до него состав списка
  /// не изменился, а показать в сайдбаре задачу, которую сервер отверг, —
  /// хуже, чем показать её на полсекунды позже.
  void _notifyMyActiveChanged() {
    // Провайдер задачи автоудаляемый: пока летел запрос, экран могли закрыть.
    if (!ref.mounted) return;

    ref.read(myActiveIssuesRevisionProvider.notifier).bump();
  }

  /// Оптимистичная правка одного поля.
  ///
  /// [rollback] получает **текущее** состояние, а не то, что было до правки:
  /// вернуть надо одно поле, а всё остальное оставить как есть.
  Future<void> _apply({
    required IssueDto optimistic,
    required IssueDto Function(IssueDto current) rollback,
    required Future<IssueDto> Function() request,
    bool affectsMyActive = false,
  }) async {
    state = AsyncData(optimistic);

    try {
      final updated = await request();
      if (ref.mounted) state = AsyncData(updated);
      if (affectsMyActive) _notifyMyActiveChanged();
    } on Object {
      final current = state.value;
      if (ref.mounted && current != null) {
        state = AsyncData(rollback(current));
      }

      rethrow;
    }
  }
}

/// Запрос к подсказке участников: задача плюс строка поиска.
@immutable
class IssueMemberQuery {
  /// @nodoc
  const IssueMemberQuery({required this.issueKey, this.query = ''});

  /// @nodoc
  final String issueKey;

  /// Строка поиска. Пустая — начало списка участников проекта.
  final String query;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IssueMemberQuery &&
          other.issueKey == issueKey &&
          other.query == query;

  @override
  int get hashCode => Object.hash(issueKey, query);
}

/// Подсказка упоминаний `@` (US-74).
///
/// Только для подсказки в тексте: селекторы автора и исполнителя ушли
/// на `GET /api/projects/{slug}/members?q=` (`projectMemberSearchProvider`).
/// Маршруты разные не по недосмотру — у них разный смысл: подсказка отдаёт
/// то, что годится в токен `@[имя](user:<uuid>)`, и ограничена 20 строками
/// и частотой запросов, а селектор выбирает участника проекта.
final issueMembersProvider =
    AsyncNotifierProvider.family<
      IssueMembersController,
      List<MentionSuggestionDto>,
      IssueMemberQuery
    >(IssueMembersController.new, isAutoDispose: true, retry: (_, _) => null);

/// Контроллер подсказки участников.
class IssueMembersController extends AsyncNotifier<List<MentionSuggestionDto>> {
  /// @nodoc
  IssueMembersController(this.query);

  /// @nodoc
  final IssueMemberQuery query;

  /// Сколько подсказка держится в памяти после закрытия меню.
  ///
  /// Пока человек перебирает буквы, ответ на уже набранный префикс лежит
  /// рядом: маршрут ограничен по частоте, и лишний запрос за тем же самым —
  /// это шаг к 429.
  static const cacheFor = Duration(seconds: 30);

  @override
  Future<List<MentionSuggestionDto>> build() {
    final link = ref.keepAlive();
    final timer = Timer(cacheFor, link.close);
    ref.onDispose(timer.cancel);

    return ref
        .watch(mentionsRepositoryProvider)
        .suggest(query.issueKey, query: query.query);
  }
}

/// Есть ли среди найденных полные тёзки.
///
/// От этого зависит, показывать ли email второй строкой: показывать его
/// всегда — лишний шум, не показывать никогда — невозможно выбрать между
/// двумя Ивановыми (US-74, `components.md`, 6).
Set<String> ambiguousNames(List<MentionSuggestionDto> items) {
  final seen = <String>{};
  final duplicates = <String>{};

  for (final item in items) {
    final name = item.displayName.toLowerCase();
    if (!seen.add(name)) duplicates.add(name);
  }

  return duplicates;
}
