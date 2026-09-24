import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/features/tokens/domain/token_presentation.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_record_state_badge.dart';

import '../../helpers/fake_tokens_repository.dart';

void main() {
  final now = DateTime(2026, 9, 24, 12);

  group('колонка «Использован»', () {
    test('свежий неиспользованный токен говорит «пока неизвестно»', () {
      final token = fakeToken(
        createdAt: now.subtract(const Duration(hours: 3)),
      );

      expect(
        TokenPresentation.lastSeenLabel(token, now: now),
        'пока неизвестно',
      );
      // Первые сутки совпадение дат ничего не доказывает — и тултип
      // говорит об этом прямо.
      expect(
        TokenPresentation.lastSeenTooltip(token, now: now),
        contains('меньше суток назад'),
      );
    });

    test('через сутки неиспользованный токен говорит «ни разу»', () {
      final token = fakeToken(createdAt: now.subtract(const Duration(days: 3)));

      expect(TokenPresentation.lastSeenLabel(token, now: now), 'ни разу');
    });

    test('«сегодня», «вчера» и дата', () {
      final created = now.subtract(const Duration(days: 30));

      String labelFor(DateTime seen) => TokenPresentation.lastSeenLabel(
        fakeToken(createdAt: created, lastSeenAt: seen),
        now: now,
      );

      expect(labelFor(now.subtract(const Duration(hours: 2))), 'сегодня');
      expect(labelFor(now.subtract(const Duration(days: 1))), 'вчера');
      expect(labelFor(DateTime(2026, 9, 1, 9)), '1 сен');
    });

    test('слова «последний раз» нет ни в одной формулировке', () {
      final tokens = [
        fakeToken(createdAt: now.subtract(const Duration(hours: 1))),
        fakeToken(createdAt: now.subtract(const Duration(days: 40))),
        fakeToken(
          createdAt: now.subtract(const Duration(days: 40)),
          lastSeenAt: now.subtract(const Duration(days: 2)),
        ),
      ];

      for (final token in tokens) {
        final texts = [
          TokenPresentation.lastSeenLabel(token, now: now),
          TokenPresentation.lastSeenTooltip(token, now: now),
          TokenPresentation.rowSemanticsLabel(token, now: now),
        ];

        for (final text in texts) {
          expect(text.toLowerCase(), isNot(contains('последний раз')));
        }
      }
    });

    test('использованный токен обещает «не раньше», а не точное время', () {
      final token = fakeToken(
        createdAt: now.subtract(const Duration(days: 40)),
        lastSeenAt: now.subtract(const Duration(days: 2)),
      );

      expect(
        TokenPresentation.lastSeenTooltip(token, now: now),
        startsWith('Использован не раньше'),
      );
    });
  });

  group('колонка «Истекает»', () {
    test('меньше 30 дней — предупреждение словами и числом', () {
      final token = fakeToken(
        expiresAt: now.add(const Duration(days: 12, hours: 1)),
      );

      expect(TokenPresentation.expiresLabel(token, now: now), 'через 12 дней');
      expect(TokenPresentation.expiresSoon(token, now: now), isTrue);
    });

    test('меньше суток — отдельная формулировка', () {
      final token = fakeToken(expiresAt: now.add(const Duration(hours: 5)));

      expect(TokenPresentation.expiresLabel(token, now: now), 'меньше суток');
    });

    test('истёкший назван словом «истёк», а не только цветом', () {
      final token = fakeToken(expiresAt: DateTime(2026, 2, 1, 9));

      expect(TokenPresentation.expiresLabel(token, now: now), 'истёк 1 фев');
      expect(TokenPresentation.expiresSoon(token, now: now), isFalse);
      expect(TokenPresentation.stateOf(token, now: now), SLRecordState.expired);
    });

    test('дальний срок показывает год, когда он не текущий', () {
      final token = fakeToken(expiresAt: DateTime(2027, 3, 3, 14, 32));

      expect(TokenPresentation.expiresLabel(token, now: now), '3 мар 2027');
      expect(
        TokenPresentation.expiresTooltip(token, now: now),
        'Истекает 3 марта 2027 в 14:32',
      );
    });

    test('у отозванного в колонке прочерк, а не срок', () {
      final token = fakeToken(revokedAt: DateTime(2026, 3, 3, 14, 32));

      expect(TokenPresentation.expiresLabel(token, now: now), '—');
      expect(TokenPresentation.stateOf(token, now: now), SLRecordState.revoked);
    });
  });

  group('счёт действующих токенов', () {
    test('истёкшие и отозванные в лимит не входят', () {
      final tokens = [
        fakeToken(id: '1'),
        fakeToken(id: '2', expiresAt: DateTime(2026, 2, 1)),
        fakeToken(id: '3', revokedAt: DateTime(2026, 3, 3)),
        fakeToken(id: '4'),
      ];

      expect(TokenPresentation.countActive(tokens, now: now), 2);
    });
  });

  group('доступность', () {
    test('префикс читается посимвольно', () {
      expect(TokenPresentation.prefixSpelled('3f9a1c22'), '3 f 9 a 1 c 2 2');
      expect(TokenPresentation.prefixLabel('3f9a1c22'), '3f9a1c22…');
    });

    test('строка читается одной фразой в фиксированном порядке', () {
      final token = fakeToken(
        name: 'dsh-mcp',
        createdAt: DateTime(2026, 2, 12, 10, 30),
        lastSeenAt: now.subtract(const Duration(days: 1)),
        expiresAt: now.add(const Duration(days: 12, hours: 1)),
      );

      expect(
        TokenPresentation.rowSemanticsLabel(token, now: now),
        'dsh-mcp, префикс 3 f 9 a 1 c 2 2, создан 12 февраля 2026, '
        'использован не раньше вчерашнего дня, '
        'истекает через 12 дней, 6 октября 2026',
      );
    });

    test('у отозванного фраза заканчивается отзывом', () {
      final token = fakeToken(revokedAt: DateTime(2026, 3, 3, 14, 32));

      expect(
        TokenPresentation.rowSemanticsLabel(token, now: now),
        endsWith('отозван 3 марта 2026'),
      );
    });

    test('кнопка отзыва называет токен и последствие', () {
      final label = TokenPresentation.revokeSemanticsLabel(fakeToken());

      expect(label, contains('dsh-mcp'));
      expect(label, contains('потеряют доступ немедленно'));
    });
  });
}
