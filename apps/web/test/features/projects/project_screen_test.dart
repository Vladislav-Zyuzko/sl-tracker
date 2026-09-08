import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/core/platform/browser_navigator.dart';
import 'package:sl_tracker_web/features/invites/data/invitations_repository.dart';
import 'package:sl_tracker_web/features/projects/data/projects_repository.dart';
import 'package:sl_tracker_web/features/projects/presentation/project_screen.dart';
import 'package:sl_tracker_web/features/projects/presentation/widgets/copy_invitation_link_button.dart';
import 'package:sl_tracker_web/features/projects/presentation/widgets/copy_project_address_button.dart';
import 'package:sl_tracker_web/features/queues/data/queues_repository.dart';

import '../../helpers/fake_platform.dart';
import '../../helpers/fake_project_repositories.dart';
import '../../helpers/fake_queue_repositories.dart';
import '../../helpers/pump_widget.dart';

/// Поднимает экран проекта по адресу `/projects/<slug>`.
Future<GoRouter> pumpProject(
  WidgetTester tester, {
  required FakeProjectsRepository projects,
  FakeInvitationsRepository? invitations,
  RecordingBrowserNavigator? navigator,
  String location = '/projects/sweet-limit',
  Size windowSize = const Size(1280, 800),
}) => pumpWithRouter(
  tester,
  initialLocation: location,
  windowSize: windowSize,
  overrides: [
    projectsRepositoryProvider.overrideWithValue(projects),
    invitationsRepositoryProvider.overrideWithValue(
      invitations ?? FakeInvitationsRepository(),
    ),
    browserNavigatorProvider.overrideWithValue(
      navigator ?? RecordingBrowserNavigator(),
    ),
    // Вкладка «Очереди» открыта по умолчанию и ходит за списком очередей:
    // без подмены репозитория тест стучался бы в сеть.
    queuesRepositoryProvider.overrideWithValue(FakeQueuesRepository()),
  ],
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(body: Text('мои проекты')),
    ),
    GoRoute(
      path: '/projects/:slug',
      builder: (context, state) =>
          Scaffold(body: ProjectScreen(slug: state.pathParameters['slug']!)),
    ),
  ],
);

void main() {
  group('экран проекта', () {
    testWidgets('404 показывает «Проект не найден» без данных проекта', (
      tester,
    ) async {
      // Проекта нет и «вы не участник» — это одно и то же снаружи:
      // иначе экран подтверждал бы существование чужого проекта (US-13).
      final projects = FakeProjectsRepository()
        ..getFailure = const ApiFailure(kind: ApiFailureKind.notFound);

      await pumpProject(tester, projects: projects);
      await tester.pumpAndSettle();

      expect(find.text('Проект не найден'), findsOneWidget);
      expect(find.text('Sweet Limit'), findsNothing);
    });

    testWidgets('сбой связи предлагает повтор, а не «не найден»', (
      tester,
    ) async {
      final projects = FakeProjectsRepository()
        ..getFailure = const ApiFailure(kind: ApiFailureKind.network);

      await pumpProject(tester, projects: projects);
      await tester.pumpAndSettle();

      expect(find.text('Не удалось загрузить проект'), findsOneWidget);
      expect(find.text('Повторить'), findsOneWidget);
    });

    testWidgets('прежний адрес заменяется действующим (US-18)', (tester) async {
      // Сервер отвечает 200 и отдаёт действующее короткое имя — клиент
      // обязан подменить адрес в строке браузера.
      final projects = FakeProjectsRepository(
        projects: [fakeProject(slug: 'sweet-limit')],
      );

      final router = await pumpProject(
        tester,
        projects: projects,
        location: '/projects/staroe-imya',
      );
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/projects/sweet-limit',
      );
    });
  });

  group('D-04: адрес проекта и ссылка-приглашение', () {
    testWidgets('в шапке есть адрес проекта — и он не про приглашение', (
      tester,
    ) async {
      await pumpProject(
        tester,
        projects: FakeProjectsRepository(projects: [fakeProject()]),
      );
      await tester.pumpAndSettle();

      // Доступное имя несёт пояснение: визуальная подпись рядом незрячему
      // пользователю бесполезна.
      expect(
        find.bySemanticsLabel(CopyProjectAddressButton.accessibleName),
        findsOneWidget,
      );
      // Слово «приглашение» рядом с адресом не появляется никогда.
      expect(
        CopyProjectAddressButton.accessibleName.toLowerCase(),
        isNot(contains('приглаш')),
      );
      expect(
        CopyProjectAddressButton.explanation.toLowerCase(),
        isNot(contains('приглаш')),
      );
      // Ссылки-приглашения на первой вкладке нет вовсе.
      expect(find.byType(CopyInvitationLinkButton), findsNothing);
    });

    testWidgets('адрес копируется одним нажатием и обычным тостом', (
      tester,
    ) async {
      final clipboard = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard.add((call.arguments as Map)['text'] as String);
          }

          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await pumpProject(
        tester,
        projects: FakeProjectsRepository(projects: [fakeProject()]),
        navigator: RecordingBrowserNavigator(),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.bySemanticsLabel(CopyProjectAddressButton.accessibleName),
      );
      await tester.pumpAndSettle();

      // Полный адрес, а не путь: из чата по пути никто не перейдёт.
      expect(clipboard, ['https://tracker.example/projects/sweet-limit']);
      expect(find.text(CopyProjectAddressButton.toastMessage), findsOneWidget);
      // Тост об адресе не пугает: он ничего не раздаёт.
      expect(find.text(CopyInvitationLinkButton.toastMessage), findsNothing);
    });

    testWidgets('ссылка-приглашение живёт только на своей вкладке', (
      tester,
    ) async {
      await pumpProject(
        tester,
        projects: FakeProjectsRepository(projects: [fakeProject()]),
        invitations: FakeInvitationsRepository(invitations: [fakeInvitation()]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CopyInvitationLinkButton), findsNothing);

      await tester.tap(find.text('Приглашения'));
      await tester.pumpAndSettle();

      expect(find.byType(CopyInvitationLinkButton), findsOneWidget);
      // Баннер-предупреждение обязателен и не сворачивается.
      expect(
        find.textContaining('Ссылка-приглашение даёт членство в проекте'),
        findsOneWidget,
      );
      // Две ссылки никогда не видны одновременно: пока открыты приглашения,
      // кнопки адреса проекта на экране нет вовсе (D-04).
      expect(find.byType(CopyProjectAddressButton), findsNothing);
      expect(find.text('Скопировать адрес'), findsNothing);
    });

    testWidgets('копирование приглашения предупреждает тостом', (tester) async {
      final clipboard = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard.add((call.arguments as Map)['text'] as String);
          }

          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await pumpProject(
        tester,
        projects: FakeProjectsRepository(projects: [fakeProject()]),
        invitations: FakeInvitationsRepository(invitations: [fakeInvitation()]),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Приглашения'));
      await tester.pumpAndSettle();

      expect(find.byType(CopyInvitationLinkButton), findsOneWidget);
      await tester.tap(
        find.bySemanticsLabel(CopyInvitationLinkButton.accessibleName),
      );
      await tester.pumpAndSettle();

      expect(clipboard.single, contains('/invite/'));
      expect(find.text(CopyInvitationLinkButton.toastMessage), findsOneWidget);
    });

    testWidgets('у истёкшего приглашения копировать нечего', (tester) async {
      await pumpProject(
        tester,
        projects: FakeProjectsRepository(projects: [fakeProject()]),
        invitations: FakeInvitationsRepository(
          invitations: [
            fakeInvitation(state: InvitationDtoState.expired, url: null),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Приглашения'));
      await tester.pumpAndSettle();

      expect(find.byType(CopyInvitationLinkButton), findsNothing);
      // Приглушённость — не единственный носитель смысла: есть плашка.
      expect(find.text('Истекло'), findsOneWidget);
    });
  });

  group('права на экране проекта', () {
    testWidgets('у читателя нет вкладок «Приглашения» и «Настройки»', (
      tester,
    ) async {
      await pumpProject(
        tester,
        projects: FakeProjectsRepository(
          projects: [fakeProject(role: ProjectDtoRole.reader)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Очереди'), findsOneWidget);
      expect(find.text('Участники'), findsOneWidget);
      // Не серые, а отсутствующие (`screens/README.md`, 4).
      expect(find.text('Приглашения'), findsNothing);
      expect(find.text('Настройки'), findsNothing);
      // «Скопировать адрес» остаётся: это доступно всем участникам.
      expect(
        find.bySemanticsLabel(CopyProjectAddressButton.accessibleName),
        findsOneWidget,
      );
      // Меню действий с проектом у читателя нет.
      expect(find.byTooltip('Действия с проектом'), findsNothing);
    });

    testWidgets('у администратора есть все четыре вкладки', (tester) async {
      await pumpProject(
        tester,
        projects: FakeProjectsRepository(projects: [fakeProject()]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Приглашения'), findsOneWidget);
      expect(find.text('Настройки'), findsOneWidget);
      expect(find.byTooltip('Действия с проектом'), findsOneWidget);
    });
  });

  group('вкладка участников', () {
    testWidgets('строка показывает имя, пометку «(вы)» и дату вступления', (
      tester,
    ) async {
      final projects = FakeProjectsRepository(projects: [fakeProject()])
        ..memberList = [
          fakeMember(isSelf: true),
          fakeMember(
            userId: 'user-2',
            displayName: 'Пётр Смирнов',
            email: 'petr@yandex.ru',
            role: ProjectMemberDtoRole.reader,
          ),
        ];

      await pumpProject(tester, projects: projects);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Участники'));
      await tester.pumpAndSettle();

      expect(find.text('Анна Иванова'), findsOneWidget);
      expect(find.text('(вы)'), findsOneWidget);
      expect(find.text('в проекте с 12 фев'), findsNWidgets(2));
      // Роль читателя видна текстом, а не только цветом.
      expect(find.text('Читатель'), findsOneWidget);
    });

    testWidgets('исключение показывает число задач без исполнителя', (
      tester,
    ) async {
      // Сервер считает его в той же транзакции (D-31), и человек должен
      // узнать последствие числом.
      final projects = FakeProjectsRepository(projects: [fakeProject()])
        ..unassignedIssues = 4
        ..memberList = [
          fakeMember(),
          fakeMember(
            userId: 'user-2',
            displayName: 'Пётр Смирнов',
            email: 'petr@yandex.ru',
            role: ProjectMemberDtoRole.member,
          ),
        ];

      await pumpProject(tester, projects: projects);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Участники'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Действия для Пётр Смирнов'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Исключить из проекта'));
      await tester.pumpAndSettle();

      expect(find.textContaining('останутся без исполнителя'), findsOneWidget);

      await tester.tap(find.text('Исключить'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Задач осталось без исполнителя: 4'),
        findsOneWidget,
      );
    });

    testWidgets('последнего администратора не понизить и не исключить', (
      tester,
    ) async {
      final projects = FakeProjectsRepository(projects: [fakeProject()])
        ..memberList = [fakeMember(isSelf: true)];

      await pumpProject(tester, projects: projects);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Участники'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Действия для Анна Иванова'));
      await tester.pumpAndSettle();

      // Вместо выключенных пунктов — пояснение, почему нельзя.
      expect(
        find.text('В проекте должен остаться хотя бы один администратор'),
        findsOneWidget,
      );
      expect(find.text('Исключить из проекта'), findsNothing);
      expect(find.text('Сделать участником'), findsNothing);
    });
  });

  group('настройки проекта', () {
    testWidgets('короткое имя приводится к допустимому виду на лету', (
      tester,
    ) async {
      await pumpProject(
        tester,
        projects: FakeProjectsRepository(projects: [fakeProject()]),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Настройки'));
      await tester.pumpAndSettle();

      final field = find.widgetWithText(TextField, 'sweet-limit');
      await tester.enterText(field, 'Сладкий Лимит');
      await tester.pumpAndSettle();

      expect(find.text('sladkiy-limit'), findsWidgets);
      // Предупреждение появляется только когда значение изменено.
      expect(find.text('Адрес изменится'), findsOneWidget);
      expect(
        find.text('https://tracker.example/projects/sladkiy-limit'),
        findsOneWidget,
      );
    });

    testWidgets('после смены адрес в браузере становится серверным', (
      tester,
    ) async {
      // Сервер мог привести значение к своему виду — берём его, а не своё.
      final projects = FakeProjectsRepository(projects: [fakeProject()])
        ..changedSlug = 'sladkiy-limit-7';

      final router = await pumpProject(tester, projects: projects);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Настройки'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'sweet-limit'),
        'sladkiy-limit',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Изменить адрес'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Изменить адрес'));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/projects/sladkiy-limit-7',
      );
    });

    testWidgets('ограничения обложки написаны до выбора файла', (tester) async {
      await pumpProject(
        tester,
        projects: FakeProjectsRepository(projects: [fakeProject()]),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Настройки'));
      await tester.pumpAndSettle();

      expect(find.text('PNG, JPEG или WEBP, до 5 МБ'), findsOneWidget);
    });

    testWidgets('удаление требует точного названия проекта', (tester) async {
      await pumpProject(
        tester,
        projects: FakeProjectsRepository(projects: [fakeProject()]),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Настройки'));
      await tester.pumpAndSettle();

      final dangerButton = find.widgetWithText(FilledButton, 'Удалить проект');
      await tester.ensureVisible(dangerButton);
      await tester.pumpAndSettle();
      await tester.tap(dangerButton);
      await tester.pumpAndSettle();

      // В модалке кнопка неактивна, пока не введено точное название:
      // это единственная защита от необратимого действия (US-17).
      final inDialog = find.descendant(
        of: find.byType(Dialog),
        matching: find.widgetWithText(FilledButton, 'Удалить проект'),
      );

      expect(tester.widget<FilledButton>(inDialog).onPressed, isNull);

      await tester.enterText(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextField),
        ),
        'Sweet Limit',
      );
      await tester.pumpAndSettle();

      expect(tester.widget<FilledButton>(inDialog).onPressed, isNotNull);
    });
  });
}
