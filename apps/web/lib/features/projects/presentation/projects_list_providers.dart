import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/features/projects/data/projects_repository.dart';

/// Загруженная часть списка проектов.
@immutable
class ProjectsListPage {
  /// @nodoc
  const ProjectsListPage({
    required this.items,
    required this.nextCursor,
    required this.total,
    this.isLoadingMore = false,
  });

  /// Проекты по названию по возрастанию — порядок задаёт сервер (US-10).
  final List<ProjectDto> items;

  /// Курсор следующей страницы. `null` — проектов больше нет.
  final String? nextCursor;

  /// Всего проектов у пользователя.
  final int total;

  /// Идёт догрузка следующей страницы.
  final bool isLoadingMore;

  /// Есть ли что догружать.
  bool get hasMore => nextCursor != null;

  /// @nodoc
  ProjectsListPage copyWith({
    List<ProjectDto>? items,
    String? nextCursor,
    int? total,
    bool? isLoadingMore,
  }) => ProjectsListPage(
    items: items ?? this.items,
    nextCursor: nextCursor ?? this.nextCursor,
    total: total ?? this.total,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

/// Список моих проектов.
///
/// Автоочистка намеренная. Дело не только в свежести данных: в `coverUrl`
/// лежит подписанная ссылка со сроком жизни 10 минут, и держать её в памяти
/// между заходами на экран бессмысленно — она протухнет молча, и вместо
/// обложек человек увидит монограммы.
final projectsListProvider =
    AsyncNotifierProvider<ProjectsListController, ProjectsListPage>(
      ProjectsListController.new,
      isAutoDispose: true,
      // Ошибка загрузки — это состояние экрана с кнопкой «Повторить»:
      // решение о повторе принимает человек, а не таймер.
      retry: (_, _) => null,
    );

/// Контроллер списка проектов.
class ProjectsListController extends AsyncNotifier<ProjectsListPage> {
  @override
  Future<ProjectsListPage> build() async {
    final page = await ref.watch(projectsRepositoryProvider).list();

    return ProjectsListPage(
      items: page.items,
      nextCursor: page.nextCursor,
      total: page.total.toInt(),
    );
  }

  /// Перезагружает список — кнопка «Повторить» и возврат после создания.
  void refresh() => ref.invalidateSelf();

  /// Догружает следующую страницу.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final page = await ref
          .read(projectsRepositoryProvider)
          .list(cursor: current.nextCursor);

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
      // Ошибка догрузки не стирает уже показанные карточки.
      if (ref.mounted) {
        state = AsyncData(current.copyWith(isLoadingMore: false));
      }

      rethrow;
    }
  }

  /// Создаёт проект и возвращает его целиком.
  ///
  /// Короткое имя в адресе приходит от сервера: клиентский предпросмотр мог
  /// разойтись с ним из-за коллизии, и переходить нужно именно на `slug`
  /// из ответа (D-35).
  ///
  /// Список не достраивается вручную: сразу после создания человек уходит
  /// на экран проекта, и порядок по названию всё равно пересчитает сервер.
  Future<ProjectDto> create({
    required String name,
    required String description,
  }) async {
    final created = await ref
        .read(projectsRepositoryProvider)
        .create(name: name, description: description);

    // Провайдер мог самоочиститься, пока шёл запрос: человек ушёл с экрана,
    // не дождавшись ответа. Проект при этом создан — возвращаем его.
    if (ref.mounted) refresh();

    return created;
  }
}
