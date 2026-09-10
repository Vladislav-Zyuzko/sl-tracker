import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/platform/file_picker.dart';
import 'package:sl_tracker_web/features/invites/data/invitations_repository.dart';
import 'package:sl_tracker_web/features/projects/data/projects_repository.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_role_badge.dart';

/// Проект по короткому имени из адреса.
///
/// Ключ семейства — тот slug, по которому пришёл человек, а не действующий:
/// прежнее короткое имя продолжает открывать проект (US-18), и подменять
/// ключ на действующий нельзя — иначе провайдер пересоздавался бы под собой.
/// Действующее имя лежит в `state.value.slug`, и экран заменяет им адрес
/// в строке браузера.
///
/// Автоочистка: `coverUrl` — подписанная ссылка на 10 минут, держать её
/// между заходами незачем.
final projectProvider =
    AsyncNotifierProvider.family<ProjectController, ProjectDto, String>(
      ProjectController.new,
      isAutoDispose: true,
      retry: (_, _) => null,
    );

/// Контроллер одного проекта.
class ProjectController extends AsyncNotifier<ProjectDto> {
  /// @nodoc
  ProjectController(this.slug);

  /// Короткое имя из адреса. Может быть прежним, а не действующим.
  final String slug;

  @override
  Future<ProjectDto> build() =>
      ref.watch(projectsRepositoryProvider).bySlug(slug);

  /// Перезагружает проект.
  void refresh() => ref.invalidateSelf();

  /// Действующее короткое имя. Пока проект не загружен — то, что в адресе.
  String get currentSlug => state.value?.slug ?? slug;

  /// Записывает результат, если провайдер ещё жив.
  ///
  /// Провайдер самоочищается: пока идёт запрос, человек может уйти с экрана —
  /// например, закрыть вкладку проекта посреди загрузки обложки. Тогда
  /// писать в состояние уже некуда, и попытка это сделать роняет запрос
  /// исключением, а не показывает ошибку. Результат при этом возвращается:
  /// сервер своё дело сделал.
  ProjectDto _publish(ProjectDto project) {
    if (ref.mounted) state = AsyncData(project);

    return project;
  }

  /// Меняет название и описание (US-12).
  ///
  /// Не `update`: так называется метод самого `AsyncNotifier`.
  Future<ProjectDto> updateDetails({
    required String name,
    required String description,
  }) async {
    final updated = await ref
        .read(projectsRepositoryProvider)
        .update(currentSlug, name: name, description: description);

    return _publish(updated);
  }

  /// Меняет короткое имя в адресе (US-18).
  ///
  /// Возвращает проект целиком: экран берёт `slug` из ответа, а не то, что
  /// человек набрал в поле, — сервер приводит значение к своим правилам.
  Future<ProjectDto> changeSlug(String newSlug) async {
    final updated = await ref
        .read(projectsRepositoryProvider)
        .changeSlug(currentSlug, newSlug);

    return _publish(updated);
  }

  /// Загружает обложку.
  Future<ProjectDto> uploadCover(PickedFile file) async {
    final updated = await ref
        .read(projectsRepositoryProvider)
        .uploadCover(currentSlug, file);

    return _publish(updated);
  }

  /// Удаляет обложку: снова показывается монограмма (US-12).
  Future<ProjectDto> removeCover() async {
    final updated = await ref
        .read(projectsRepositoryProvider)
        .removeCover(currentSlug);

    return _publish(updated);
  }

  /// Удаляет проект со всем содержимым (US-17).
  Future<void> remove() =>
      ref.read(projectsRepositoryProvider).remove(currentSlug);
}

/// Участники проекта.
final projectMembersProvider =
    AsyncNotifierProvider.family<
      ProjectMembersController,
      ProjectMembersPage,
      String
    >(ProjectMembersController.new, isAutoDispose: true, retry: (_, _) => null);

/// Запрос к поиску участников проекта: проект плюс строка поиска.
@immutable
class ProjectMemberSearch {
  /// @nodoc
  const ProjectMemberSearch({required this.slug, this.query = ''});

  /// Короткое имя проекта.
  final String slug;

  /// Строка поиска. Пустая — начало списка участников.
  final String query;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectMemberSearch &&
          other.slug == slug &&
          other.query == query;

  @override
  int get hashCode => Object.hash(slug, query);
}

/// Совпавшие участники и сколько их всего.
@immutable
class ProjectMemberMatches {
  /// @nodoc
  const ProjectMemberMatches({required this.items, required this.total});

  /// Найденные участники — не больше [ProjectMemberSearchController.limit].
  final List<ProjectMemberDto> items;

  /// Сколько совпало на сервере. При активном поиске это число совпадений,
  /// а не состав проекта, — поэтому по нему и видно, что показано не всё.
  final int total;

  /// Совпадений больше, чем поместилось в меню.
  bool get isTruncated => total > items.length;
}

/// Поиск участников проекта под селектор пользователя
/// (`components.md`, 6).
///
/// Ищет **сервер** — `GET /api/projects/{slug}/members?q=`. Выкачивать весь
/// состав проекта и фильтровать его на клиенте нельзя: в крупном проекте
/// участников сотни, и за пределами первой страницы осталось бы ровно то,
/// что человек ищет.
///
/// Постраничной подгрузки здесь нет намеренно: меню показывает не больше 20
/// совпадений и предлагает уточнить запрос (`components.md`, 6). Бесконечная
/// прокрутка в выпадающем списке из трёх строк никому не нужна.
final projectMemberSearchProvider =
    AsyncNotifierProvider.family<
      ProjectMemberSearchController,
      ProjectMemberMatches,
      ProjectMemberSearch
    >(
      ProjectMemberSearchController.new,
      isAutoDispose: true,
      retry: (_, _) => null,
    );

/// Контроллер поиска участников.
class ProjectMemberSearchController
    extends AsyncNotifier<ProjectMemberMatches> {
  /// @nodoc
  ProjectMemberSearchController(this.search);

  /// @nodoc
  final ProjectMemberSearch search;

  /// Максимум строк в меню (`components.md`, 6).
  static const limit = 20;

  /// Сколько ответ держится в памяти после закрытия меню.
  ///
  /// Пока человек перебирает буквы, ответ на уже набранный префикс лежит
  /// рядом — и стирание буквы не превращается в новый запрос.
  static const cacheFor = Duration(seconds: 30);

  @override
  Future<ProjectMemberMatches> build() async {
    final link = ref.keepAlive();
    final timer = Timer(cacheFor, link.close);
    ref.onDispose(timer.cancel);

    final page = await ref
        .watch(projectsRepositoryProvider)
        .members(search.slug, query: search.query, limit: limit);

    return ProjectMemberMatches(items: page.items, total: page.total.toInt());
  }
}

/// Загруженная часть списка участников.
@immutable
class ProjectMembersPage {
  /// @nodoc
  const ProjectMembersPage({
    required this.items,
    required this.nextCursor,
    required this.total,
    this.isLoadingMore = false,
  });

  /// Сначала администраторы, дальше по имени — порядок задаёт сервер.
  final List<ProjectMemberDto> items;

  /// @nodoc
  final String? nextCursor;

  /// Всего участников в проекте.
  final int total;

  /// @nodoc
  final bool isLoadingMore;

  /// @nodoc
  bool get hasMore => nextCursor != null;

  /// В проекте всегда есть хотя бы один администратор
  /// (`permissions.md`, п. 7), и последнего понижать нельзя.
  bool get hasSingleAdmin =>
      items
          .where((member) => member.role == ProjectMemberDtoRole.admin)
          .length <=
      1;

  /// @nodoc
  ProjectMembersPage copyWith({
    List<ProjectMemberDto>? items,
    String? nextCursor,
    int? total,
    bool? isLoadingMore,
  }) => ProjectMembersPage(
    items: items ?? this.items,
    nextCursor: nextCursor ?? this.nextCursor,
    total: total ?? this.total,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

/// Контроллер списка участников.
class ProjectMembersController extends AsyncNotifier<ProjectMembersPage> {
  /// @nodoc
  ProjectMembersController(this.slug);

  /// Короткое имя проекта.
  final String slug;

  @override
  Future<ProjectMembersPage> build() async {
    final page = await ref.watch(projectsRepositoryProvider).members(slug);

    return ProjectMembersPage(
      items: page.items,
      nextCursor: page.nextCursor,
      total: page.total.toInt(),
    );
  }

  /// @nodoc
  void refresh() => ref.invalidateSelf();

  /// Догружает следующую страницу.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final page = await ref
          .read(projectsRepositoryProvider)
          .members(slug, cursor: current.nextCursor);

      if (!ref.mounted) return;

      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
          total: page.total.toInt(),
          isLoadingMore: false,
        ),
      );
    } on Object {
      if (ref.mounted) {
        state = AsyncData(current.copyWith(isLoadingMore: false));
      }

      rethrow;
    }
  }

  /// Меняет роль участника — оптимистично, с явным откатом.
  ///
  /// Бейдж роли меняется сразу: ждать ответа сервера, глядя на неизменившийся
  /// список, человеку незачем. При ошибке (например, 409
  /// `last_project_admin`) возвращается ровно прежняя строка, а не
  /// перезагружается весь список: перезагрузка стирала бы прокрутку и другие
  /// изменения заодно.
  Future<void> changeRole(String userId, SLRole role) async {
    final current = state.value;
    if (current == null) return;

    final index = current.items.indexWhere((item) => item.userId == userId);
    if (index < 0) return;

    final previous = current.items[index];
    final optimistic = previous.copyWith(
      role: switch (role) {
        SLRole.admin => ProjectMemberDtoRole.admin,
        SLRole.member => ProjectMemberDtoRole.member,
        SLRole.reader => ProjectMemberDtoRole.reader,
      },
    );

    state = AsyncData(
      current.copyWith(items: _replace(current.items, index, optimistic)),
    );

    try {
      final updated = await ref
          .read(projectsRepositoryProvider)
          .changeMemberRole(slug, userId, role);

      final page = state.value;
      if (page == null || !ref.mounted) return;

      final at = page.items.indexWhere((item) => item.userId == userId);
      if (at < 0) return;

      state = AsyncData(
        page.copyWith(items: _replace(page.items, at, updated)),
      );
    } on Object {
      final page = state.value;
      if (page != null && ref.mounted) {
        final at = page.items.indexWhere((item) => item.userId == userId);
        if (at >= 0) {
          state = AsyncData(
            page.copyWith(items: _replace(page.items, at, previous)),
          );
        }
      }

      rethrow;
    }
  }

  /// Исключает участника. Возвращает число задач, оставшихся без исполнителя.
  ///
  /// Не оптимистично: строка исчезает после ответа сервера. Показывать
  /// человека исключённым, когда сервер ещё может отказать (409
  /// `last_project_admin`), — врать о правах.
  Future<int> remove(String userId) async {
    final unassignedIssues = await ref
        .read(projectsRepositoryProvider)
        .removeMember(slug, userId);

    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          items: current.items.where((item) => item.userId != userId).toList(),
          total: current.total > 0 ? current.total - 1 : 0,
        ),
      );
    }

    return unassignedIssues;
  }

  static List<ProjectMemberDto> _replace(
    List<ProjectMemberDto> items,
    int index,
    ProjectMemberDto value,
  ) => [...items]..[index] = value;
}

/// Приглашения проекта. Только для администратора.
final projectInvitationsProvider =
    AsyncNotifierProvider.family<
      ProjectInvitationsController,
      List<InvitationDto>,
      String
    >(
      ProjectInvitationsController.new,
      isAutoDispose: true,
      retry: (_, _) => null,
    );

/// Контроллер списка приглашений.
///
/// Страница здесь одна: приглашений у проекта единицы, а курсор из контракта
/// нужен на случай, когда их окажется больше — тогда добавится догрузка.
class ProjectInvitationsController extends AsyncNotifier<List<InvitationDto>> {
  /// @nodoc
  ProjectInvitationsController(this.slug);

  /// @nodoc
  final String slug;

  @override
  Future<List<InvitationDto>> build() async {
    final page = await ref.watch(invitationsRepositoryProvider).list(slug);

    return page.items;
  }

  /// @nodoc
  void refresh() => ref.invalidateSelf();

  /// Создаёт ссылку и ставит её первой: сначала новые (US-22).
  Future<InvitationDto> create({
    required SLRole role,
    required CreateInvitationDtoExpiresInDays expiresInDays,
  }) async {
    final created = await ref
        .read(invitationsRepositoryProvider)
        .create(slug, role: role, expiresInDays: expiresInDays);

    if (ref.mounted) state = AsyncData([created, ...state.value ?? const []]);

    return created;
  }

  /// Отзывает ссылку. Строка остаётся в списке приглушённой (US-22).
  Future<void> revoke(String id) async {
    final revoked = await ref
        .read(invitationsRepositoryProvider)
        .revoke(slug, id);

    final current = state.value;
    if (current == null || !ref.mounted) return;

    state = AsyncData([
      for (final invitation in current)
        if (invitation.id == id) revoked else invitation,
    ]);
  }
}
