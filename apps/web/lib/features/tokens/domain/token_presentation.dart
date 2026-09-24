import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/utils/sl_date_format.dart';
import 'package:sl_tracker_web/core/utils/sl_plural.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_record_state_badge.dart';

/// Формулировки экрана токенов доступа (`docs/design/screens/tokens.md`).
///
/// Вынесены из виджетов отдельно, потому что здесь легче всего соврать,
/// а соврать нельзя: `lastSeenAt` обновляется на сервере не чаще раза в сутки,
/// значит значение колонки «Использован» означает «**не раньше** чем»,
/// а не «последний раз». Слова «последний раз» на экране нет ни в одном
/// тексте, и это правило проверяется тестом.
///
/// **Клиент не решает, действует ли токен, — он только рисует.** Сравнение
/// с локальными часами нужно лишь для выбора формулировки; источник правды
/// о работоспособности токена — сервер.
sealed class TokenPresentation {
  /// Сколько действующих токенов разрешено одному человеку
  /// (`SPEC-PAT-API.md`, §3.1).
  static const activeLimit = 20;

  /// Порог, с которого срок подсвечивается предупреждением.
  static const expiringSoon = Duration(days: 30);

  /// Состояние токена, вычисленное клиентом.
  ///
  /// Вычисленного сервером `state` в контракте нет (Q-D36), поэтому считаем
  /// сами — по тем же правилам, по которым красим строку.
  static SLRecordState stateOf(TokenDto token, {DateTime? now}) {
    if (token.revokedAt != null) return SLRecordState.revoked;

    final moment = now ?? DateTime.now();

    return token.expiresAt.toLocal().isAfter(moment.toLocal())
        ? SLRecordState.active
        : SLRecordState.expired;
  }

  /// Действует ли токен: не отозван и срок не вышел.
  ///
  /// Именно это число упирается в лимит 20. Поле `total` из ответа для
  /// счётчика не годится: при `includeRevoked=false` сервер отсекает
  /// отозванные, но истёкшие в выдаче остаются, и `total` их посчитает.
  static bool isActive(TokenDto token, {DateTime? now}) =>
      stateOf(token, now: now) == SLRecordState.active;

  /// Сколько токенов из списка действуют.
  static int countActive(Iterable<TokenDto> tokens, {DateTime? now}) =>
      tokens.where((token) => isActive(token, now: now)).length;

  /// Восемь символов префикса и многоточие: «3f9a1c22…».
  ///
  /// Многоточие — честный знак, что это начало токена, а не он целиком.
  static String prefixLabel(String prefix) => '$prefix…';

  /// Префикс для скринридера — по символам: «3 f 9 a 1 c 2 2».
  ///
  /// Восьмисимвольная случайная строка, прочитанная как слово, бесполезна:
  /// её сверяют посимвольно (`accessibility.md`, 2.8).
  static String prefixSpelled(String prefix) => prefix.split('').join(' ');

  /// Пользовался ли кто-нибудь токеном.
  ///
  /// Признак «ни разу» — совпадение `lastSeenAt` и `createdAt`, а не пустое
  /// значение: в контракте поле не бывает `null`.
  static bool neverUsed(TokenDto token) =>
      !token.lastSeenAt.isAfter(token.createdAt);

  /// Текст колонки «Использован».
  static String lastSeenLabel(TokenDto token, {DateTime? now}) {
    final moment = (now ?? DateTime.now()).toLocal();

    if (neverUsed(token)) {
      // Первые сутки совпадение `lastSeenAt` и `createdAt` ничего
      // не доказывает: отметка могла просто не успеть обновиться.
      return moment.difference(token.createdAt.toLocal()) <
              const Duration(days: 1)
          ? 'пока неизвестно'
          : 'ни разу';
    }

    final seen = token.lastSeenAt.toLocal();
    final startOfToday = DateTime(moment.year, moment.month, moment.day);

    if (!seen.isBefore(startOfToday)) return 'сегодня';
    if (!seen.isBefore(startOfToday.subtract(const Duration(days: 1)))) {
      return 'вчера';
    }

    return SLDateFormat.short(seen, now: moment);
  }

  /// Тултип и доступное имя ячейки «Использован».
  static String lastSeenTooltip(TokenDto token, {DateTime? now}) {
    if (!neverUsed(token)) {
      return 'Использован не раньше ${SLDateFormat.exact(token.lastSeenAt)}. '
          'Отметка обновляется не чаще раза в сутки, поэтому токен мог '
          'работать и позже.';
    }

    return lastSeenLabel(token, now: now) == 'ни разу'
        ? 'Ни одного запроса с этим токеном не зафиксировано. '
              'Отметка обновляется не чаще раза в сутки.'
        : 'Токен выпущен меньше суток назад. Если агент уже работает, '
              'отметка появится в течение суток.';
  }

  /// Текст колонки «Истекает».
  ///
  /// У отозванного токена срок не показывается: он больше ничего не значит.
  static String expiresLabel(TokenDto token, {DateTime? now}) {
    if (token.revokedAt != null) return '—';

    final moment = (now ?? DateTime.now()).toLocal();
    final expires = token.expiresAt.toLocal();

    if (!expires.isAfter(moment)) {
      return 'истёк ${SLDateFormat.short(expires, now: moment)}';
    }

    final left = expires.difference(moment);
    if (left < const Duration(days: 1)) return 'меньше суток';
    if (left < expiringSoon) return 'через ${SLPlural.days(left.inDays)}';

    // Год показывается всегда, когда он не текущий: токен на 365 дней почти
    // всегда истекает в следующем году, и «3 мар» без года читается
    // как «через неделю».
    return SLDateFormat.short(expires, now: moment);
  }

  /// Подсвечивать ли срок предупреждением: осталось меньше 30 дней.
  static bool expiresSoon(TokenDto token, {DateTime? now}) {
    if (token.revokedAt != null) return false;

    final moment = (now ?? DateTime.now()).toLocal();
    final expires = token.expiresAt.toLocal();

    return expires.isAfter(moment) && expires.difference(moment) < expiringSoon;
  }

  /// Тултип ячейки «Истекает».
  static String expiresTooltip(TokenDto token, {DateTime? now}) {
    final moment = (now ?? DateTime.now()).toLocal();
    final expires = token.expiresAt.toLocal();
    final exact =
        '${SLDateFormat.long(expires)} в ${SLDateFormat.clock(expires)}';

    return expires.isAfter(moment) ? 'Истекает $exact' : 'Истёк $exact';
  }

  /// Тултип плашки «Отозван».
  static String revokedTooltip(DateTime revokedAt) =>
      'Отозван ${SLDateFormat.long(revokedAt)} '
      'в ${SLDateFormat.clock(revokedAt)}';

  /// Доступное имя строки списка: она читается одной фразой
  /// в фиксированном порядке (`accessibility.md`).
  static String rowSemanticsLabel(TokenDto token, {DateTime? now}) {
    final moment = now ?? DateTime.now();
    final revokedAt = token.revokedAt;

    final parts = <String>[
      token.name,
      'префикс ${prefixSpelled(token.prefix)}',
      'создан ${SLDateFormat.long(token.createdAt)}',
      'использован ${_lastSeenSpoken(token, now: moment)}',
      if (revokedAt == null)
        'истекает ${expiresLabel(token, now: moment)}, '
            '${SLDateFormat.long(token.expiresAt)}'
      else
        'отозван ${SLDateFormat.long(revokedAt)}',
    ];

    return parts.join(', ');
  }

  /// Доступное имя кнопки отзыва: с контекстом и последствием.
  ///
  /// Четыре одинаковые кнопки «Отозвать» в списке недопустимы
  /// (`accessibility.md`, 2.4).
  static String revokeSemanticsLabel(TokenDto token) =>
      'Отозвать токен ${token.name}. '
      'Агенты с этим токеном потеряют доступ немедленно';

  /// Как колонка «Использован» произносится внутри фразы.
  static String _lastSeenSpoken(TokenDto token, {DateTime? now}) {
    final label = lastSeenLabel(token, now: now);

    return switch (label) {
      'ни разу' => 'ни разу',
      'пока неизвестно' => 'пока неизвестно',
      'сегодня' => 'не раньше сегодняшнего дня',
      'вчера' => 'не раньше вчерашнего дня',
      _ => 'не раньше ${SLDateFormat.long(token.lastSeenAt)}',
    };
  }
}
