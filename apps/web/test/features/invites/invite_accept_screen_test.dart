import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/core/api/generated/export.dart';
import 'package:sl_tracker_web/core/network/api_failure.dart';
import 'package:sl_tracker_web/features/invites/data/invitations_repository.dart';
import 'package:sl_tracker_web/features/invites/presentation/invite_accept_screen.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_skeleton.dart';

import '../../helpers/fake_project_repositories.dart';
import '../../helpers/pump_widget.dart';

/// Поднимает экран приёма приглашения по адресу `/invite/<token>`.
Future<GoRouter> pumpInvite(
  WidgetTester tester,
  FakeInvitationsRepository invitations, {
  Size windowSize = const Size(1280, 800),
}) => pumpWithRouter(
  tester,
  initialLocation: '/invite/token-1234567890123456',
  windowSize: windowSize,
  overrides: [invitationsRepositoryProvider.overrideWithValue(invitations)],
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(body: Text('мои проекты')),
    ),
    GoRoute(
      path: '/projects/:slug',
      builder: (context, state) =>
          Scaffold(body: Text('проект ${state.pathParameters['slug']}')),
    ),
    GoRoute(
      path: '/invite/:token',
      builder: (context, state) =>
          InviteAcceptScreen(token: state.pathParameters['token']!),
    ),
  ],
);

void main() {
  group('приглашение действительно', () {
    testWidgets('показывает проект и роль, но не его содержимое', (
      tester,
    ) async {
      await pumpInvite(tester, FakeInvitationsRepository());
      await tester.pumpAndSettle();

      expect(find.text('Sweet Limit'), findsOneWidget);
      expect(
        find.text('Вас приглашают присоединиться к проекту'),
        findsOneWidget,
      );
      expect(find.text('Ваша роль: Участник'), findsOneWidget);
      expect(
        find.text('Сможете создавать и менять задачи, комментировать'),
        findsOneWidget,
      );
      // Ни очередей, ни участников, ни автора приглашения, ни описания
      // проекта, ни срока действия ссылки (US-21).
      expect(find.textContaining('Анна'), findsNothing);
      expect(find.textContaining('Мобильное приложение'), findsNothing);
      expect(find.textContaining('участник'), findsNothing);
      expect(find.textContaining('дней'), findsNothing);
    });

    testWidgets('роль читателя объясняется своими словами', (tester) async {
      await pumpInvite(
        tester,
        FakeInvitationsRepository(
          previewResult: fakeInvitationPreview(
            role: InvitationPreviewDtoRole.reader,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ваша роль: Читатель'), findsOneWidget);
      expect(
        find.text('Сможете просматривать задачи и обсуждения, но не менять их'),
        findsOneWidget,
      );
    });

    testWidgets('вступление уводит в проект', (tester) async {
      final invitations = FakeInvitationsRepository();
      final router = await pumpInvite(tester, invitations);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Присоединиться'));
      await tester.pumpAndSettle();

      expect(invitations.acceptCalls, 1);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/projects/sweet-limit',
      );
      expect(
        find.textContaining('Вы присоединились к проекту'),
        findsOneWidget,
      );
    });
  });

  group('проверка приглашения', () {
    testWidgets('пока проверяем — скелетон в геометрии экрана', (tester) async {
      final invitations = FakeInvitationsRepository()..gate = Completer<void>();

      await pumpInvite(tester, invitations);
      await tester.pump();

      expect(find.byType(SLSkeletonBox), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      invitations.gate!.complete();
      await tester.pumpAndSettle();
    });
  });

  group('приглашение не работает', () {
    testWidgets('410 — «больше не действует», без названия проекта', (
      tester,
    ) async {
      // Истёкшее и отозванное показываются одинаково: разница подсказывала бы,
      // что кто-то специально отозвал доступ.
      await pumpInvite(
        tester,
        FakeInvitationsRepository(
          previewFailure: const ApiFailure(
            kind: ApiFailureKind.gone,
            statusCode: 410,
            code: 'invitation_inactive',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Приглашение больше не действует'), findsOneWidget);
      expect(find.text('Sweet Limit'), findsNothing);
      expect(find.text('Присоединиться'), findsNothing);
      expect(find.text('На главную'), findsOneWidget);
    });

    testWidgets('404 — «не найдено», текст тот же', (tester) async {
      // По сообщению нельзя понять, существует ли такой проект (US-21).
      await pumpInvite(
        tester,
        FakeInvitationsRepository(
          previewFailure: const ApiFailure(
            kind: ApiFailureKind.notFound,
            statusCode: 404,
            code: 'invitation_not_found',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Приглашение не найдено'), findsOneWidget);
      expect(
        find.textContaining('Попросите новую у того, кто вас пригласил'),
        findsOneWidget,
      );
      expect(find.text('Sweet Limit'), findsNothing);
    });

    testWidgets('сбой связи отличается от отказа и предлагает повтор', (
      tester,
    ) async {
      final invitations = FakeInvitationsRepository(
        previewFailure: const ApiFailure(kind: ApiFailureKind.network),
      );

      await pumpInvite(tester, invitations);
      await tester.pumpAndSettle();

      expect(find.text('Не удалось проверить приглашение'), findsOneWidget);

      invitations.previewFailure = null;
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.text('Sweet Limit'), findsOneWidget);
    });

    testWidgets('ошибка вступления оставляет на экране с баннером', (
      tester,
    ) async {
      await pumpInvite(
        tester,
        FakeInvitationsRepository(
          acceptFailure: const ApiFailure(kind: ApiFailureKind.network),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Присоединиться'));
      await tester.pumpAndSettle();

      expect(find.text('Не удалось присоединиться'), findsOneWidget);
      // Кнопка снова активна: человек может попробовать ещё раз.
      expect(find.text('Присоединиться'), findsOneWidget);
    });
  });

  group('уже участник', () {
    testWidgets('экран не показывается — сразу проект и тост', (tester) async {
      // Показывать «вы уже здесь» с кнопкой «Присоединиться» значило бы
      // предлагать действие, которое ничего не делает (US-21).
      final router = await pumpInvite(
        tester,
        FakeInvitationsRepository(
          previewResult: fakeInvitationPreview(alreadyMember: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/projects/sweet-limit',
      );
      expect(find.text('Вы уже участник этого проекта'), findsOneWidget);
      expect(find.text('Присоединиться'), findsNothing);
    });
  });
}
