import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/features/projects/domain/project_slug.dart';

void main() {
  group('ProjectSlug.slugify', () {
    test('проверочный пример D-35', () {
      // Ровно тот случай, на котором сверяются клиент и сервер:
      // и → i, й → y, знаки — в дефис, крайние дефисы обрезаются.
      expect(ProjectSlug.slugify('Сладкий Лимит 2026!'), 'sladkiy-limit-2026');
    });

    test('шипящие и мягкий знак', () {
      expect(ProjectSlug.slugify('Ёжик щётка'), 'ezhik-schetka');
      expect(ProjectSlug.slugify('Июль'), 'iyul');
      expect(ProjectSlug.slugify('Объявление'), 'obyavlenie');
    });

    test('повторные и крайние дефисы схлопываются', () {
      expect(ProjectSlug.slugify('  --Веб   сайт--  '), 'veb-sayt');
    });

    test('латиница с диакритикой', () {
      expect(ProjectSlug.slugify('Café Déjà'), 'cafe-deja');
    });

    test('название без допустимых символов даёт пустую строку', () {
      // Запасное имя вида `project-7` выдаёт сервер: номер клиенту неизвестен.
      expect(ProjectSlug.slugify('🙂🙂'), '');
      expect(ProjectSlug.slugify('!!!'), '');
    });

    test('длина ограничена 40 символами и не кончается дефисом', () {
      final long = ProjectSlug.slugify('а' * 60);

      expect(long.length, lessThanOrEqualTo(ProjectSlug.maxLength));
      expect(long.endsWith('-'), isFalse);
    });
  });

  group('ProjectSlug.normalizeInput', () {
    test('кириллица и пробелы приводятся на лету', () {
      expect(ProjectSlug.normalizeInput('Сладкий Лимит'), 'sladkiy-limit');
    });

    test('хвостовой дефис сохраняется, пока человек печатает', () {
      // Иначе следующая буква прилипла бы к предыдущему слову.
      expect(ProjectSlug.normalizeInput('sladkiy '), 'sladkiy-');
    });

    test('ведущий дефис не появляется', () {
      expect(ProjectSlug.normalizeInput(' limit'), 'limit');
    });
  });

  group('ProjectSlug.validate', () {
    test('годное имя', () {
      expect(ProjectSlug.validate('sladkiy-limit'), isNull);
    });

    test('заглавные, пробелы и двойные дефисы отклоняются', () {
      expect(ProjectSlug.validate('Sladkiy'), 'invalid_slug');
      expect(ProjectSlug.validate('sladkiy limit'), 'invalid_slug');
      expect(ProjectSlug.validate('sladkiy--limit'), 'invalid_slug');
      expect(ProjectSlug.validate(''), 'invalid_slug');
    });

    test('системные адреса приложения заняты', () {
      for (final reserved in ['issues', 'invite', 'projects', 'me', 'api']) {
        expect(
          ProjectSlug.validate(reserved),
          'reserved_slug',
          reason: reserved,
        );
      }
    });
  });
}
