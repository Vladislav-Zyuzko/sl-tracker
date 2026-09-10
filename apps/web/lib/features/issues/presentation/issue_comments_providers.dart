import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/features/issues/data/comments_repository.dart';

/// Комментарий, который ещё не доехал до сервера.
///
/// Живёт рядом с лентой, а не внутри неё: у него нет идентификатора,
/// а текст терять нельзя ни при каких обстоятельствах (US-71).
@immutable
class PendingComment {
  /// @nodoc
  const PendingComment({
    required this.localId,
    required this.body,
    required this.author,
    required this.createdAt,
    this.failed = false,
  });

  /// Локальный идентификатор: только чтобы отличать пачку отправляемых
  /// комментариев друг от друга.
  final int localId;

  /// Текст в Markdown — ровно то, что человек набрал.
  final String body;

  /// Автор: текущий пользователь.
  final IssueUserDto author;

  /// Когда нажали «Отправить».
  final DateTime createdAt;

  /// Отправка сорвалась: слева полоса `danger`, «Не отправлено»,
  /// «Повторить» / «Удалить». Текст при этом остаётся на экране.
  final bool failed;

  /// @nodoc
  PendingComment copyWith({bool? failed}) => PendingComment(
    localId: localId,
    body: body,
    author: author,
    createdAt: createdAt,
    failed: failed ?? this.failed,
  );
}

/// Загруженная часть ленты комментариев.
@immutable
class CommentsPage {
  /// @nodoc
  const CommentsPage({
    required this.items,
    required this.pending,
    required this.earlierCursor,
    required this.total,
    required this.canComment,
    this.isLoadingEarlier = false,
    this.loadEarlierFailed = false,
  });

  /// Загруженные комментарии в хронологическом порядке, сначала старые
  /// (US-70).
  final List<CommentDto> items;

  /// Отправляемые комментарии — всегда в конце ленты.
  final List<PendingComment> pending;

  /// Курсор **более ранних** комментариев: кнопка «Показать более ранние»
  /// над лентой. `null` — более ранних нет.
  final String? earlierCursor;

  /// Всего комментариев у задачи: счётчик на вкладке.
  final int total;

  /// Может ли текущий пользователь писать. У читателя `false`: поле ввода
  /// не показывается вовсе (US-71, D-29).
  final bool canComment;

  /// @nodoc
  final bool isLoadingEarlier;

  /// @nodoc
  final bool loadEarlierFailed;

  /// Есть ли что подгружать вверх.
  bool get hasEarlier => earlierCursor != null;

  /// @nodoc
  CommentsPage copyWith({
    List<CommentDto>? items,
    List<PendingComment>? pending,
    String? earlierCursor,
    bool clearEarlierCursor = false,
    int? total,
    bool? isLoadingEarlier,
    bool? loadEarlierFailed,
  }) => CommentsPage(
    items: items ?? this.items,
    pending: pending ?? this.pending,
    earlierCursor: clearEarlierCursor
        ? null
        : (earlierCursor ?? this.earlierCursor),
    total: total ?? this.total,
    canComment: canComment,
    isLoadingEarlier: isLoadingEarlier ?? this.isLoadingEarlier,
    loadEarlierFailed: loadEarlierFailed ?? this.loadEarlierFailed,
  );
}

/// Лента комментариев задачи (US-70 … US-73).
final issueCommentsProvider =
    AsyncNotifierProvider.family<CommentsController, CommentsPage, String>(
      CommentsController.new,
      isAutoDispose: true,
      retry: (_, _) => null,
    );

/// Контроллер ленты комментариев.
class CommentsController extends AsyncNotifier<CommentsPage> {
  /// @nodoc
  CommentsController(this.issueKey);

  /// @nodoc
  final String issueKey;

  var _nextLocalId = 0;

  /// Догружались ли более ранние комментарии.
  ///
  /// От этого зависит, чей курсор «более ранних» правильный после
  /// перечитывания: свой, уже уехавший вглубь ленты, или свежий из ответа.
  var _pagedBack = false;

  @override
  Future<CommentsPage> build() async {
    final page = await ref.read(commentsRepositoryProvider).list(issueKey);

    return CommentsPage(
      items: page.items,
      pending: const [],
      earlierCursor: page.nextCursor,
      total: page.total.toInt(),
      canComment: page.canComment,
    );
  }

  /// @nodoc
  void refresh() => ref.invalidateSelf();

  /// Догружает более ранние комментарии — они встают **в начало** ленты.
  ///
  /// Ошибка не роняет ленту: уже прочитанное остаётся на месте, а кнопка
  /// превращается в «Не удалось загрузить» с повтором.
  Future<void> loadEarlier() async {
    final current = state.value;
    if (current == null ||
        !current.hasEarlier ||
        current.isLoadingEarlier ||
        current.loadEarlierFailed) {
      return;
    }

    state = AsyncData(
      current.copyWith(isLoadingEarlier: true, loadEarlierFailed: false),
    );

    try {
      final page = await ref
          .read(commentsRepositoryProvider)
          .list(issueKey, cursor: current.earlierCursor);

      if (!ref.mounted) return;

      _pagedBack = true;
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          items: [...page.items, ...latest.items],
          earlierCursor: page.nextCursor,
          clearEarlierCursor: page.nextCursor == null,
          total: page.total.toInt(),
          isLoadingEarlier: false,
        ),
      );
    } on Object {
      if (!ref.mounted) return;

      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(isLoadingEarlier: false, loadEarlierFailed: true),
      );
    }
  }

  /// Повторяет сорвавшуюся подгрузку.
  Future<void> retryLoadEarlier() async {
    final current = state.value;
    if (current == null || !current.loadEarlierFailed) return;

    state = AsyncData(current.copyWith(loadEarlierFailed: false));
    await loadEarlier();
  }

  /// Перечитывает свежую часть ленты.
  ///
  /// Вызывается по живому событию и после восстановления связи. Именно
  /// перечитывает и **сливает**, а не пересоздаёт ленту: догруженные ранее
  /// порции остаются на месте, а неотправленные комментарии — тем более
  /// (US-71, набранный текст не теряется ни при каких обстоятельствах).
  Future<void> reload() async {
    if (state.value == null) return;

    final CommentListDto page;
    try {
      page = await ref.read(commentsRepositoryProvider).list(issueKey);
    } on Object {
      // Живое обновление — не повод показывать ошибку: на экране остаётся
      // то, что уже загружено.
      return;
    }

    final latest = state.value;
    if (!ref.mounted || latest == null) return;

    final freshIds = {for (final item in page.items) item.id};
    final freshOldest = page.items.isEmpty ? null : page.items.first.createdAt;
    final kept = [
      for (final item in latest.items)
        if (!freshIds.contains(item.id) &&
            (freshOldest == null || item.createdAt.isBefore(freshOldest)))
          item,
    ];

    state = AsyncData(
      latest.copyWith(
        items: [...kept, ...page.items],
        total: page.total.toInt(),
        // Курсор «более ранних» свежего ответа указывает на границу первой
        // порции. Если человек уже догрузил ленту вглубь, эта граница
        // осталась позади, и подменять ею свой курсор нельзя.
        earlierCursor: _pagedBack ? latest.earlierCursor : page.nextCursor,
        clearEarlierCursor: !_pagedBack && page.nextCursor == null,
      ),
    );
  }

  /// Убирает комментарий, удалённый другим пользователем.
  ///
  /// Точечно, а не перечитыванием: удалённый комментарий мог лежать далеко
  /// вверху ленты, куда свежая порция не достаёт.
  void removeLocally(String commentId) {
    final current = state.value;
    if (current == null) return;

    final index = current.items.indexWhere((item) => item.id == commentId);
    if (index < 0) return;

    state = AsyncData(
      current.copyWith(
        items: [...current.items]..removeAt(index),
        total: current.total - 1,
      ),
    );
  }

  /// Отправляет комментарий.
  ///
  /// Комментарий появляется в ленте сразу, полупрозрачным. При ошибке он
  /// **остаётся на экране** с пометкой «Не отправлено»: потерять набранный
  /// текст недопустимо (US-71).
  Future<void> send(String body, IssueUserDto author) async {
    final current = state.value;
    if (current == null) return;

    final pending = PendingComment(
      localId: _nextLocalId++,
      body: body,
      author: author,
      createdAt: DateTime.now(),
    );

    state = AsyncData(current.copyWith(pending: [...current.pending, pending]));

    await _deliver(pending);
  }

  /// Повторяет отправку неудавшегося комментария.
  Future<void> retrySend(int localId) async {
    final current = state.value;
    if (current == null) return;

    final index = current.pending.indexWhere((item) => item.localId == localId);
    if (index < 0) return;

    final pending = current.pending[index].copyWith(failed: false);
    state = AsyncData(
      current.copyWith(
        pending: _replacePending(current.pending, index, pending),
      ),
    );

    await _deliver(pending);
  }

  /// Убирает неотправленный комментарий по кнопке «Удалить».
  void discardPending(int localId) {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        pending: [
          for (final item in current.pending)
            if (item.localId != localId) item,
        ],
      ),
    );
  }

  /// Правит свой комментарий (US-72). Не оптимистично: правку подтверждают
  /// кнопкой, и показать несохранённый текст как сохранённый — обман.
  Future<void> edit(String commentId, String body) async {
    final updated = await ref
        .read(commentsRepositoryProvider)
        .update(issueKey, commentId, body);

    final current = state.value;
    if (!ref.mounted || current == null) return;

    state = AsyncData(
      current.copyWith(
        items: [
          for (final item in current.items)
            if (item.id == commentId) updated else item,
        ],
      ),
    );
  }

  /// Удаляет комментарий (US-73).
  ///
  /// Оптимистично: подтверждение уже было в модалке, и держать строку
  /// на экране после «Удалить» незачем. При ошибке она возвращается на своё
  /// место — именно на своё, а не в конец ленты.
  Future<void> remove(String commentId) async {
    final current = state.value;
    if (current == null) return;

    final index = current.items.indexWhere((item) => item.id == commentId);
    if (index < 0) return;

    final removed = current.items[index];
    state = AsyncData(
      current.copyWith(
        items: [...current.items]..removeAt(index),
        total: current.total - 1,
      ),
    );

    try {
      await ref.read(commentsRepositoryProvider).remove(issueKey, commentId);
    } on Object {
      final latest = state.value;
      if (ref.mounted && latest != null) {
        state = AsyncData(
          latest.copyWith(
            items: [...latest.items]
              ..insert(index.clamp(0, latest.items.length), removed),
            total: latest.total + 1,
          ),
        );
      }

      rethrow;
    }
  }

  /// Отправка одного отложенного комментария.
  Future<void> _deliver(PendingComment pending) async {
    try {
      final created = await ref
          .read(commentsRepositoryProvider)
          .create(issueKey, pending.body);

      final current = state.value;
      if (!ref.mounted || current == null) return;

      state = AsyncData(
        current.copyWith(
          items: [...current.items, created],
          pending: [
            for (final item in current.pending)
              if (item.localId != pending.localId) item,
          ],
          total: current.total + 1,
        ),
      );
    } on Object {
      final current = state.value;
      if (!ref.mounted || current == null) return;

      final index = current.pending.indexWhere(
        (item) => item.localId == pending.localId,
      );
      if (index < 0) return;

      state = AsyncData(
        current.copyWith(
          pending: _replacePending(
            current.pending,
            index,
            pending.copyWith(failed: true),
          ),
        ),
      );
    }
  }

  static List<PendingComment> _replacePending(
    List<PendingComment> items,
    int index,
    PendingComment value,
  ) => [...items]..[index] = value;
}
