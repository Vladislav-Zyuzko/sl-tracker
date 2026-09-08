import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/utils/sl_date_format.dart';
import 'package:sl_tracker_web/features/access/domain/access_email.dart';

void main() {
  group('даты', () {
    final date = DateTime(2026, 2, 12, 14, 30);

    test('в текущем году год не повторяется', () {
      expect(SLDateFormat.short(date, now: DateTime(2026, 9, 1)), '12 фев');
    });

    test('в прошлом году год нужен', () {
      expect(
        SLDateFormat.short(date, now: DateTime(2027, 1, 1)),
        '12 фев 2026',
      );
    });

    test('узкая колонка получает числовой вид', () {
      expect(SLDateFormat.numeric(date), '12.02');
    });

    test('точное время — для тултипа', () {
      expect(SLDateFormat.exact(date), '12 февраля 2026, 14:30');
    });
  });

  group('адрес в списке доступа', () {
    test('регистр и пробелы не создают второй адрес', () {
      expect(AccessEmail.normalize('  Ivan@Yandex.RU '), 'ivan@yandex.ru');
    });

    test('проверка формата совпадает с серверной', () {
      expect(AccessEmail.isValid('ivan@yandex.ru'), isTrue);
      expect(AccessEmail.isValid('ivan.petrov@my.yandex.ru'), isTrue);
      expect(AccessEmail.isValid('ivan@yandex'), isFalse);
      expect(AccessEmail.isValid('ivan yandex.ru'), isFalse);
      expect(AccessEmail.isValid('@yandex.ru'), isFalse);
      expect(AccessEmail.isValid(''), isFalse);
      expect(
        AccessEmail.isValid('${'a' * 320}@yandex.ru'),
        isFalse,
        reason: 'предел колонки varchar(320)',
      );
    });
  });
}
