import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/features/tokens/data/tokens_repository.dart';
import 'package:sl_tracker_web/features/tokens/domain/token_presentation.dart';

/// Загруженный список токенов.
@immutable
class TokensPage {
  /// @nodoc
  const TokensPage({
    required this.items,
    this.hasRevokedHistory = false,
    this.highlightedId,
  });

  /// Токены от новых к старым: порядок задаёт сервер (`createdAt desc`).
  final List<TokenDto> items;

  /// У человека есть отозванные токены, скрытые переключателем.
  ///
  /// Нужно ровно для одного: отличить «токенов никогда не было» от «все
  /// отозваны, и история спрятана фильтром». Сервер при `includeRevoked=false`
  /// отдаёт в обоих случаях пустой список, поэтому в этом — и только в этом —
  /// случае делается второй запрос.
  final bool hasRevokedHistory;

  /// Только что отозванная строка: подсвечивается 1200 мс.
  final String? highlightedId;

  /// Сколько токенов действуют — это число упирается в лимит 20.
  int get activeCount => TokenPresentation.countActive(items);

  /// Лимит выбран: выпустить новый токен нельзя, пока что-нибудь не отозвано.
  bool get isAtLimit => activeCount >= TokenPresentation.activeLimit;

  /// @nodoc
  TokensPage copyWith({
    List<TokenDto>? items,
    bool? hasRevokedHistory,
    String? highlightedId,
    bool clearHighlight = false,
  }) => TokensPage(
    items: items ?? this.items,
    hasRevokedHistory: hasRevokedHistory ?? this.hasRevokedHistory,
    highlightedId: clearHighlight ? null : highlightedId ?? this.highlightedId,
  );
}

/// Показывать ли отозванные токены.
///
/// Состояние **не запоминается между заходами**: «выключен» — часть контракта
/// экрана, а липкий фильтр через полгода читается как список, полный мусора
/// (`screens/tokens.md`).
final tokensIncludeRevokedProvider =
    NotifierProvider<TokensIncludeRevoked, bool>(
      TokensIncludeRevoked.new,
      isAutoDispose: true,
    );

/// @nodoc
class TokensIncludeRevoked extends Notifier<bool> {
  @override
  bool build() => false;

  /// @nodoc
  void update({required bool value}) => state = value;

  /// @nodoc
  void toggle() => state = !state;
}

/// Список токенов доступа.
///
/// Автоочистка намеренная: экран открывают раз в год, и данные при следующем
/// открытии должны быть свежими. В реальном времени список не обновляется —
/// токен, выпущенный в другой вкладке, появится при следующем открытии.
final tokensListProvider = AsyncNotifierProvider<TokensController, TokensPage>(
  TokensController.new,
  isAutoDispose: true,
  // Автоповтор выключен намеренно: ошибка загрузки — это состояние экрана
  // с кнопкой «Повторить», решение за человеком.
  retry: (_, _) => null,
);

/// Контроллер списка токенов.
class TokensController extends AsyncNotifier<TokensPage> {
  Timer? _highlightTimer;

  /// Сколько держится подсветка только что отозванной строки.
  static const highlightDuration = Duration(milliseconds: 1200);

  @override
  Future<TokensPage> build() async {
    final includeRevoked = ref.watch(tokensIncludeRevokedProvider);
    ref.onDispose(() => _highlightTimer?.cancel());

    final repository = ref.read(tokensRepositoryProvider);
    final page = await repository.list(includeRevoked: includeRevoked);

    // Второй запрос — только когда список пуст: иначе не отличить «токенов
    // никогда не было» от «все отозваны и скрыты фильтром», а тексты
    // у этих состояний разные.
    final hasRevokedHistory = page.items.isEmpty && !includeRevoked
        ? (await repository.list(includeRevoked: true)).items.isNotEmpty
        : false;

    return TokensPage(items: page.items, hasRevokedHistory: hasRevokedHistory);
  }

  /// Перезагружает список — кнопка «Повторить» после ошибки.
  void refresh() => ref.invalidateSelf();

  /// Выпускает токен и возвращает его секрет.
  ///
  /// Секрет уходит вызывающему диалогу и **нигде не сохраняется**: ни в
  /// состоянии провайдера, ни в кэше, ни в логах. В список добавляется строка,
  /// собранная из безопасных полей ответа: только что выпущенный токен
  /// не пользован, поэтому `lastSeenAt` равен `createdAt` — ровно так же,
  /// как это отдаст сервер при следующей загрузке.
  ///
  /// Ошибки (`token_limit_reached`, `429`, валидация) уходят наверх: их место
  /// в модалке создания, а не в общем состоянии экрана.
  Future<IssuedTokenDto> create({
    required String name,
    required int expiresInDays,
  }) async {
    final issued = await ref
        .read(tokensRepositoryProvider)
        .create(name: name, expiresInDays: expiresInDays);

    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          items: [
            TokenDto(
              id: issued.id,
              name: issued.name,
              prefix: issued.prefix,
              purpose: TokenDtoPurpose.pat,
              createdAt: issued.createdAt,
              lastSeenAt: issued.createdAt,
              expiresAt: issued.expiresAt,
              revokedAt: null,
            ),
            ...current.items,
          ],
        ),
      );
    }

    return issued;
  }

  /// Отзывает токен.
  ///
  /// **Не оптимистично**: строка меняется только после `204`. Показать
  /// «отозван» раньше, чем это стало правдой, — опасная ложь.
  ///
  /// Когда отозванные показаны, список перезагружается: время отзыва знает
  /// сервер, и подставлять сюда локальные часы значило бы выдумать данные.
  Future<void> revoke(String id) async {
    final repository = ref.read(tokensRepositoryProvider);
    await repository.revoke(id);

    if (ref.read(tokensIncludeRevokedProvider)) {
      final page = await repository.list(includeRevoked: true);
      state = AsyncData(TokensPage(items: page.items, highlightedId: id));
      _scheduleHighlightClear(id);

      return;
    }

    final current = state.value;
    if (current == null) return;

    state = AsyncData(
      current.copyWith(
        items: current.items.where((token) => token.id != id).toList(),
        // Отозванный токен только что появился в истории: если список стал
        // пустым, это «всё отозвано», а не «токенов не было».
        hasRevokedHistory: true,
        clearHighlight: true,
      ),
    );
  }

  void _scheduleHighlightClear(String id) {
    _highlightTimer?.cancel();
    _highlightTimer = Timer(highlightDuration, () {
      final page = state.value;
      if (page == null || page.highlightedId != id) return;

      state = AsyncData(page.copyWith(clearHighlight: true));
    });
  }
}

/// Сколько у человека действующих токенов — для строки «ДОСТУП» в профиле.
///
/// Отдельного поля в `GET /api/me` для этого нет, а запрос дешёвый: активных
/// токенов не больше 20. Ошибка не ломает строку профиля — она показывает
/// текст без числа (`screens/profile.md`).
final activeTokensCountProvider = FutureProvider.autoDispose<int>(
  (ref) async {
    final page = await ref.watch(tokensRepositoryProvider).list();

    return TokenPresentation.countActive(page.items);
  },
  // Автоповтор выключен: не загрузившийся счётчик — это строка без числа,
  // а не повод долбить сервер из фонового экрана.
  retry: (_, _) => null,
);
