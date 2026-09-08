import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/platform/file_picker.dart';
import 'package:sl_tracker_web/features/projects/data/projects_repository.dart';
import 'package:sl_tracker_web/features/projects/domain/project_cover.dart';
import 'package:sl_tracker_web/features/projects/presentation/widgets/project_cover_section.dart';
import 'package:sl_tracker_web/shared/uikit/media/sl_cover_image.dart';

import '../../helpers/fake_platform.dart';
import '../../helpers/fake_project_repositories.dart';
import '../../helpers/pump_widget.dart';

Future<void> pumpCoverSection(
  WidgetTester tester, {
  required FakeProjectsRepository projects,
  required FakeFilePicker picker,
  String? coverUrl,
}) async {
  await pumpWithProviders(
    tester,
    Scaffold(
      body: ProjectCoverSection(project: fakeProject(coverUrl: coverUrl)),
    ),
    overrides: [
      projectsRepositoryProvider.overrideWithValue(projects),
      filePickerProvider.overrideWithValue(picker),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ограничения обложки', () {
    test('пять мегабайт — предел, как на сервере', () {
      expect(ProjectCover.maxBytes, 5 * 1024 * 1024);
      expect(
        ProjectCover.problemOf(fakePickedFile(size: ProjectCover.maxBytes)),
        isNull,
      );
      expect(
        ProjectCover.problemOf(fakePickedFile(size: ProjectCover.maxBytes + 1)),
        ProjectCoverProblem.tooLarge,
      );
    });

    test('принимаются PNG, JPEG и WEBP', () {
      for (final type in ProjectCover.allowedTypes) {
        expect(
          ProjectCover.problemOf(fakePickedFile(mimeType: type)),
          isNull,
          reason: type,
        );
      }

      expect(
        ProjectCover.problemOf(fakePickedFile(mimeType: 'image/gif')),
        ProjectCoverProblem.unsupportedType,
      );
    });

    test('нераспознанный тип оставляем серверу', () {
      // Тип определяется по содержимому файла на сервере, а не по заголовку:
      // отказывать заранее не за что.
      expect(ProjectCover.problemOf(fakePickedFile(mimeType: '')), isNull);
    });
  });

  group('секция обложки', () {
    testWidgets('ограничения написаны до выбора файла', (tester) async {
      await pumpCoverSection(
        tester,
        projects: FakeProjectsRepository(projects: [fakeProject()]),
        picker: FakeFilePicker(),
      );

      expect(find.text(ProjectCover.limitsHint), findsOneWidget);
    });

    testWidgets('тяжёлый файл до сервера не доходит', (tester) async {
      final projects = FakeProjectsRepository(projects: [fakeProject()]);
      final picker = FakeFilePicker(
        result: fakePickedFile(size: 6 * 1024 * 1024),
      );

      await pumpCoverSection(tester, projects: projects, picker: picker);

      await tester.tap(find.text('Загрузить'));
      await tester.pumpAndSettle();

      expect(find.text('Обложка не изменилась'), findsOneWidget);
      expect(find.textContaining('это больше 5 МБ'), findsOneWidget);
      // Прежняя обложка остаётся, запрос не уходит.
      expect(projects.lastUploadedFile, isNull);
    });

    testWidgets('чужой формат тоже отсекается на клиенте', (tester) async {
      final projects = FakeProjectsRepository(projects: [fakeProject()]);
      final picker = FakeFilePicker(
        result: fakePickedFile(name: 'cover.gif', mimeType: 'image/gif'),
      );

      await pumpCoverSection(tester, projects: projects, picker: picker);

      await tester.tap(find.text('Загрузить'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Это не PNG, JPEG или WEBP'), findsOneWidget);
      expect(projects.lastUploadedFile, isNull);
    });

    testWidgets('годный файл уходит на сервер', (tester) async {
      final projects = FakeProjectsRepository(projects: [fakeProject()]);
      final picker = FakeFilePicker(result: fakePickedFile());

      await pumpCoverSection(tester, projects: projects, picker: picker);

      await tester.tap(find.text('Загрузить'));
      await tester.pumpAndSettle();

      expect(picker.lastAccept, ProjectCover.acceptAttribute);
      expect(projects.lastUploadedFile?.name, 'cover.png');
      expect(find.text('Обложка загружена'), findsNothing);
    });

    testWidgets('закрытый диалог выбора — не ошибка', (tester) async {
      final projects = FakeProjectsRepository(projects: [fakeProject()]);
      final picker = FakeFilePicker();

      await pumpCoverSection(tester, projects: projects, picker: picker);

      await tester.tap(find.text('Загрузить'));
      await tester.pumpAndSettle();

      expect(picker.calls, 1);
      expect(find.text('Обложка не изменилась'), findsNothing);
      expect(projects.lastUploadedFile, isNull);
    });

    testWidgets('у проекта с обложкой есть «Заменить» и «Удалить»', (
      tester,
    ) async {
      await pumpCoverSection(
        tester,
        projects: FakeProjectsRepository(projects: [fakeProject()]),
        picker: FakeFilePicker(),
        coverUrl: 'https://storage.example/cover-signed',
      );

      expect(find.text('Заменить'), findsOneWidget);
      expect(find.text('Удалить'), findsOneWidget);
    });
  });

  group('размер файла словами', () {
    test('человеку показывается «4,2 МБ», а не байты', () {
      expect(ProjectCover.formatSize(900), '900 Б');
      expect(ProjectCover.formatSize(2048), '2 КБ');
      expect(ProjectCover.formatSize((4.2 * 1024 * 1024).round()), '4,2 МБ');
    });
  });

  group('протухшая подписанная ссылка', () {
    testWidgets('обложка просит обновить ссылку ровно один раз', (
      tester,
    ) async {
      // Подписанный адрес живёт 10 минут. Истёк — вместо «сломанного
      // изображения» показывается монограмма, а владелец данных один раз
      // получает просьбу перезапросить объект.
      var refreshes = 0;

      await pumpInTheme(
        tester,
        SLCoverImage(
          projectId: 'project-1',
          projectName: 'Sweet Limit',
          coverUrl: 'https://storage.example/cover-expired',
          width: 280,
          height: 158,
          onCoverExpired: () => refreshes++,
        ),
      );
      await tester.pumpAndSettle();

      expect(refreshes, 1);
      expect(find.text('SW'), findsOneWidget);

      // Повторные кадры новых запросов не порождают: иначе недоступное
      // хранилище превратилось бы в бесконечный цикл.
      await tester.pump();
      await tester.pumpAndSettle();

      expect(refreshes, 1);
    });

    testWidgets('без обложки никого не тревожим', (tester) async {
      var refreshes = 0;

      await pumpInTheme(
        tester,
        SLCoverImage(
          projectId: 'project-1',
          projectName: 'Sweet Limit',
          coverUrl: null,
          width: 280,
          height: 158,
          onCoverExpired: () => refreshes++,
        ),
      );
      await tester.pumpAndSettle();

      expect(refreshes, 0);
      expect(find.text('SW'), findsOneWidget);
    });
  });
}
