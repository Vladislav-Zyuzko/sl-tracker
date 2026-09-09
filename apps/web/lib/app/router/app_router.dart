import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sl_tracker_web/app/not_found_screen.dart';
import 'package:sl_tracker_web/app/router/app_routes.dart';
import 'package:sl_tracker_web/features/access/presentation/access_denied_screen.dart';
import 'package:sl_tracker_web/features/access/presentation/access_list_screen.dart';
import 'package:sl_tracker_web/features/auth/domain/session.dart';
import 'package:sl_tracker_web/features/auth/domain/session_state.dart';
import 'package:sl_tracker_web/features/auth/presentation/login_screen.dart';
import 'package:sl_tracker_web/features/auth/presentation/session_providers.dart';
import 'package:sl_tracker_web/features/invites/presentation/invite_accept_screen.dart';
import 'package:sl_tracker_web/features/issues/presentation/issue_screen.dart';
import 'package:sl_tracker_web/features/profile/presentation/profile_screen.dart';
import 'package:sl_tracker_web/features/projects/presentation/project_screen.dart';
import 'package:sl_tracker_web/features/projects/presentation/projects_screen.dart';
import 'package:sl_tracker_web/features/queues/domain/issue_sort.dart';
import 'package:sl_tracker_web/features/queues/presentation/queue_issues_providers.dart';
import 'package:sl_tracker_web/features/queues/presentation/queue_issues_screen.dart';
import 'package:sl_tracker_web/features/shell/presentation/app_shell.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_empty_state.dart';
import 'package:sl_tracker_web/shared/uikit/states/sl_error_state.dart';

/// Роутер приложения.
///
/// Провайдер, а не глобальная переменная: роутер читает состояние сессии,
/// чтобы уводить на вход. Пересоздавать `GoRouter` на каждое изменение
/// сессии нельзя — потеряется история браузера, поэтому смена состояния
/// приходит через [refreshListenable].
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<Session>(ref.read(sessionControllerProvider));
  ref.listen(sessionControllerProvider, (_, next) => refresh.value = next);

  final router = GoRouter(
    initialLocation: AppRoutes.projects,
    refreshListenable: refresh,
    redirect: (context, state) =>
        _redirect(state, ref.read(sessionControllerProvider)),
    routes: _routes,
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });

  return router;
});

/// Куда пускать, а куда нет.
///
/// Правило одно: внутрь приложения — только с сессией, на вход — только без
/// неё. Пока сессия не проверена, никого никуда не уводим: иначе перезагрузка
/// страницы выкидывала бы человека на вход каждый раз, пока идёт `GET /api/me`.
String? _redirect(GoRouterState state, Session session) {
  if (session.isResolving) return null;

  final path = state.uri.path;
  final isLogin = path == AppRoutes.login;
  final isAccessDenied = path == AppRoutes.accessDenied;

  if (session.isSignedOut) {
    // Экраны вне оболочки открыты всем: на вход человек и так идёт,
    // а экран отказа показывается ровно тогда, когда сессии нет.
    if (isLogin || isAccessDenied) return null;

    return Uri(
      path: AppRoutes.login,
      queryParameters: {
        // Адрес назначения: после входа человек попадёт туда, куда шёл (US-01).
        if (path != AppRoutes.projects) 'next': state.uri.toString(),
        if (session.state == SessionState.expired) 'reason': 'expired',
      },
    ).toString();
  }

  // Вошедшему на экране входа делать нечего — и мигать им тоже не нужно.
  if (isLogin) return safeNextLocation(state.uri.queryParameters['next']);
  if (isAccessDenied) return AppRoutes.projects;

  return null;
}

/// Проверяет адрес возврата после входа.
///
/// Принимается только путь внутри приложения. `//evil.example` — это
/// протокол-относительный внешний адрес, а не наш путь, и такие отбрасываются:
/// параметр в адресной строке задаёт кто угодно.
String safeNextLocation(String? next) {
  if (next == null || !next.startsWith('/') || next.startsWith('//')) {
    return AppRoutes.projects;
  }

  return next;
}

/// Токен приглашения из адреса возврата.
///
/// Человек, пришедший по ссылке-приглашению без сессии, уходит на вход
/// с `next=/invite/<token>`. Токен нужно передать бэкенду при старте входа:
/// действующее приглашение пускает в трекер в обход списка доступа
/// (ADR-0006, п. 3), иначе человек упрётся в экран отказа (US-21).
String? inviteTokenOf(String? next) {
  if (next == null) return null;

  final segments = Uri.parse(next).pathSegments;
  if (segments.length != 2 || segments.first != 'invite') return null;

  return RouteParams.inviteToken.hasMatch(segments[1]) ? segments[1] : null;
}

/// Заглушка экрана уведомлений: спека есть, данных пока нет.
class _NotificationsScreen extends StatelessWidget {
  const _NotificationsScreen();

  @override
  Widget build(BuildContext context) => const SLEmptyState(
    icon: Icons.notifications_none_rounded,
    title: 'Уведомлений нет',
    description:
        'Сюда попадают уведомления о задачах, '
        'в которых вы участвуете.',
  );
}

final _routes = <RouteBase>[
  // Экраны вне оболочки: пользователь ещё не внутри приложения.
  GoRoute(
    path: AppRoutes.login,
    name: AppRoutes.loginName,
    builder: (context, state) {
      final query = state.uri.queryParameters;
      final next = query['next'];

      return LoginScreen(
        errorCode: query['error'],
        next: next == null ? null : safeNextLocation(next),
        invite: inviteTokenOf(next),
        sessionExpired: query['reason'] == 'expired',
      );
    },
  ),
  GoRoute(
    path: AppRoutes.accessDenied,
    name: AppRoutes.accessDeniedName,
    // Тикет приходит в query, а не в пути: экран открывается и без него —
    // например, когда пользователь вернулся на адрес по истории браузера
    // спустя минуту, и тикет уже протух.
    builder: (context, state) =>
        AccessDeniedScreen(ticket: state.uri.queryParameters['ticket']),
  ),
  GoRoute(
    path: AppRoutes.invite,
    name: AppRoutes.inviteName,
    builder: (context, state) {
      final token = state.pathParameters['token'] ?? '';

      return RouteParams.inviteToken.hasMatch(token)
          ? InviteAcceptScreen(token: token)
          : const _InvalidInviteScreen();
    },
  ),

  // Устаревшие и «интуитивные» адреса. Пользователь вполне может набрать
  // /projects руками — приводим к каноническому виду, а не отдаём 404.
  GoRoute(path: '/projects', redirect: (_, _) => AppRoutes.projects),
  GoRoute(path: '/profile', redirect: (_, _) => AppRoutes.profile),
  GoRoute(path: '/access', redirect: (_, _) => AppRoutes.access),

  ShellRoute(
    builder: (context, state, child) => AppShell(child: child),
    routes: [
      GoRoute(
        path: AppRoutes.projects,
        name: AppRoutes.projectsName,
        builder: (context, state) => const ProjectsScreen(),
      ),
      GoRoute(
        path: AppRoutes.project,
        name: AppRoutes.projectName,
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';

          return RouteParams.projectSlug.hasMatch(slug)
              ? ProjectScreen(slug: slug)
              : NotFoundScreen(location: state.uri.toString());
        },
      ),
      GoRoute(
        path: AppRoutes.queue,
        name: AppRoutes.queueName,
        builder: (context, state) {
          final key = state.pathParameters['key'] ?? '';
          if (!RouteParams.queueKey.hasMatch(key)) {
            return NotFoundScreen(location: state.uri.toString());
          }

          // Фильтр и сортировка живут в адресе: ссылку на отфильтрованный
          // список можно скопировать, а F5 не сбрасывает выбор (US-32).
          final query = state.uri.queryParameters;

          return QueueIssuesScreen(
            queueKey: key,
            statusKeys: QueueIssuesQuery.parseStatuses(query['status']),
            sort: IssueSort.parse(query['sort']),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.issue,
        name: AppRoutes.issueName,
        builder: (context, state) {
          final key = state.pathParameters['key'] ?? '';

          // Ключ, не подходящий под формат, — это опечатка в адресной строке,
          // а не отсутствующая задача: к API за ним не ходим.
          if (!RouteParams.issueKey.hasMatch(key)) {
            return const _IssueNotFoundScreen();
          }

          // Якорь на комментарий: по нему приходят из уведомления
          // об упоминании (US-102, US-104).
          return IssueScreen(
            issueKey: key,
            anchorCommentId: state.uri.queryParameters['comment'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: AppRoutes.notificationsName,
        builder: (context, state) => const _NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: AppRoutes.profileName,
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'access',
            name: AppRoutes.accessName,
            builder: (context, state) => const AccessListScreen(),
          ),
        ],
      ),
    ],
  ),
];

/// Задача не найдена.
///
/// Текст намеренно не различает «удалена» и «нет доступа»: иначе экран
/// раскрывал бы существование задачи из чужого проекта.
class _IssueNotFoundScreen extends StatelessWidget {
  const _IssueNotFoundScreen();

  @override
  Widget build(BuildContext context) => SLErrorState(
    title: 'Задача не найдена',
    description:
        'Возможно, она удалена, или у вас нет доступа '
        'к её проекту.',
    actionLabel: 'К списку проектов',
    onAction: () => GoRouter.of(context).go(AppRoutes.projects),
  );
}

/// Приглашение с непригодным токеном.
class _InvalidInviteScreen extends StatelessWidget {
  const _InvalidInviteScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SLErrorState(
      title: 'Ссылка приглашения не подходит',
      description:
          'Проверьте, что скопировали ссылку целиком, '
          'или попросите отправить её ещё раз.',
      actionLabel: null,
      onAction: null,
    ),
  );
}
