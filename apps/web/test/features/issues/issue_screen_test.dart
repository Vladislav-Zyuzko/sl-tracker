import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/platform/file_drop.dart';
import 'package:sl_tracker_web/core/platform/file_picker.dart';
import 'package:sl_tracker_web/features/auth/data/auth_repository.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';
import 'package:sl_tracker_web/features/issues/data/attachments_repository.dart';
import 'package:sl_tracker_web/features/issues/data/comments_repository.dart';
import 'package:sl_tracker_web/features/issues/data/issues_repository.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_screen.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/comment_composer.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/issue_fields_panel.dart';
import 'package:sl_tracker_web/features/issues/presentation/widgets/issue_skeletons.dart';
import 'package:sl_tracker_web/features/queues/data/queues_repository.dart';
import 'package:sl_tracker_web/shared/uikit/indicators/sl_status_chip.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';

import '../../helpers/fake_issue_repositories.dart';
import '../../helpers/fake_queue_repositories.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/pump_widget.dart';

/// Всё окружение экрана задачи сразу: задача, комментарии, вложения,
/// подсказка участников, статусы очереди и сессия.
class IssueWorld {
  IssueWorld({
    IssueDto? issue,
    List<CommentDto>? comments,
    List<AttachmentDto>? attachments,
    bool canComment = true,
  }) : issues = FakeIssuesRepository()..issue = issue ?? fakeIssue(),
       comments = FakeCommentsRepository(
         items: comments ?? const [],
         canComment: canComment,
       ),
       attachments = FakeAttachmentsRepository(items: attachments ?? const []);

  final FakeIssuesRepository issues;
  final FakeCommentsRepository comments;
  final FakeAttachmentsRepository attachments;
  final mentions = FakeMentionsRepository();
  final queues = FakeQueuesRepository();
  final drop = FakeFileDropTarget();
  final picker = FakeFilePicker();

  List<Override> get overrides => [
    issuesRepositoryProvider.overrideWithValue(issues),
    commentsRepositoryProvider.overrideWithValue(comments),
    attachmentsRepositoryProvider.overrideWithValue(attachments),
    mentionsRepositoryProvider.overrideWithValue(mentions),
    queuesRepositoryProvider.overrideWithValue(queues),
    fileDropTargetProvider.overrideWithValue(drop),
    filePickerProvider.overrideWithValue(picker),
    authRepositoryProvider.overrideWithValue(
      FakeAuthRepository(meResult: fakeMe()),
    ),
  ];
}

Future<ProviderContainer> pumpIssue(
  WidgetTester tester,
  IssueWorld world, {
  Size windowSize = const Size(1440, 900),
  String? anchorCommentId,
}) async {
  final container = await pumpWithProviders(
    tester,
    IssueScreen(issueKey: 'DEV-42', anchorCommentId: anchorCommentId),
    overrides: world.overrides,
    windowSize: windowSize,
  );

  // Сессия нужна для «Назначить на себя» и для поля комментария.
  await container.read(sessionControllerProvider.notifier).load();
  await tester.pumpAndSettle();

  return container;
}

void main() {
  group('экран задачи', () {
    testWidgets('пока задача грузится, ключ уже виден, а тело — скелетон', (
      tester,
    ) async {
      final world = IssueWorld()..issues.gate = Completer<void>();

      await pumpWithProviders(
        tester,
        const IssueScreen(issueKey: 'DEV-42'),
        overrides: world.overrides,
      );
      await tester.pump();

      // Ключ есть в адресе, скрывать его скелетоном незачем.
      expect(find.text('DEV-42'), findsOneWidget);
      expect(find.byType(DescriptionSkeleton), findsOneWidget);
      expect(find.byType(FieldsPanelSkeleton), findsOneWidget);

      world.issues.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('задача показывает название, статус и описание', (
      tester,
    ) async {
      final world = IssueWorld(
        issue: fakeIssue(description: 'Экспорт падает на 52 000 строк.'),
      );

      await pumpIssue(tester, world);

      expect(
        find.text('Починить экспорт CSV на больших выгрузках'),
        findsOneWidget,
      );
      expect(find.byType(SLStatusChip), findsWidgets);
      expect(
        find.textContaining('Экспорт падает', findRichText: true),
        findsWidgets,
      );
    });

    testWidgets('«не найдена» не раскрывает ничего о задаче', (tester) async {
      final world = IssueWorld()
        ..issues.issueFailure = const ApiFailure(
          kind: ApiFailureKind.notFound,
          statusCode: 404,
        );

      await pumpWithProviders(
        tester,
        const IssueScreen(issueKey: 'DEV-9999'),
        overrides: world.overrides,
      );
      await tester.pumpAndSettle();

      expect(find.text('Задача не найдена'), findsOneWidget);
      expect(find.byType(SLErrorState), findsOneWidget);
      expect(find.byType(IssueFieldsPanel), findsNothing);
    });

    testWidgets('сбой сети предлагает повторить, а не «не найдена»', (
      tester,
    ) async {
      final world = IssueWorld()
        ..issues.issueFailure = const ApiFailure(
          kind: ApiFailureKind.network,
        );

      await pumpWithProviders(
        tester,
        const IssueScreen(issueKey: 'DEV-42'),
        overrides: world.overrides,
      );
      await tester.pumpAndSettle();

      expect(find.text('Не удалось загрузить задачу'), findsOneWidget);
      expect(find.text('Повторить'), findsOneWidget);
    });

    testWidgets('пустое описание предлагает его добавить', (tester) async {
      await pumpIssue(tester, IssueWorld());

      expect(find.text('Описание не заполнено'), findsOneWidget);
      expect(find.text('Добавить описание'), findsOneWidget);
    });

    testWidgets('читатель видит содержимое, но не контролы', (tester) async {
      final world = IssueWorld(
        issue: fakeIssue(
          description: 'Только для чтения',
          canEdit: false,
          canDelete: false,
        ),
        canComment: false,
      );

      await pumpIssue(tester, world);

      // Содержимое видно целиком (US-41)…
      expect(
        find.text('Починить экспорт CSV на больших выгрузках'),
        findsOneWidget,
      );
      // …а действий нет.
      expect(find.text('Добавить описание'), findsNothing);
      expect(find.text('Изменить'), findsNothing);
      expect(find.text('Прикрепить'), findsNothing);
      expect(find.byType(CommentComposer), findsNothing);
      expect(find.byType(CommentComposerDenied), findsOneWidget);
    });

    testWidgets('пустая лента объясняет, зачем писать первым', (tester) async {
      await pumpIssue(tester, IssueWorld());

      expect(find.text('Комментариев пока нет'), findsOneWidget);
      expect(find.byType(CommentComposer), findsOneWidget);
    });

    testWidgets('комментарии показываются в ленте', (tester) async {
      final world = IssueWorld(
        comments: [
          fakeComment(id: 'c1', body: 'Проверил на стейдже'),
          fakeComment(id: 'c2', body: 'Какой размер порции берём?'),
        ],
      );

      await pumpIssue(tester, world);

      expect(
        find.textContaining('Проверил на стейдже', findRichText: true),
        findsWidgets,
      );
      expect(
        find.textContaining('Какой размер порции', findRichText: true),
        findsWidgets,
      );
    });

    testWidgets('история — вкладка рядом, а не блок под комментариями', (
      tester,
    ) async {
      final world = IssueWorld(
        comments: [fakeComment(id: 'c1', body: 'Комментарий в ленте')],
      );
      world.issues.historyGroups = [
        fakeHistoryGroup(
          actor: fakeIssueUser(displayName: 'Пётр Смирнов'),
          changes: [fakeHistoryChange()],
        ),
      ];

      await pumpIssue(tester, world);

      // По умолчанию всегда «Комментарии», даже если их нет.
      expect(find.text('изменил статус'), findsNothing);

      await tester.tap(find.text('История'));
      await tester.pumpAndSettle();

      expect(find.text('изменил статус'), findsOneWidget);
      expect(find.text('Пётр Смирнов'), findsOneWidget);
      // Лента комментариев на вкладке истории не показывается.
      expect(
        find.textContaining('Комментарий в ленте', findRichText: true),
        findsNothing,
      );
    });

    testWidgets('системное изменение подписано «Система»', (tester) async {
      final world = IssueWorld();
      world.issues.historyGroups = [
        fakeHistoryGroup(
          changes: [
            fakeHistoryChange(
              kind: IssueHistoryChangeDtoKind.assigneeChanged,
              oldValue: 'Пётр Смирнов',
              newValue: null,
            ),
          ],
        ),
      ];

      await pumpIssue(tester, world);
      await tester.tap(find.text('История'));
      await tester.pumpAndSettle();

      expect(find.text('Система'), findsOneWidget);
      // Пустое значение — словами, а не пустой строкой (US-91).
      expect(find.text('не назначен'), findsOneWidget);
    });

    testWidgets('блок вложений скрыт, пока их нет (US-48)', (tester) async {
      await pumpIssue(tester, IssueWorld());

      expect(find.text('ВЛОЖЕНИЯ 0'), findsNothing);
      // Контрол добавления при этом на месте — в строке действий.
      expect(find.text('Прикрепить'), findsOneWidget);
    });

    testWidgets('вложения показываются списком с размером', (tester) async {
      final world = IssueWorld(attachments: [fakeAttachment()]);

      await pumpIssue(tester, world);

      expect(find.text('ВЛОЖЕНИЯ 1'), findsOneWidget);
      expect(find.textContaining('2,3 МБ'), findsOneWidget);
    });

    testWidgets('блок ссылок скрыт, пока их нет (US-48)', (tester) async {
      await pumpIssue(tester, IssueWorld());

      expect(find.text('ССЫЛКИ 0'), findsNothing);
      expect(find.text('Добавить ссылку'), findsOneWidget);
    });

    testWidgets('ссылки показываются подписью, а не адресом', (tester) async {
      final world = IssueWorld(
        issue: fakeIssue(
          links: [
            IssueLinkDto(
              id: 'link-1',
              url: 'https://example.com/spec',
              title: 'Макет в Figma',
              createdBy: fakeIssueUser(),
              createdAt: DateTime.utc(2026, 2, 12),
            ),
          ],
        ),
      );

      await pumpIssue(tester, world);

      expect(find.text('ССЫЛКИ 1'), findsOneWidget);
      expect(find.text('Макет в Figma'), findsOneWidget);
    });

    testWidgets('перетаскивание подписано и отписывается при уходе', (
      tester,
    ) async {
      final world = IssueWorld();
      await pumpIssue(tester, world);

      expect(world.drop.attachCount, 1);

      world.drop.hover(over: true);
      await tester.pump();
      expect(
        find.text('Отпустите файлы, чтобы прикрепить'),
        findsOneWidget,
      );

      world.drop.hover(over: false);
      await tester.pump();
      expect(find.text('Отпустите файлы, чтобы прикрепить'), findsNothing);

      // Слушатель висит на документе: уход с экрана обязан его снять.
      await tester.pumpWidget(const SizedBox.shrink());
      expect(world.drop.detachCount, 1);
    });

    testWidgets('брошенные файлы уезжают на загрузку', (tester) async {
      final world = IssueWorld();
      await pumpIssue(tester, world);

      world.drop.drop([fakePickedFile(name: 'screenshot.png')]);
      await tester.pumpAndSettle();

      expect(world.attachments.uploadedNames, ['screenshot.png']);
    });

    testWidgets('файл больше 25 МБ не уезжает на сервер вовсе', (
      tester,
    ) async {
      final world = IssueWorld();
      await pumpIssue(tester, world);

      world.drop.drop([
        fakePickedFile(name: 'дамп.sql', size: 30 * 1024 * 1024),
      ]);
      await tester.pumpAndSettle();

      expect(world.attachments.uploadedNames, isEmpty);
      expect(find.text('Файл больше 25 МБ'), findsOneWidget);
    });
  });

  group('адаптив', () {
    testWidgets('на планшете панель полей уезжает наверх лентой', (
      tester,
    ) async {
      await pumpIssue(
        tester,
        IssueWorld(),
        windowSize: const Size(900, 800),
      );

      expect(find.byType(IssueFieldsBand), findsOneWidget);
      expect(find.byType(IssueFieldsPanel), findsNothing);
    });

    testWidgets('на телефоне статус отдельно, остальное свёрнуто', (
      tester,
    ) async {
      await pumpIssue(
        tester,
        IssueWorld(),
        windowSize: const Size(400, 800),
      );

      expect(find.byType(IssueFieldsCompact), findsOneWidget);
      expect(find.byType(SLStatusChip), findsWidgets);
      // Свёрнутая строка полей показывает главное одной строкой.
      expect(find.textContaining('Приоритет 80'), findsOneWidget);
    });

    testWidgets('на десктопе панель полей стоит колонкой справа', (
      tester,
    ) async {
      await pumpIssue(tester, IssueWorld());

      expect(find.byType(IssueFieldsPanel), findsOneWidget);
      expect(find.byType(IssueFieldsBand), findsNothing);
      expect(find.text('Исполнитель'), findsOneWidget);
      expect(find.text('Назначить на себя'), findsOneWidget);
    });
  });
}
