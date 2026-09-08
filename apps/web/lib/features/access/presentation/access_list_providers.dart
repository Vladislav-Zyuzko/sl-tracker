import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/features/access/data/access_repository.dart';

/// Загруженная часть списка доступа.
@immutable
class AccessListPage {
  /// @nodoc
  const AccessListPage({
    required this.items,
    required this.nextCursor,
    required this.total,
    this.isLoadingMore = false,
    this.highlightedId,
  });

  /// Записи от новых к старым.
  final List<AccessEntryDto> items;

  /// Курсор следующей страницы. `null` — записей больше нет.
  final String? nextCursor;

  /// Всего записей с учётом поиска.
  final int total;

  /// Идёт догрузка следующей страницы.
  final bool isLoadingMore;

  /// Запись, только что добавленная руками: подсвечивается 1200 мс.
  final String? highlightedId;

  /// Есть ли что догружать.
  bool get hasMore => nextCursor != null;

  /// @nodoc
  AccessListPage copyWith({
    List<AccessEntryDto>? items,
    String? nextCursor,
    int? total,
    bool? isLoadingMore,
    String? highlightedId,
    bool clearHighlight = false,
  }) => AccessListPage(
    items: items ?? this.items,
    nextCursor: nextCursor ?? this.nextCursor,
    total: total ?? this.total,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    highlightedId: clearHighlight ? null : highlightedId ?? this.highlightedId,
  );
}

/// Строка поиска по списку доступа.
///
/// Отдельный провайдер, а не поле состояния: смена запроса перезапускает
/// загрузку списка целиком, и это ровно то, что описывает `ref.watch`.
final accessSearchQueryProvider = NotifierProvider<AccessSearchQuery, String>(
  AccessSearchQuery.new,
  isAutoDispose: true,
);

/// @nodoc
class AccessSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  /// @nodoc
  void update(String value) => state = value.trim();
}

/// Список доступа.
///
/// Автоочистка намеренная: экран административный, открывают его редко,
/// и данные при следующем открытии должны быть свежими. В реальном времени
/// список не обновляется (`screens/access-list.md`).
final accessListProvider =
    AsyncNotifierProvider<AccessListController, AccessListPage>(
      AccessListController.new,
      isAutoDispose: true,
      // Автоповтор Riverpod здесь выключен намеренно: ошибка загрузки —
      // это состояние экрана с кнопкой «Повторить», решение за человеком.
      // Молча долбить сервер после 403 тем более незачем.
      retry: (_, _) => null,
    );

/// Контроллер списка доступа.
class AccessListController extends AsyncNotifier<AccessListPage> {
  Timer? _highlightTimer;

  /// Сколько держится подсветка только что добавленной строки.
  static const highlightDuration = Duration(milliseconds: 1200);

  @override
  Future<AccessListPage> build() async {
    final query = ref.watch(accessSearchQueryProvider);
    ref.onDispose(() => _highlightTimer?.cancel());

    final page = await ref.watch(accessRepositoryProvider).list(query: query);

    return AccessListPage(
      items: page.items,
      nextCursor: page.nextCursor,
      total: page.total.toInt(),
    );
  }

  /// Перезагружает список — кнопка «Обновить» и повтор после ошибки.
  void refresh() => ref.invalidateSelf();

  /// Догружает следующую страницу.
  ///
  /// Повторный вызов во время загрузки игнорируется: прокрутка легко
  /// вызывает его несколько раз подряд.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final page = await ref
          .read(accessRepositoryProvider)
          .list(
            cursor: current.nextCursor,
            query: ref.read(accessSearchQueryProvider),
          );

      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
          total: page.total.toInt(),
          isLoadingMore: false,
        ),
      );
    } on Object {
      // Ошибка догрузки не должна стирать уже показанные строки: возвращаем
      // список как был, а сообщение показывает экран.
      state = AsyncData(current.copyWith(isLoadingMore: false));
      rethrow;
    }
  }

  /// Добавляет адрес и показывает новую запись сверху.
  ///
  /// Ошибки (`invalid_email`, `access_entry_exists`) уходят наверх:
  /// их место — в модалке добавления, а не в общем состоянии экрана.
  Future<AccessEntryDto> add(String email) async {
    final created = await ref.read(accessRepositoryProvider).add(email);
    final current = state.value;

    // При активном поиске вставлять запись вслепую нельзя: она может
    // не подходить под запрос. Тогда честнее перезагрузить список.
    if (current == null || ref.read(accessSearchQueryProvider).isNotEmpty) {
      refresh();

      return created;
    }

    state = AsyncData(
      current.copyWith(
        items: [created, ...current.items],
        total: current.total + 1,
        highlightedId: created.id,
      ),
    );

    _highlightTimer?.cancel();
    _highlightTimer = Timer(highlightDuration, () {
      final page = state.value;
      if (page == null || page.highlightedId != created.id) return;

      state = AsyncData(page.copyWith(clearHighlight: true));
    });

    return created;
  }

  /// Выдаёт или снимает признак владельца трекера.
  ///
  /// Не оптимистично: показывать, что права уже изменены, когда сервер ещё
  /// не ответил, — врать о правах.
  Future<void> setInstanceOwner(String id, {required bool value}) async {
    final updated = await ref
        .read(accessRepositoryProvider)
        .setInstanceOwner(id, value: value);

    final current = state.value;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        items: [
          for (final entry in current.items)
            if (entry.id == id) updated else entry,
        ],
      ),
    );
  }

  /// Отзывает доступ. Возвращает число погашенных сессий (US-09).
  ///
  /// Строка исчезает только после ответа сервера: оптимистично показывать,
  /// что человек лишён доступа, когда это ещё не так, — опасная ложь
  /// (`screens/access-list.md`).
  Future<int> revoke(String id) async {
    final revokedSessions = await ref.read(accessRepositoryProvider).revoke(id);
    final current = state.value;

    if (current != null) {
      state = AsyncData(
        current.copyWith(
          items: current.items.where((entry) => entry.id != id).toList(),
          total: current.total > 0 ? current.total - 1 : 0,
        ),
      );
    }

    return revokedSessions;
  }
}
