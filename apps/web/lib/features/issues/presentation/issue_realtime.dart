import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/realtime/realtime_frame.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_comments_providers.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_history_providers.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_providers.dart';
import 'package:sl_tracker_web/features/realtime/presentation/realtime_providers.dart';

/// Что живые обновления сообщили экрану задачи.
@immutable
class IssueLiveState {
  /// @nodoc
  const IssueLiveState({
    this.newComments = 0,
    this.deleted = false,
    this.flashingFields = const {},
  });

  /// Сколько чужих комментариев приехало, пока человек не внизу ленты.
  ///
  /// По этому числу рисуется плашка «Новых комментариев: 2» — лента при этом
  /// **не прокручивается сама**: ни одно внешнее обновление не двигает то,
  /// на что человек смотрит (`screens/README.md`, 7).
  final int newComments;

  /// Задачу удалил другой пользователь.
  final bool deleted;

  /// Поля, изменённые снаружи прямо сейчас: их фон вспыхивает
  /// `accentSurface`. Имена — как в ответе `GET /api/issues/{key}`.
  final Set<String> flashingFields;

  /// @nodoc
  IssueLiveState copyWith({
    int? newComments,
    bool? deleted,
    Set<String>? flashingFields,
  }) => IssueLiveState(
    newComments: newComments ?? this.newComments,
    deleted: deleted ?? this.deleted,
    flashingFields: flashingFields ?? this.flashingFields,
  );
}

/// Живые обновления открытой задачи (D-26).
///
/// Экран **смотрит** сюда, а логика обновления данных живёт здесь: виджет
/// не ходит ни в API, ни в сокет.
///
/// Событие — сигнал, а не состояние: по нему перечитывается ровно то, что
/// могло измениться, обычным HTTP-запросом. Набранный текст при этом
/// не трогается никогда (US-45).
final issueRealtimeProvider =
    NotifierProvider.family<IssueRealtimeController, IssueLiveState, String>(
      IssueRealtimeController.new,
      isAutoDispose: true,
    );

/// Контроллер живых обновлений задачи.
class IssueRealtimeController extends Notifier<IssueLiveState> {
  /// @nodoc
  IssueRealtimeController(this.issueKey);

  /// Ключ задачи из адреса. Регистр значения не имеет: тему сервер вернёт
  /// в каноническом виде, и сравнением занимается клиент живых обновлений.
  final String issueKey;

  /// Сколько держится подсветка поля, изменённого снаружи.
  static const flashDuration = Duration(milliseconds: 200);

  @override
  IssueLiveState build() {
    listenRealtimeTopic(ref, RealtimeTopics.issue(issueKey), _onSignal);

    return const IssueLiveState();
  }

  /// Плашка «Новых комментариев» нажата или человек сам доехал до низа.
  void clearNewComments() {
    if (state.newComments == 0) return;

    state = state.copyWith(newComments: 0);
  }

  void _onSignal(RealtimeSignal signal) {
    switch (signal) {
      case RealtimeEvent():
        _onEvent(signal);
      case RealtimeResync():
        // За время обрыва потеряно всё: перечитываем задачу целиком.
        _refreshIssue();
        unawaited(_comments.reload());
        ref.read(issueHistoryProvider(issueKey).notifier).refresh();
      case RealtimeTopicLost():
        // Права на задачу могли отобрать прямо сейчас. Перечитываем и
        // показываем то, что вернёт сервер: для чужого проекта это 404
        // и экран «Задача не найдена».
        _refreshIssue();
    }
  }

  void _onEvent(RealtimeEvent event) {
    final currentUserId = ref.read(sessionControllerProvider).user?.id;

    switch (event.event) {
      case RealtimeEvents.issueUpdated:
        _refreshIssue();
        // Отдельного события у истории нет: любое изменение задачи могло
        // добавить в неё запись.
        ref.read(issueHistoryProvider(issueKey).notifier).refresh();

        // Своя же правка возвращается и инициатору — подсвечивать её как
        // внешнее изменение не нужно (`websocket.md`, 9).
        if (!event.isMine(currentUserId)) _flash(event.changedFields);
      case RealtimeEvents.issueDeleted:
        state = state.copyWith(deleted: true);
      case RealtimeEvents.commentCreated:
        unawaited(_comments.reload());
        if (!event.isMine(currentUserId)) {
          state = state.copyWith(newComments: state.newComments + 1);
        }
      case RealtimeEvents.commentUpdated:
        unawaited(_comments.reload());
      case RealtimeEvents.commentDeleted:
        final id = event.text('id');
        if (id != null) _comments.removeLocally(id);
      default:
        // Каталог событий может пополниться: незнакомое событие не повод
        // ни падать, ни дёргать сервер.
        break;
    }
  }

  CommentsController get _comments =>
      ref.read(issueCommentsProvider(issueKey).notifier);

  void _refreshIssue() =>
      ref.read(issueProvider(issueKey).notifier).refresh();

  /// Зажигает подсветку изменённых полей и гасит её через [flashDuration].
  void _flash(List<String> fields) {
    if (fields.isEmpty) return;

    state = state.copyWith(flashingFields: {...state.flashingFields, ...fields});

    Timer(flashDuration, () {
      if (!ref.mounted) return;

      state = state.copyWith(
        flashingFields: {
          for (final field in state.flashingFields)
            if (!fields.contains(field)) field,
        },
      );
    });
  }
}
